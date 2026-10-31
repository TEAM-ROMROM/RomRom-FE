// 채팅방 AI 행동 추천: 추천 소켓 구독, 노출 판정, 추천 행동 실행(기존 위치·교환 완료 플로우 재사용), 닫기 (#759)
part of '../chat_room_screen.dart';

mixin _ChatRoomRecommendationActions
    on _ChatRoomScreenStateFields, _ChatRoomMessaging, _ChatRoomTradeActions, _ChatRoomAttachmentSending {
  ChatRecommendationNotifier get _recommendationNotifier => ref.read(chatRecommendationProvider.notifier);

  /// 추천 이벤트 구독 (사용자 전용 큐, 화면당 1회) > 수신 추천을 provider에 반영
  void _subscribeToRecommendations() {
    if (_recommendationSubscription != null) return;
    _recommendationSubscription = _wsService.subscribeToRecommendations(widget.chatRoomId).listen((recommendation) {
      if (!mounted) return;
      debugPrint('[ChatRoom] recommendation received: action=${recommendation.action.serverName}');
      _recommendationNotifier.applyServerRecommendation(widget.chatRoomId, recommendation);
    });
  }

  /// 배너에 띄울 추천 행동 (없거나 지금 실행 불가 > null)
  ChatRecommendedAction? _resolveVisibleRecommendedAction(ChatActionRecommendation? recommendation) {
    if (recommendation == null || _myMemberId == null) return null;
    final bool canPerform = canPerformRecommendedAction(
      action: recommendation.action,
      isInputDisabled: _isInputDisabled,
      isTradeCompleted: _isTradeCompleted,
      isTradeActionPending: _isPendingTradeAction,
      activeTradeRequestSenderId: findActiveTradeRequestSenderId(
        messages: _messages,
        isTradeCompleted: _isTradeCompleted,
      ),
      myMemberId: _myMemberId,
    );
    return canPerform ? recommendation.action : null;
  }

  /// 추천 닫기 (같은 추천 재노출 안 함)
  void _onRecommendationDismissed() => _recommendationNotifier.dismiss(widget.chatRoomId);

  /// 추천 행동 실행: 추천 닫기(중복 탭 방지) > 행동별 기존 플로우 (취소·거절은 확인 모달 먼저)
  Future<void> _onRecommendedActionPressed(ChatRecommendedAction action) async {
    _recommendationNotifier.dismiss(widget.chatRoomId);
    switch (action) {
      case ChatRecommendedAction.none:
        return;
      case ChatRecommendedAction.sendLocation:
        await _onSendLocation();
      case ChatRecommendedAction.requestTradeCompletion:
        await _onRequestExchange();
      case ChatRecommendedAction.cancelTradeCompletionRequest:
        final bool isCancelConfirmed = await _confirmRecommendedTradeAction(
          message: '보낸 교환 완료 요청을 취소할까요?',
          confirmText: '요청 취소',
        );
        if (isCancelConfirmed && mounted) await _onCancelTradeRequest();
      case ChatRecommendedAction.rejectTradeCompletionRequest:
        final bool isRejectConfirmed = await _confirmRecommendedTradeAction(
          message: '교환 완료 요청을 거절할까요?',
          confirmText: '거절하기',
        );
        if (isRejectConfirmed && mounted) await _onRejectTradeRequest();
      case ChatRecommendedAction.confirmTradeCompletion:
        await _onConfirmTradeRequest();
    }
  }

  /// 추천으로 실행하는 교환 요청 취소·거절 확인 모달 (확인 > true)
  Future<bool> _confirmRecommendedTradeAction({required String message, required String confirmText}) async {
    final bool? isConfirmed = await CommonModal.confirm(
      context: context,
      message: message,
      confirmText: confirmText,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    return isConfirmed == true;
  }
}
