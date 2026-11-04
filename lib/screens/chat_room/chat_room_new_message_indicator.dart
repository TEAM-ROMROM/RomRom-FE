// 채팅방 맨 아래로 버튼·새 메시지 알림: 맨 아래에서 멀어지면 버튼, 그동안 온 상대 메시지 수 > '새 메시지 N' (맨 아래 근처 기준은 자동 스크롤과 공통)
part of '../chat_room_screen.dart';

mixin _ChatRoomNewMessageIndicator on _ChatRoomScreenStateFields, _ChatRoomScrollToBottom {
  // 맨 아래(최신)에서 멀어졌는지 (맨 아래로 버튼 노출)
  bool _isAwayFromBottom = false;
  // 위로 보는 중 쌓인 상대 새 메시지 수 (맨 아래 도착·버튼 탭 > 0)
  int _unseenIncomingMessageCount = 0;

  /// 스크롤: 맨 아래 근처 > 버튼 숨김·새 메시지 수 초기화, 멀어짐 > 버튼 노출 (값 바뀔 때만 다시 그림)
  void _onScrollPositionChangedForLatestButton() {
    if (!_scrollController.hasClients) return;
    final isAwayFromBottom = !isNearBottom(distanceFromBottomPixels: _scrollController.offset);
    final unseenIncomingMessageCount = isAwayFromBottom ? _unseenIncomingMessageCount : 0;
    if (isAwayFromBottom == _isAwayFromBottom && unseenIncomingMessageCount == _unseenIncomingMessageCount) return;
    setState(() {
      _isAwayFromBottom = isAwayFromBottom;
      _unseenIncomingMessageCount = unseenIncomingMessageCount;
    });
  }

  /// 수신 메시지 반영 후 새 메시지 수 갱신 (자동 스크롤 안 된 상대 메시지만 +1)
  void _countIncomingMessageWhileAway({required bool isMyMessage, required bool isAutoScrolled}) {
    final nextCount = countUnseenIncomingMessages(
      currentCount: _unseenIncomingMessageCount,
      isMyMessage: isMyMessage,
      isAutoScrolled: isAutoScrolled,
    );
    if (nextCount != _unseenIncomingMessageCount) setState(() => _unseenIncomingMessageCount = nextCount);
  }

  /// 맨 아래로 버튼 탭: 새 메시지 수 초기화 > 맨 아래로 스크롤
  void _onScrollToLatestPressed() {
    setState(() => _unseenIncomingMessageCount = 0);
    _scrollToBottom();
  }

  /// 메시지 목록 위 오른쪽 아래 버튼 (Stack 자식)
  Widget _buildScrollToLatestButton() {
    return Positioned(
      right: 16,
      bottom: 12,
      child: ChatScrollToLatestButton(
        isVisible: _isAwayFromBottom,
        unseenMessageCount: _unseenIncomingMessageCount,
        onPressed: _onScrollToLatestPressed,
      ),
    );
  }
}
