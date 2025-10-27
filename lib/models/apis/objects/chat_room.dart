/// 채팅방 모델 클래스
class ChatRoom {
  final String chatRoomId;
  final String otherUserNickname;
  final String? otherUserProfileUrl;
  final String otherUserLocation;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isNew;

  // TODO: API 연동 시 추가 필드
  // final bool isSentRequest;
  // final bool isReceivedRequest;

  ChatRoom({
    required this.chatRoomId,
    required this.otherUserNickname,
    this.otherUserProfileUrl,
    required this.otherUserLocation,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isNew = false,
  });
}

