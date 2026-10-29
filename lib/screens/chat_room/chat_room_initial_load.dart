// 채팅방 진입 초기화: 메시지·읽음 상태 조회, 상대 접속 폴링, 소켓 구독(메시지·읽음·재연결), 알림 안내, 안내 모달
part of '../chat_room_screen.dart';

mixin _ChatRoomInitialLoad on _ChatRoomScreenStateFields, _ChatRoomMessaging, _ChatRoomTradeActions {
  /// 채팅방 초기화: 메시지·읽음 상태 조회 > 상대 상태 폴링 > 메시지 구독 > 알림 안내 > 읽음·재연결 구독 > 안내 모달
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      _myMemberId = await MemberManager.getCurrentMemberId();
      if (_myMemberId == null) throw Exception('사용자 정보를 불러올 수 없습니다');

      await _wsService.connect();

      final chatRepository = _chatRepository;
      final response = await chatRepository.getChatMessages(chatRoomId: widget.chatRoomId, pageNumber: 0, pageSize: 50);
      final opponentState = await chatRepository.getChatRoomReadStatus(chatRoomId: widget.chatRoomId);
      if (!mounted) return;

      setState(() {
        chatRoom = response.chatRoom!;
        _messages = response.messages?.content ?? [];
        _opponentState = opponentState;
      });

      _startOpponentStatusPolling();
      _messageSubscription = _wsService.subscribeToChatRoom(widget.chatRoomId).listen(_onChatRoomMessageReceived);

      setState(() => _isLoading = false);
      _scrollToBottom();
      chatRepository.updateChatRoomReadCursor(chatRoomId: widget.chatRoomId, isEntered: true);
      await _showChatNotificationGuideOnce();

      // 읽음 이벤트 WebSocket 구독 (REST 폴링 대체)
      _readEventSubscription = _wsService.subscribeToReadEvents(widget.chatRoomId).listen((state) {
        if (state.memberId == _myMemberId || !mounted) return;
        setState(() => _opponentState = state);
        debugPrint('[ChatRoom] 읽음 이벤트 수신: isPresent=${state.isPresent}, leftAt=${state.leftAt}');
      });

      // WebSocket 재연결 시 메시지 재동기화 (단절 구간 유실 복구)
      _reconnectSubscription = _wsService.onReconnected.listen((_) {
        _resyncMessages();
      });

      // 진입 안내 모달 (탈퇴한 상대 > 나간 상대 순, 각 1회)
      CommonModal.showOnceAfterFrame(
        context: context,
        isShown: () => _deleteModalShown,
        markShown: () => _deleteModalShown = true,
        shouldShow: () => _isOpponentDeleted,
        message: '존재하지 않거나 탈퇴한 사용자입니다.',
        onConfirm: () => Navigator.of(context).pop(),
      );
      _showOpponentLeftModalOnce(shouldShow: () => !_deleteModalShown && _hasSystemMessage);

      if (widget.autoTriggerExchangeRequest && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _autoRequestTradeCompletion());
      }
    } catch (e) {
      debugPrint('채팅방 초기화 실패: $e');
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = ErrorUtils.getErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  /// 상대방 접속 상태: 초기값 반영 > 폴러 시작 > 갱신 구독
  void _startOpponentStatusPolling() {
    final initialOpponent = chatRoom.getOpponent(_myMemberId!);
    final opponentId = initialOpponent?.memberId;
    if (opponentId == null) return;
    ChatMemberStatusPoller.instance.start(opponentId);
    setState(() {
      _opponentLastActiveAt = initialOpponent?.lastActiveAt;
      _isOpponentOnline = initialOpponent?.isOnline ?? false;
    });
    _pollerSubscription = ChatMemberStatusPoller.instance.stream.listen((member) {
      if (!mounted) return;
      setState(() {
        _opponentLastActiveAt = member.lastActiveAt;
        _isOpponentOnline = member.isOnline ?? false;
      });
    });
  }

  /// 채팅방 메시지 수신: 목록 반영 > 비속어 경고 > 상대 퇴장 모달 > 거래 완료 시 후기 화면
  void _onChatRoomMessageReceived(ChatMessage newMessage) {
    debugPrint(
      '[ChatRoom] 🔔 메시지 수신: type=${newMessage.type}, id=${newMessage.chatMessageId}, senderId=${newMessage.senderId}',
    );
    if (!mounted) return;
    setState(() => _handleIncomingMessage(newMessage));
    _scrollToBottom();

    // 비속어 경고 (발신자 본인에게만 표시)
    if (newMessage.isProfanityDetected == true && newMessage.senderId == _myMemberId) {
      CommonSnackBar.show(context: context, message: '비속어 사용은 제재 대상이 될 수 있습니다.', type: SnackBarType.info);
    }

    if (newMessage.type == MessageType.system) {
      _showOpponentLeftModalOnce(shouldShow: () => !_deleteModalShown);
    }

    // 상대방이 거래 완료를 수락했을 때 요청자에게도 후기 화면 표시
    if (newMessage.type == MessageType.tradeCompleted && !_reviewNavigated) {
      _reloadTradeAffectedLists();
      _openTradeReviewScreen();
    }
  }

  /// '상대방이 채팅방을 나갔습니다' 모달 (세션 당 1회)
  void _showOpponentLeftModalOnce({required bool Function() shouldShow}) {
    CommonModal.showOnceAfterFrame(
      context: context,
      isShown: () => _systemMessageModalShown,
      markShown: () => _systemMessageModalShown = true,
      shouldShow: shouldShow,
      message: '상대방이 채팅방을 나갔습니다.',
      onConfirm: () => Navigator.of(context).pop(),
    );
  }

  /// 알림 꺼진 경우 바텀시트 안내 (세션 당 1회)
  Future<void> _showChatNotificationGuideOnce() async {
    if (!mounted || _notificationSnackBarShown) return;
    try {
      final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
      final memberProfile = await ref.read(memberProfileProvider.notifier).fetchCachedOrReload();
      final bool chatNotificationAgreed = memberProfile.member?.isChatNotificationAgreed ?? true;
      if (!permissionGranted || !chatNotificationAgreed) {
        _notificationSnackBarShown = true;
        if (mounted) {
          await NotificationBottomSheet.showChatNotificationBottomSheet(context);
        }
      }
    } catch (e) {
      debugPrint('알림 권한 안내 노출 실패: $e');
    }
  }
}
