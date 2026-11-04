// 채팅방 메시지 확장 동작: 메시지 변경 구독(삭제·약속 상태), 방별 알림 끄기, 내 메시지 삭제, 메시지 신고, 약속 제안·수락·취소 (#1006)
part of '../chat_room_screen.dart';

mixin _ChatRoomMessageActions on _ChatRoomScreenStateFields, _ChatRoomScrollToBottom, _ChatRoomMessaging {
  // 메시지 변경본 구독 (/sub/chat.update.{chatRoomId})
  StreamSubscription<ChatMessage>? _messageUpdateSubscription;
  // 삭제·약속 수락·취소 진행 중 메시지 ID (같은 메시지 중복 요청 방지, 해제는 finally)
  final Set<String> _pendingMessageActionIds = {};
  // 방별 알림 끄기 요청 중 / 약속 제안 요청 중 (중복 실행 방지)
  bool _isUpdatingNotificationMute = false;
  bool _isProposingAppointment = false;

  /// 메시지 변경 구독 시작 (화면당 1회)
  void _startMessageUpdateSubscription() {
    _messageUpdateSubscription ??= _wsService.subscribeToMessageUpdates(widget.chatRoomId).listen(_applyUpdatedMessage);
  }

  /// 메시지 변경 구독 해제 (구독 안 했으면 무시)
  void _stopMessageUpdateSubscription() {
    final messageUpdateSubscription = _messageUpdateSubscription;
    if (messageUpdateSubscription == null) return;
    _messageUpdateSubscription = null;
    unawaited(messageUpdateSubscription.cancel());
    _wsService.unsubscribeFromMessageUpdates(widget.chatRoomId);
  }

  /// 변경본 반영: 같은 ID 메시지 교체 (목록에 없으면 무시 > 이전 페이지·재동기화가 서버 버전 반영)
  void _applyUpdatedMessage(ChatMessage updatedMessage) {
    if (!mounted) return;
    final replacedMessages = replaceMessageById(messages: _messages, updatedMessage: updatedMessage);
    if (replacedMessages == null) return;
    setState(() => _messages = replacedMessages);
  }

  /// 방별 알림 끄기·켜기: chatRoomsProvider 경유 (목록 아이콘 동시 갱신) > 확정 값 반영·안내
  Future<void> _onToggleNotificationMute() async {
    if (_isUpdatingNotificationMute) return;
    _isUpdatingNotificationMute = true;
    try {
      final bool confirmedIsMuted = await ref
          .read(chatRoomsProvider.notifier)
          .setNotificationMuted(chatRoomId: widget.chatRoomId, isNotificationMuted: !_isNotificationMuted);
      if (!mounted) return;
      setState(() => _isNotificationMuted = confirmedIsMuted);
      CommonSnackBar.show(
        context: context,
        message: confirmedIsMuted ? '이 채팅방 알림을 껐어요' : '이 채팅방 알림을 켰어요',
        type: SnackBarType.success,
      );
    } catch (error) {
      if (mounted) _showErrorSnackBar(error);
    } finally {
      _isUpdatingNotificationMute = false;
    }
  }

  /// 내 메시지 삭제: 확인 모달 > 삭제 API > 삭제 반영본으로 교체 (상대 화면은 변경 이벤트로 교체)
  Future<void> _onDeleteMessage(ChatMessage message) async {
    final messageId = message.chatMessageId;
    if (messageId == null || _pendingMessageActionIds.contains(messageId)) return;
    final bool? isConfirmed = await CommonModal.confirm(
      context: context,
      message: '메시지를 삭제할까요?\n상대방 화면에서도 삭제됩니다.',
      confirmText: '삭제',
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (isConfirmed != true || !mounted) return;
    await _runMessageAction(
      messageId,
      () => _chatRepository.deleteMessage(chatRoomId: widget.chatRoomId, chatMessageId: messageId),
    );
  }

  /// 상대 메시지 신고: 신고 화면 (회원 신고 사유) > 성공 시 접수 안내
  Future<void> _onReportMessage(ChatMessage message) async {
    final messageId = message.chatMessageId;
    if (messageId == null) return;
    final bool? isReported = await context.navigateTo<bool>(
      screen: ReportScreen.chatMessage(chatRoomId: widget.chatRoomId, chatMessageId: messageId),
    );
    if (isReported != true || !mounted) return;
    await CommonModal.success(context: context, message: '신고가 접수되었습니다.', onConfirm: () => Navigator.of(context).pop());
  }

  /// 약속 수락 (제안 받은 사람)
  Future<void> _onAcceptAppointment(ChatMessage message) async {
    final messageId = message.chatMessageId;
    if (messageId == null) return;
    await _runMessageAction(
      messageId,
      () => _chatRepository.acceptAppointment(chatRoomId: widget.chatRoomId, chatMessageId: messageId),
    );
  }

  /// 약속 취소: 확인 모달 > 취소 API
  Future<void> _onCancelAppointment(ChatMessage message) async {
    final messageId = message.chatMessageId;
    if (messageId == null || _pendingMessageActionIds.contains(messageId)) return;
    final bool? isConfirmed = await CommonModal.confirm(
      context: context,
      message: '약속을 취소할까요?',
      cancelText: '닫기',
      confirmText: '약속 취소',
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (isConfirmed != true || !mounted) return;
    await _runMessageAction(
      messageId,
      () => _chatRepository.cancelAppointment(chatRoomId: widget.chatRoomId, chatMessageId: messageId),
    );
  }

  /// 메시지 단위 API 공통: 진행 중 표시 > 요청 > 응답 변경본 교체 > 실패 안내 (진행 표시 해제는 finally)
  Future<void> _runMessageAction(String messageId, Future<ChatMessage?> Function() request) async {
    if (_pendingMessageActionIds.contains(messageId)) return;
    setState(() => _pendingMessageActionIds.add(messageId));
    try {
      final updatedMessage = await request();
      if (updatedMessage != null) _applyUpdatedMessage(updatedMessage);
    } catch (error) {
      if (mounted) _showErrorSnackBar(error);
    } finally {
      if (mounted) setState(() => _pendingMessageActionIds.remove(messageId));
    }
  }

  /// 약속 잡기: 시트(일시·장소, 지도 위치 선택) > 제안 API > 생성 메시지 목록 반영 (소켓 에코는 ID 중복으로 무시)
  Future<void> _onProposeAppointment() async {
    if (_isInputDisabled || _isProposingAppointment) return;
    FocusScope.of(context).unfocus();
    final proposal = await showChatAppointmentProposalSheet(
      context: context,
      onPickLocation: () => context.navigateTo<LocationAddress>(screen: const ChatLocationPickerScreen()),
    );
    if (proposal == null || !mounted) return;

    _isProposingAppointment = true;
    try {
      final proposedMessage = await _chatRepository.proposeAppointment(
        chatRoomId: widget.chatRoomId,
        appointmentAt: proposal.appointmentAt,
        placeName: proposal.placeName,
        latitude: proposal.latitude,
        longitude: proposal.longitude,
      );
      if (!mounted || proposedMessage == null) return;
      setState(() => _handleIncomingMessage(proposedMessage));
      _scrollToBottom();
    } catch (error) {
      if (mounted) _showErrorSnackBar(error);
    } finally {
      _isProposingAppointment = false;
    }
  }
}
