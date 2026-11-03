// 채팅방 메시지 송수신: 수신 반영(중복·낙관적 교체), 텍스트·사진·위치 전송(전송 중·실패·다시 보내기), WS 이미지 보완, 재연결 동기화
part of '../chat_room_screen.dart';

// WS 이미지 URL 일괄 조회 대기 시간 (연속 수신 묶음)
const Duration _wsImageFetchBatchDelay = Duration(milliseconds: 500);
// 서버 에코 대기 시간 (초과 시 전송 실패 표시)
const Duration _sendEchoTimeout = Duration(seconds: 10);

const String _imageMessageContent = '사진을 보냈습니다.';
const String _sendFailedMessage = '메시지를 보내지 못했어요. 연결 상태를 확인해 주세요.';

mixin _ChatRoomMessaging on _ChatRoomScreenStateFields, _ChatRoomScrollToBottom {
  /// 재연결 시 호출: 서버 최신 메시지 재조회 > 서버에 이미 저장된 내 로컬 메시지 정리 > 유실분 병합
  Future<void> _resyncMessages() async {
    if (_isResyncing || !mounted) return;
    _isResyncing = true;
    try {
      final response = await _chatRepository.getChatMessages(
        chatRoomId: widget.chatRoomId,
        pageNumber: 0,
        pageSize: chatMessagePageSize,
      );
      if (!mounted) return;
      final serverMessages = response.messages?.content ?? [];
      // 끊김 중 실패로 표시됐지만 실제로는 전달된 메시지 (서버 버전만 남김, 이미 표시된 서버 메시지는 후보 제외)
      final confirmedLocalIds = findPendingLocalIdsConfirmedByServer(
        pendingLocalMessages: _pendingLocalMessages,
        serverMessages: serverMessages,
        myMemberId: _myMemberId,
        displayedMessageIds: {
          for (final message in _messages)
            if (message.chatMessageId != null) message.chatMessageId!,
        },
      );
      setState(() {
        confirmedLocalIds.forEach(_forgetLocalMessage);
        _messages = mergeServerMessages(current: _messages, serverMessages: serverMessages);
      });
      // 단절 구간에 놓친 AI 추천 교정 (닫은 추천은 provider가 재노출 차단)
      ref
          .read(chatRecommendationProvider.notifier)
          .applyServerRecommendation(widget.chatRoomId, response.latestRecommendation);
      debugPrint('[ChatRoom] 🔁 재연결 동기화 완료: 서버 ${serverMessages.length}건 병합');
    } catch (e) {
      // 백그라운드 동기화이므로 사용자에게 노출하지 않음. 다음 재연결 때 재시도.
      debugPrint('[ChatRoom] 재연결 동기화 실패(무시): $e');
    } finally {
      _isResyncing = false;
    }
  }

  /// 수신 메시지 반영: 중복 무시 > 내 에코 처리(대기 로컬 확정·대체된 원래 메시지 흡수) > 새로 삽입
  /// 텍스트 전송 잠금은 전송 상태에서 계산 > 중복으로 무시돼도 잠김 없음
  void _handleIncomingMessage(ChatMessage newMessage) {
    debugPrint('[ChatRoom] _handleIncomingMessage: type=${newMessage.type}, id=${newMessage.chatMessageId}');
    final newId = newMessage.chatMessageId;
    final isDuplicate = (newId != null) && _messages.any((m) => m.chatMessageId != null && m.chatMessageId == newId);
    if (isDuplicate) {
      debugPrint('[ChatRoom] 중복 메시지 수신 무시: chatMessageId=$newId');
      return;
    }

    final echoDecision = resolveIncomingEcho(
      pendingLocalMessages: _pendingLocalMessages,
      supersededLocalMessages: _supersededLocalMessages,
      incomingMessage: newMessage,
      myMemberId: _myMemberId,
      receivedAt: DateTime.now(),
    );
    // 다시 보내기 전 원래 메시지의 늦은 에코: 재전송분이 이미 화면에 있어 표시하지 않음
    final absorbedSupersededLocalId = echoDecision.absorbedSupersededLocalId;
    if (absorbedSupersededLocalId != null) {
      _supersededLocalMessages.remove(absorbedSupersededLocalId);
      debugPrint('[ChatRoom] late echo of superseded message absorbed: $absorbedSupersededLocalId');
      return;
    }

    // 대기 로컬 메시지 확정 (낙관적 말풍선 > 서버 메시지 교체, 실패 표시였어도 확정)
    final matchedLocalId = echoDecision.confirmedLocalId;
    if (matchedLocalId != null) {
      final localMessage = _pendingLocalMessages[matchedLocalId]!;
      _clearLocalSendState(matchedLocalId);
      final localIndex = _messages.indexWhere((m) => m.chatMessageId == localMessage.chatMessageId);
      final confirmedMessage = mergeServerEchoIntoLocalMessage(localMessage: localMessage, serverMessage: newMessage);
      if (localIndex != -1) {
        _messages[localIndex] = confirmedMessage;
      } else {
        _messages.insert(0, confirmedMessage);
      }
      return;
    }

    // 교환 완료 요청 WS 에코 도착: 낙관적 로컬 메시지를 실제 서버 메시지로 교체
    if (newMessage.type == MessageType.tradeCompleteRequest && newMessage.senderId == _myMemberId) {
      final localId = _latestLocalTradeRequestId;
      if (localId != null) {
        _messages.removeWhere((m) => m.chatMessageId == localId);
        _latestLocalTradeRequestId = null;
        debugPrint('[ChatRoom] 교환 완료 요청 WS 에코 수신 → 로컬 임시 메시지 교체');
      }
    }

    // WebSocket 브로드캐스트에 imageUrls 미포함 시 REST API로 보완
    if (newMessage.type == MessageType.image && (newMessage.imageUrls == null || newMessage.imageUrls!.isEmpty)) {
      final tempId = '$webSocketImageMessageIdPrefix${DateTime.now().microsecondsSinceEpoch}';
      _messages.insert(0, newMessage.copyWith(chatMessageId: tempId));
      _pendingWsImageTempIds.add(tempId);
      _wsImageFetchTimer?.cancel();
      _wsImageFetchTimer = Timer(_wsImageFetchBatchDelay, _batchFetchWsImageUrls);
    } else {
      _messages.insert(0, newMessage);
    }
  }

  /// 텍스트 전송: 소켓 전송 시도 > 즉시 실패면 입력 글 유지·안내 > 성공 시 전송 중 말풍선·입력창 비움
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSendingMessage || _isInputDisabled) return;

    final localMessage = _buildLocalMessage(type: MessageType.text, content: content);
    if (!_trySendOverWebSocket(localMessage)) {
      _showSendFailedSnackBar();
      return;
    }
    setState(() => _addLocalMessage(localMessage, isSent: true));
    _messageController.clear();
    _scrollToBottom();
  }

  /// 사진 메시지 전송 (입력창 글은 사진 설명으로 보내지 않고 그대로 둠)
  void _sendImage({required List<String> imageUrls}) {
    if (imageUrls.isEmpty || !mounted) return;
    _sendAttachmentMessage(
      _buildLocalMessage(type: MessageType.image, content: _imageMessageContent, imageUrls: imageUrls),
    );
  }

  /// 사진·위치 전송: 즉시 실패해도 실패 말풍선으로 남겨 다시 보내기 제공 (업로드·위치 선택 반복 방지)
  void _sendAttachmentMessage(ChatMessage localMessage) {
    final isSent = _trySendOverWebSocket(localMessage);
    setState(() => _addLocalMessage(localMessage, isSent: isSent));
    if (!isSent) _showSendFailedSnackBar();
    _scrollToBottom();
  }

  /// 실패 말풍선 다시 보내기: 새 로컬 ID·시각으로 맨 아래 재삽입 (즉시 실패면 실패 말풍선 유지)
  /// 원래 메시지는 대체 목록에 보관 > 실제로는 서버에 저장돼 늦게 온 에코를 흡수
  void _retryFailedMessage(String localId) {
    final failedMessage = _pendingLocalMessages[localId];
    if (failedMessage == null || _isInputDisabled) return;
    final retryMessage = failedMessage.copyWith(
      chatMessageId: buildLocalMessageId(prefix: localMessageIdPrefix),
      createdDate: DateTime.now(),
    );
    if (!_trySendOverWebSocket(retryMessage)) {
      _showSendFailedSnackBar();
      return;
    }
    setState(() {
      _forgetLocalMessage(localId);
      _rememberSupersededMessage(localId, failedMessage);
      _addLocalMessage(retryMessage, isSent: true);
    });
    _scrollToBottom();
  }

  /// 대체된 원래 메시지 보관 (에코 대기 한도 지난 것은 정리)
  void _rememberSupersededMessage(String localId, ChatMessage originalMessage) {
    final now = DateTime.now();
    _supersededLocalMessages.removeWhere(
      (_, message) => now.difference(message.createdDate ?? now) > pendingLocalMessageEchoWindow,
    );
    _supersededLocalMessages[localId] = originalMessage;
  }

  /// 실패 말풍선 삭제 (서버에 없는 메시지라 화면에서만 제거)
  void _deleteFailedMessage(String localId) {
    setState(() => _forgetLocalMessage(localId));
  }

  /// 낙관적 로컬 메시지 생성 (내 메시지, 현재 시각)
  ChatMessage _buildLocalMessage({
    required MessageType type,
    required String content,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) {
    return ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: buildLocalMessageId(prefix: localMessageIdPrefix),
      senderId: _myMemberId,
      createdDate: DateTime.now(),
      content: content,
      type: type,
      imageUrls: imageUrls,
      latitude: latitude,
      longitude: longitude,
    );
  }

  /// 소켓 전송 시도 (미연결 등 즉시 실패면 false)
  bool _trySendOverWebSocket(ChatMessage message) {
    try {
      _wsService.sendMessage(
        chatRoomId: widget.chatRoomId,
        content: message.content ?? '',
        type: message.type ?? MessageType.text,
        imageUrls: message.imageUrls,
        latitude: message.latitude,
        longitude: message.longitude,
      );
      return true;
    } catch (e) {
      debugPrint('[ChatRoom] send failed immediately: $e');
      return false;
    }
  }

  /// 로컬 메시지 목록 추가 (setState 안에서 호출): 전송됨 > 에코 대기 타이머, 즉시 실패 > 실패 표시
  void _addLocalMessage(ChatMessage localMessage, {required bool isSent}) {
    final localId = localMessage.chatMessageId!;
    _messages.insert(0, localMessage);
    _pendingLocalMessages[localId] = localMessage;
    if (isSent) {
      _sendEchoTimeoutTimers[localId] = Timer(_sendEchoTimeout, () => _markLocalMessageFailed(localId));
    } else {
      _failedLocalMessageIds.add(localId);
    }
  }

  /// 에코 대기 시간 초과 > 실패 표시 (그 사이 확정됐으면 무시)
  void _markLocalMessageFailed(String localId) {
    _sendEchoTimeoutTimers.remove(localId);
    if (!mounted || !_pendingLocalMessages.containsKey(localId)) return;
    setState(() => _failedLocalMessageIds.add(localId));
    _showSendFailedSnackBar();
  }

  /// 로컬 메시지 전송 추적 해제 (대기 목록·실패 표시·타이머)
  void _clearLocalSendState(String localId) {
    _pendingLocalMessages.remove(localId);
    _failedLocalMessageIds.remove(localId);
    _sendEchoTimeoutTimers.remove(localId)?.cancel();
  }

  /// 로컬 메시지 완전 제거 (전송 추적 해제 + 목록에서 삭제, setState 안에서 호출)
  void _forgetLocalMessage(String localId) {
    _clearLocalSendState(localId);
    _messages.removeWhere((message) => message.chatMessageId == localId);
  }

  void _showSendFailedSnackBar() {
    if (!mounted) return;
    CommonSnackBar.show(context: context, message: _sendFailedMessage, type: SnackBarType.error);
  }

  /// 이미지 주소 없는 WS 임시 메시지 > 최근 20건 재조회로 서버 이미지 메시지 교체
  Future<void> _batchFetchWsImageUrls() async {
    if (_pendingWsImageTempIds.isEmpty || !mounted) return;
    try {
      final response = await _chatRepository.getChatMessages(
        chatRoomId: widget.chatRoomId,
        pageNumber: 0,
        pageSize: 20,
      );
      if (!mounted) return;

      final replacements = matchWebSocketImagePlaceholders(
        messages: _messages,
        placeholderIds: _pendingWsImageTempIds,
        serverMessages: response.messages?.content ?? [],
      );
      setState(() {
        for (final (placeholderId, index, replacement) in replacements) {
          _messages[index] = replacement;
          _pendingWsImageTempIds.remove(placeholderId);
        }
      });
    } catch (e) {
      debugPrint('[ChatRoom] WebSocket 이미지 URL 일괄 보완 실패: $e');
    }
  }

  /// 오류 > 사용자 안내 문구 스낵바 (mounted 확인은 호출부)
  void _showErrorSnackBar(Object error) {
    CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(error), type: SnackBarType.error);
  }
}
