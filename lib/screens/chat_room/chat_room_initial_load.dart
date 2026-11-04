// 채팅방 진입 초기화: 메시지 구독(조회 중 수신분 보관) > 메시지·읽음 상태 조회 > 보관분 병합, 상대 접속 폴링, 읽음·AI 추천·재연결 구독, 알림 안내, 안내 모달
part of '../chat_room_screen.dart';

mixin _ChatRoomInitialLoad
    on _ChatRoomScreenStateFields, _ChatRoomMessaging, _ChatRoomTradeActions, _ChatRoomRecommendationActions {
  /// 채팅방 초기화: 회원 ID > 메시지 구독 > 소켓 연결·메시지(AI 추천 포함)·읽음 상태 동시 조회 > 보관분 병합 > 상대 상태 폴링 > 추천·읽음·재연결 구독 > 안내 (알림 시트 > 모달)
  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      _liveMessagesDuringInitialLoad.clear();

      _myMemberId = await MemberManager.getCurrentMemberId();
      if (_myMemberId == null) throw Exception('사용자 정보를 불러올 수 없습니다');
      if (!mounted) return;

      // 조회 전 구독: 조회 응답 이후 도착분 유실 방지 (조회 중 수신분은 보관 > 조회 결과와 병합)
      _startRoomMessageSubscription();
      // 조회 시작 때 미연결이면 실제 구독 시작 전 공백 > 연결 후 재조회 1회
      final isSubscribedBeforeFetch = _wsService.isConnected;

      // 서로 의존 없는 3개 동시 시작, 첫 실패 즉시 아래 catch (나머지 오류는 Future.wait가 처리)
      final chatRepository = _chatRepository;
      final messagesLoading = chatRepository.getChatMessages(
        chatRoomId: widget.chatRoomId,
        pageNumber: 0,
        pageSize: chatMessagePageSize,
      );
      final readStatusLoading = chatRepository.getChatRoomReadStatus(chatRoomId: widget.chatRoomId);
      await Future.wait([_wsService.connect(), messagesLoading, readStatusLoading], eagerError: true);
      final response = await messagesLoading;
      final opponentState = await readStatusLoading;
      if (!mounted) return;

      setState(() {
        chatRoom = response.chatRoom!;
        _messages = response.messages?.content ?? [];
        _opponentState = opponentState;
        _nextOlderMessagePageNumber = 1;
        _hasMoreOlderMessages = !(response.messages?.last ?? true);
        _isLoading = false;
      });
      _recommendationNotifier.applyServerRecommendation(widget.chatRoomId, response.latestRecommendation);
      _applyLiveMessagesReceivedDuringLoad();
      if (!isSubscribedBeforeFetch) unawaited(_resyncAfterFirstConnection());

      _startOpponentStatusPolling();
      _subscribeToRecommendations();
      _scrollToBottom();
      _updateReadCursorInBackground(isEntered: true);
      // 채팅 목록·탭바 안 읽음 해제 (알림 등 목록 밖 진입 포함)
      ref.read(chatRoomsProvider.notifier).markRoomAsRead(widget.chatRoomId);
      _subscribeToReadEvents();
      // WebSocket 재연결 시 메시지 재동기화 (단절 구간 유실 복구)
      _reconnectSubscription ??= _wsService.onReconnected.listen((_) => _resyncMessages());

      // 안내는 읽음·구독을 막지 않게 뒤에서 순서대로
      unawaited(_showEntryGuidesInOrder());
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

  @override
  void _startRoomMessageSubscription() {
    if (_messageSubscription != null) return;
    _messageSubscription = _wsService.subscribeToChatRoom(widget.chatRoomId).listen(_onChatRoomMessageReceived);
  }

  @override
  void _stopRoomMessageSubscription() {
    final messageSubscription = _messageSubscription;
    if (messageSubscription == null) return;
    _messageSubscription = null;
    unawaited(messageSubscription.cancel());
    _wsService.unsubscribeFromChatRoom(widget.chatRoomId);
  }

  /// 조회 중 보관한 소켓 메시지 반영: 조회 결과에 없는 것만 수신 처리 (ID 중복 제거)
  void _applyLiveMessagesReceivedDuringLoad() {
    final unseenLiveMessages = findUnseenLiveMessages(
      liveMessages: _liveMessagesDuringInitialLoad,
      displayedMessages: _messages,
    );
    _liveMessagesDuringInitialLoad.clear();
    unseenLiveMessages.forEach(_onChatRoomMessageReceived);
  }

  /// 조회 시작 때 소켓 미연결: 연결(실제 구독 시작) 후 재조회로 공백 구간 메시지 병합
  Future<void> _resyncAfterFirstConnection() async {
    await _wsService.waitUntilConnected();
    if (mounted) await _resyncMessages();
  }

  /// 상대방 접속 상태: 초기값 반영 > 내 상대 결과만 구독 > 이 화면 소유로 폴러 시작
  void _startOpponentStatusPolling() {
    final initialOpponent = chatRoom.getOpponent(_myMemberId!);
    final opponentId = initialOpponent?.memberId;
    if (opponentId == null) return;
    setState(() {
      _opponentLastActiveAt = initialOpponent?.lastActiveAt;
      _isOpponentOnline = initialOpponent?.isOnline ?? false;
    });
    _pollerSubscription?.cancel();
    _pollerSubscription = ChatMemberStatusPoller.instance.streamOf(opponentId).listen((member) {
      if (!mounted) return;
      setState(() {
        _opponentLastActiveAt = member.lastActiveAt;
        _isOpponentOnline = member.isOnline ?? false;
      });
    });
    ChatMemberStatusPoller.instance.start(opponentId, owner: this);
  }

  /// 읽음 이벤트 WebSocket 구독 (REST 폴링 대체, 화면당 1회)
  void _subscribeToReadEvents() {
    if (_readEventSubscription != null) return;
    _readEventSubscription = _wsService.subscribeToReadEvents(widget.chatRoomId).listen((state) {
      if (state.memberId == _myMemberId || !mounted) return;
      setState(() => _opponentState = state);
      debugPrint('[ChatRoom] 읽음 이벤트 수신: isPresent=${state.isPresent}, leftAt=${state.leftAt}');
    });
  }

  /// 채팅방 메시지 수신: 조회 중 보관 > 내 나가기 무시 > 목록 반영 > 맨 아래 근처·내 메시지면 스크롤 > 비속어 경고 > 상대 퇴장 모달 > 거래 완료 시 후기 화면
  void _onChatRoomMessageReceived(ChatMessage newMessage) {
    debugPrint(
      '[ChatRoom] 🔔 메시지 수신: type=${newMessage.type}, id=${newMessage.chatMessageId}, senderId=${newMessage.senderId}',
    );
    if (!mounted) return;
    if (_isLoading || _hasError) {
      _liveMessagesDuringInitialLoad.add(newMessage);
      return;
    }
    // 방 삭제 시 내 나가기 방송 (상대 퇴장 모달 오표시 방지)
    if (isOwnLeaveMessage(message: newMessage, myMemberId: _myMemberId)) return;

    // 반영 전 위치로 판정 (반영 후엔 새 말풍선 높이만큼 달라짐)
    final shouldScrollToBottom = shouldAutoScrollOnIncomingMessage(
      isMyMessage: newMessage.senderId == _myMemberId,
      distanceFromBottomPixels: _scrollController.hasClients ? _scrollController.offset : 0,
    );
    var isMessageAdded = false;
    setState(() => isMessageAdded = _handleIncomingMessage(newMessage));
    if (!isMessageAdded) return;
    if (shouldScrollToBottom) _scrollToBottom();

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

  /// 진입 안내 순서: 알림 안내 시트(세션 1회) > 탈퇴한 상대 모달 > 나간 상대 모달 > 교환 완료 자동 요청
  Future<void> _showEntryGuidesInOrder() async {
    await _showChatNotificationGuideOnce();
    if (!mounted) return;

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

    if (widget.autoTriggerExchangeRequest) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoRequestTradeCompletion());
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

  /// 알림 꺼진 경우 바텀시트 안내 (로그인 세션 당 1회, chatNotificationGuideProvider 소유)
  Future<void> _showChatNotificationGuideOnce() async {
    if (!mounted || ref.read(chatNotificationGuideProvider)) return;
    try {
      final bool permissionGranted = await NotificationPermissionService().isPermissionGranted();
      if (!mounted) return;
      final memberProfile = await ref.read(memberProfileProvider.notifier).fetchCachedOrReload();
      if (!mounted) return;
      final bool chatNotificationAgreed = memberProfile.member?.isChatNotificationAgreed ?? true;
      if (permissionGranted && chatNotificationAgreed) return;
      // 대기 중 다른 채팅방이 먼저 띄웠으면 생략
      if (ref.read(chatNotificationGuideProvider)) return;
      ref.read(chatNotificationGuideProvider.notifier).markShown();
      await NotificationBottomSheet.showChatNotificationBottomSheet(context);
    } catch (e) {
      debugPrint('알림 권한 안내 노출 실패: $e');
    }
  }
}
