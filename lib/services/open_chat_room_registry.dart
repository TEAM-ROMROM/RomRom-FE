/// 열린 채팅방 화면 목록: 같은 방 중복 열기 방지, 같은 방 다른 화면 생존 여부 판정
/// 화면 상태와 무관한 조회 전용 (구독 UI 없음) > 화면 해제(dispose) 중에도 안전하게 갱신
class OpenChatRoomRegistry {
  // 열린 순서 (마지막 = 가장 최근 화면), 화면 route 맨 위 여부는 등록 시 받은 함수로 판정
  final List<({Object owner, String chatRoomId, bool Function() isRouteCurrent})> _openChatRooms = [];

  /// 채팅방 화면 열림 등록 (같은 소유자 재등록은 교체)
  void register({required Object owner, required String chatRoomId, required bool Function() isRouteCurrent}) {
    unregister(owner: owner);
    _openChatRooms.add((owner: owner, chatRoomId: chatRoomId, isRouteCurrent: isRouteCurrent));
  }

  /// 채팅방 화면 닫힘 해제
  void unregister({required Object owner}) {
    _openChatRooms.removeWhere((openChatRoom) => identical(openChatRoom.owner, owner));
  }

  /// [chatRoomId] 화면이 지금 맨 위에 보이는지 (같은 방 푸시 탭 > 새로 쌓지 않음)
  bool isShowingOnTop(String chatRoomId) =>
      _openChatRooms.any((openChatRoom) => openChatRoom.chatRoomId == chatRoomId && openChatRoom.isRouteCurrent());

  /// [owner] 말고 같은 방 화면이 더 열려 있는지 (퇴장 처리 생략 판정)
  bool hasOtherOpenScreen({required String chatRoomId, required Object owner}) => _openChatRooms.any(
    (openChatRoom) => openChatRoom.chatRoomId == chatRoomId && !identical(openChatRoom.owner, owner),
  );
}
