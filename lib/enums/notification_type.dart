/// 알림 타입
enum NotificationType { tradeRequestReceived, chatMessageReceived, itemLiked, systemNotice }

/// 알림 타입 확장
extension NotificationTypeExtension on NotificationType {
  /// 알림 제목
  String get title {
    switch (this) {
      case NotificationType.tradeRequestReceived:
        return '거래 요청 수신';
      case NotificationType.chatMessageReceived:
        return '채팅 메시지 수신';
      case NotificationType.itemLiked:
        return '좋아요 수신';
      case NotificationType.systemNotice:
        return '시스템 공지';
    }
  }
}
