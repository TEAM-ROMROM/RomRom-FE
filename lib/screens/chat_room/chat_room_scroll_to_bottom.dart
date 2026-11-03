// 채팅방 맨 아래(최신) 스크롤: 메시지 추가 후 다음 프레임 1회 (타이머 없음)
part of '../chat_room_screen.dart';

mixin _ChatRoomScrollToBottom on _ChatRoomScreenStateFields {
  // 맨 아래 스크롤 다음 프레임 예약 여부 (같은 프레임 여러 호출 > 1번)
  bool _isScrollToBottomScheduled = false;

  /// 맨 아래(최신)로 스크롤: 새 메시지 레이아웃 반영된 다음 프레임 1회 (타이머 없음, 같은 프레임 여러 호출 합침, 해제 후 무시)
  void _scrollToBottom() {
    if (!_scrollController.hasClients || _isScrollToBottomScheduled) return;
    _isScrollToBottomScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isScrollToBottomScheduled = false;
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(0.0, duration: AppMotion.normal, curve: AppMotion.entry);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}
