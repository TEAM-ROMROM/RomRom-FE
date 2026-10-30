// 채팅방 메시지 송수신: 수신 반영(중복·낙관적 교체), 텍스트·이미지 전송, WS 이미지 보완, 재연결 동기화
part of '../chat_room_screen.dart';

// WS 이미지 URL 일괄 조회 대기 시간 (연속 수신 묶음)
const Duration _wsImageFetchBatchDelay = Duration(milliseconds: 500);
// 하단 스크롤 전 레이아웃 반영 대기 시간
const Duration _scrollToBottomLayoutDelay = Duration(milliseconds: 100);

mixin _ChatRoomMessaging on _ChatRoomScreenStateFields {
  /// 재연결 시 호출: 서버에서 최신 메시지를 재조회해 유실분을 병합한다.
  Future<void> _resyncMessages() async {
    if (_isResyncing || !mounted) return;
    _isResyncing = true;
    try {
      final response = await _chatRepository.getChatMessages(
        chatRoomId: widget.chatRoomId,
        pageNumber: 0,
        pageSize: 50,
      );
      if (!mounted) return;
      final serverMessages = response.messages?.content ?? [];
      setState(() {
        _messages = mergeServerMessages(current: _messages, serverMessages: serverMessages);
      });
      debugPrint('[ChatRoom] 🔁 재연결 동기화 완료: 서버 ${serverMessages.length}건 병합');
    } catch (e) {
      // 백그라운드 동기화이므로 사용자에게 노출하지 않음. 다음 재연결 때 재시도.
      debugPrint('[ChatRoom] 재연결 동기화 실패(무시): $e');
    } finally {
      _isResyncing = false;
    }
  }

  /// 수신 메시지 반영: 중복 무시 > 텍스트 전송 대기 해제 > 낙관적 로컬 메시지 교체 또는 새로 삽입
  void _handleIncomingMessage(ChatMessage newMessage) {
    debugPrint('[ChatRoom] _handleIncomingMessage: type=${newMessage.type}, id=${newMessage.chatMessageId}');
    final newId = newMessage.chatMessageId;
    final isDuplicate = (newId != null) && _messages.any((m) => m.chatMessageId != null && m.chatMessageId == newId);
    if (isDuplicate) {
      debugPrint('[ChatRoom] 중복 메시지 수신 무시: chatMessageId=$newId');
      return;
    }

    if (newMessage.senderId == _myMemberId && newMessage.type == MessageType.text) {
      _isSendingMessage = false;
      _sendMessageTimeoutTimer?.cancel();
    }

    // pending 로컬 메시지와 매칭 시도 (이미지 낙관적 업데이트 교체)
    final matchedLocalId = findMatchingPendingLocalMessageId(
      pendingLocalMessages: _pendingLocalMessages,
      incomingMessage: newMessage,
      myMemberId: _myMemberId,
    );
    if (matchedLocalId != null) {
      final localMessage = _pendingLocalMessages.remove(matchedLocalId)!;
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
      final tempId = 'ws_img_${DateTime.now().microsecondsSinceEpoch}';
      _messages.insert(0, newMessage.copyWith(chatMessageId: tempId));
      _pendingWsImageTempIds.add(tempId);
      _wsImageFetchTimer?.cancel();
      _wsImageFetchTimer = Timer(_wsImageFetchBatchDelay, _batchFetchWsImageUrls);
    } else {
      _messages.insert(0, newMessage);
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSendingMessage || _isInputDisabled) return;

    // 낙관적 삽입: WS 에코를 기다리지 않고 즉시 화면에 표시한다.
    // 연결이 끊긴 상태에서도 내 메시지는 바로 보이고, WS 에코 도착 시
    // _handleIncomingMessage의 매칭 로직이 실제 서버 메시지로 교체한다.
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMsg = ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: localId,
      senderId: _myMemberId,
      createdDate: DateTime.now(),
      content: content,
      type: MessageType.text,
    );

    setState(() {
      _isSendingMessage = true;
      _messages.insert(0, localMsg);
      _pendingLocalMessages[localId] = localMsg;
    });
    _messageController.clear();
    _scrollToBottom();

    _sendMessageTimeoutTimer?.cancel();
    _sendMessageTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isSendingMessage) {
        setState(() => _isSendingMessage = false);
        CommonSnackBar.show(context: context, message: '메시지 전송에 실패했습니다.', type: SnackBarType.error);
      }
    });

    _wsService.sendMessage(chatRoomId: widget.chatRoomId, content: content, type: MessageType.text);
  }

  Future<void> _sendImage({required List<String> imageUrls, String? imageMessage}) async {
    if (imageUrls.isEmpty || !mounted) return;

    final content = imageMessage ?? '사진을 보냈습니다.';
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMsg = ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: localId,
      senderId: _myMemberId,
      createdDate: DateTime.now(),
      content: content,
      type: MessageType.image,
      imageUrls: imageUrls,
    );
    setState(() {
      _messages.insert(0, localMsg);
      _pendingLocalMessages[localId] = localMsg;
    });
    _scrollToBottom();

    _wsService.sendMessage(
      chatRoomId: widget.chatRoomId,
      type: MessageType.image,
      content: imageMessage ?? '사진을 보냈습니다.',
      imageUrls: imageUrls,
    );
    _messageController.clear();
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

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(_scrollToBottomLayoutDelay, () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(0.0, duration: AppMotion.normal, curve: AppMotion.entry);
        }
      });
    }
  }

  /// 오류 > 사용자 안내 문구 스낵바 (mounted 확인은 호출부)
  void _showErrorSnackBar(Object error) {
    CommonSnackBar.show(context: context, message: ErrorUtils.getErrorMessage(error), type: SnackBarType.error);
  }
}
