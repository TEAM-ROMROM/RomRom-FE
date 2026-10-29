// 채팅방 교환 완료 액션: 요청·자동 요청·취소·거절·확인, 거래 완료 전파, 후기 화면 이동
part of '../chat_room_screen.dart';

mixin _ChatRoomTradeActions on _ChatRoomScreenStateFields, _ChatRoomMessaging {
  /// 진입 직후 교환 완료 요청 자동 실행 (이미 완료·진행 중이면 안내만)
  void _autoRequestTradeCompletion() {
    if (!mounted) return;
    if (_isTradeCompleted) {
      CommonSnackBar.show(context: context, message: '이미 교환이 완료된 거래입니다.', type: SnackBarType.info);
      return;
    }
    if (_hasActiveTradeRequest) {
      CommonSnackBar.show(context: context, message: '교환 요청이 진행 중입니다.', type: SnackBarType.info);
      return;
    }
    _doRequestTradeCompletion();
  }

  /// 교환 완료 요청 플로우: 바텀시트 → API 호출
  Future<void> _onRequestExchange() async {
    if (_isTradeCompleted || _isPendingTradeAction || _hasActiveTradeRequest) {
      CommonSnackBar.show(context: context, message: '이미 교환이 완료되었거나 요청이 진행 중입니다.', type: SnackBarType.info);
      return;
    }

    FocusScope.of(context).unfocus();

    await ExchangeRequestBottomSheet.show(
      context: context,
      chatRoom: chatRoom,
      myMemberId: _myId,
      onConfirm: _doRequestTradeCompletion,
    );
  }

  /// 교환 완료 요청 (바텀시트 확인 후 호출, fire-and-forget)
  void _doRequestTradeCompletion() {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    debugPrint('[ChatRoom] 교환 완료 요청 API 호출 시작: chatRoomId=${widget.chatRoomId}');
    _chatRepository
        .requestTradeCompletion(chatRoomId: widget.chatRoomId)
        .then((_) {
          debugPrint('[ChatRoom] 교환 완료 요청 API 성공');
          if (!mounted) return;
          setState(() {
            _isPendingTradeAction = false;
            // 낙관적 업데이트: 백엔드 WS 브로드캐스트가 요청자에게 도달하지 않는 경우를 대비해
            // REST API 성공 즉시 로컬 메시지를 삽입해 요청 카드를 표시한다.
            // WS 에코가 나중에 도착하면 _handleIncomingMessage에서 이 로컬 메시지를 교체한다.
            final latestMyRequestIndex = _messages.indexWhere(
              (m) => m.type == MessageType.tradeCompleteRequest && m.senderId == _myMemberId,
            );
            final alreadyReceived =
                latestMyRequestIndex != -1 &&
                isActiveTradeRequestAt(
                  messages: _messages,
                  index: latestMyRequestIndex,
                  isTradeCompleted: _isTradeCompleted,
                );
            if (!alreadyReceived) {
              _messages.insert(
                0,
                ChatMessage(
                  chatRoomId: widget.chatRoomId,
                  chatMessageId: _latestLocalTradeRequestId,
                  senderId: _myMemberId,
                  createdDate: DateTime.now(),
                  type: MessageType.tradeCompleteRequest,
                ),
              );
            }
          });
        })
        .catchError((e) {
          debugPrint('[ChatRoom] 교환 완료 요청 API 실패: $e');
          if (mounted) {
            setState(() => _isPendingTradeAction = false);
            _showErrorSnackBar(e);
          }
        });
  }

  Future<void> _onCancelTradeRequest() async {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    try {
      await _chatRepository.cancelTradeCompletionRequest(chatRoomId: widget.chatRoomId);
    } catch (e) {
      if (mounted) _showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _isPendingTradeAction = false);
    }
  }

  Future<void> _onRejectTradeRequest() async {
    if (_isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    try {
      await _chatRepository.rejectTradeCompletion(chatRoomId: widget.chatRoomId);
      // 거래완료 거절 전파: 요청관리 탭이 myItemsProvider listen으로 받아 받은/보낸 요청 재조회.
      if (mounted) ref.read(myItemsProvider.notifier).reload();
    } catch (e) {
      if (mounted) _showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _isPendingTradeAction = false);
    }
  }

  /// 교환 완료 확인: 되돌릴 수 없음 확인 모달 > 완료 API > 후기 작성 화면
  Future<void> _onConfirmTradeRequest() async {
    if (_isPendingTradeAction) return;
    final bool? isTradeCompletionConfirmed = await CommonModal.confirm(
      context: context,
      message: '거래를 완료하면 되돌릴 수 없어요.\n완료하시겠어요?',
      confirmText: '완료하기',
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
    if (isTradeCompletionConfirmed != true || !mounted || _isPendingTradeAction) return;
    setState(() => _isPendingTradeAction = true);
    try {
      await _chatRepository.confirmTradeCompletion(chatRoomId: widget.chatRoomId);
      _reloadTradeAffectedLists();
      if (!mounted) return;
      _openTradeReviewScreen();
    } catch (e) {
      if (mounted) _showErrorSnackBar(e);
    } finally {
      if (mounted) setState(() => _isPendingTradeAction = false);
    }
  }

  /// 거래완료 전파: 홈 카드 덱 등 구독 화면이 내 물건·채팅 목록을 재조회하도록 알림
  void _reloadTradeAffectedLists() {
    ref.read(myItemsProvider.notifier).reload();
    ref.read(chatRoomsProvider.notifier).reload();
  }

  /// 후기 작성 화면 이동 (거래 기록 ID 있을 때만, 이동 시 중복 진입 방지 표시)
  void _openTradeReviewScreen() {
    final tradeRequestHistoryId = chatRoom.tradeRequestHistory?.tradeRequestHistoryId;
    if (tradeRequestHistoryId == null) return;
    _reviewNavigated = true;
    context.navigateTo(
      screen: TradeReviewScreen(tradeRequestHistoryId: tradeRequestHistoryId, opponentNickname: _opponentNickname),
    );
  }
}
