/// 교환 상대 선택 결과: 채팅 상대 선택(채팅방 ID) 또는 앱 밖에서 교환
class TradeCompletePartnerSelection {
  // 교환 완료 요청을 보낼 채팅방 ID (앱 밖 교환이면 null)
  final String? chatRoomId;

  const TradeCompletePartnerSelection.chatPartner({required String this.chatRoomId});

  const TradeCompletePartnerSelection.outsideApp() : chatRoomId = null;

  /// 채팅 상대 없이 앱 밖에서 교환했는지
  bool get isCompletedOutsideApp => chatRoomId == null;
}
