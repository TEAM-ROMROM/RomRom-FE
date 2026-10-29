/// 알림 타입
enum NotificationType {
  tradeRequestReceived(label: '교환 요청', serverName: 'TRADE_REQUEST_RECEIVED'),
  chatMessageReceived(label: '채팅', serverName: 'CHAT_MESSAGE_RECEIVED'),
  itemLiked(label: '좋아요', serverName: 'ITEM_LIKED'),
  systemNotice(label: '공지사항', serverName: 'SYSTEM_NOTICE'),
  itemDeletedByAdmin(label: '게시글 삭제', serverName: 'ITEM_DELETED_BY_ADMIN');

  final String label;
  final String serverName;

  const NotificationType({required this.label, required this.serverName});

  /// 알림 카테고리별 SVG 아이콘 경로
  String get svgAssetPath {
    switch (this) {
      case NotificationType.tradeRequestReceived:
        return 'assets/images/notificationExchangeYellowCircle.svg';
      case NotificationType.chatMessageReceived:
        return 'assets/images/notificationChat.svg';
      case NotificationType.itemLiked:
        return 'assets/images/notificationLike.svg';
      case NotificationType.systemNotice:
        return 'assets/images/notificationAnnouncement.svg';
      case NotificationType.itemDeletedByAdmin:
        return 'assets/images/notificationAnnouncement.svg';
    }
  }

  /// 서버 이름 > 알림 타입 (모르는 값·null > null)
  static NotificationType? fromServerName(String? name) {
    return NotificationType.values.where((e) => e.serverName == name).firstOrNull;
  }
}
