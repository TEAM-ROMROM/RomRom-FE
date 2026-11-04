// 채팅방 진입 위치: 안 읽은 첫 메시지 찾기(이전 페이지 최대 3번 더) > '여기까지 읽었어요' 구분선 > 그 위치로 이동 (못 찾으면 맨 아래)
part of '../chat_room_screen.dart';

// 구분선 찾으며 위로 한 화면씩 이동할 최대 횟수 (렌더 안 된 먼 위치 대비)
const int _unreadDividerSearchMaximumAttemptCount = 20;
// 구분선 화면 위치 (1.0 맨 위, reverse 목록 기준 > 위쪽에 읽은 메시지 조금 보임)
const double _unreadDividerViewportAlignment = 0.85;

mixin _ChatRoomUnreadPosition on _ChatRoomScreenStateFields, _ChatRoomScrollToBottom, _ChatRoomOlderMessagesPaging {
  // 구분선 위치 이동용 키
  final GlobalKey _unreadDividerKey = GlobalKey();
  // 진입 시점 안 읽음 수 (채팅 목록 전달값 > 없으면 목록 상태, 진입 처리로 0이 되기 전 initState에서 기록)
  int _unreadCountAtEntry = 0;

  /// 진입 시점 안 읽음 수 기록 (initState)
  void _captureUnreadCountAtEntry() {
    final rooms = ref.read(chatRoomsProvider).valueOrNull?.rooms ?? const <ChatRoomDetailDto>[];
    _unreadCountAtEntry =
        widget.unreadCountAtEntry ?? findUnreadCountOfRoom(rooms: rooms, chatRoomId: widget.chatRoomId) ?? 0;
  }

  /// 진입 위치 잡기: 안 읽음 없음 > 맨 아래, 있음 > 첫 안 읽은 메시지 찾기 > 구분선 표시 > 이동 (못 찾으면 맨 아래)
  /// [newestFetchedMessageId]: 진입 조회 최신 메시지 (조회 뒤 실시간 수신분은 안 읽음 계산 제외)
  Future<void> _positionAtFirstUnreadMessage({required String? newestFetchedMessageId}) async {
    if (_unreadCountAtEntry <= 0 || newestFetchedMessageId == null) {
      _scrollToBottom();
      return;
    }
    final firstUnreadMessageId = await _findFirstUnreadMessageIdLoadingOlderPages(newestFetchedMessageId);
    if (!mounted) return;
    if (firstUnreadMessageId == null) {
      _scrollToBottom();
      return;
    }
    setState(() => _firstUnreadMessageId = firstUnreadMessageId);
    await _scrollToUnreadDivider();
  }

  /// 불러온 범위에서 못 찾으면 이전 페이지 조회 반복 (한도·끝·실패 시 중단)
  Future<String?> _findFirstUnreadMessageIdLoadingOlderPages(String newestFetchedMessageId) async {
    var loadedOlderPageCount = 0;
    while (true) {
      final firstUnreadMessageId = findFirstUnreadMessageId(
        messages: _messages.skipWhile((message) => message.chatMessageId != newestFetchedMessageId).toList(),
        myMemberId: _myMemberId,
        unreadCount: _unreadCountAtEntry,
      );
      final shouldLoadOlderPage = shouldLoadOlderPageForUnread(
        isFirstUnreadFound: firstUnreadMessageId != null,
        unreadCount: _unreadCountAtEntry,
        hasMoreOlderMessages: _hasMoreOlderMessages && !_hasOlderMessagesLoadFailed,
        loadedOlderPageCount: loadedOlderPageCount,
      );
      if (!shouldLoadOlderPage) return firstUnreadMessageId;
      await _loadOlderMessages();
      if (!mounted) return null;
      loadedOlderPageCount++;
    }
  }

  /// 구분선까지 이동 (안 그려졌으면 위로 한 화면씩 넘기며 찾기) > 화면 위쪽에 맞춤
  Future<void> _scrollToUnreadDivider() => scrollReverseListToKeyedItem(
    scrollController: _scrollController,
    itemKey: _unreadDividerKey,
    alignment: _unreadDividerViewportAlignment,
    maximumAttemptCount: _unreadDividerSearchMaximumAttemptCount,
    isActive: () => mounted,
  );
}
