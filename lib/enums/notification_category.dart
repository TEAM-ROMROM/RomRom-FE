/// 알림 카테고리 enum
enum NotificationCategory {
  exchangeRequest, // 교환 요청
  like, // 좋아요
  chat, // 채팅
  announcement, // 공지사항
}

/// 알림 카테고리 확장
extension NotificationCategoryExtension on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.exchangeRequest:
        return '교환 요청';
      case NotificationCategory.like:
        return '좋아요';
      case NotificationCategory.chat:
        return '채팅';
      case NotificationCategory.announcement:
        return '공지사항';
    }
  }

  /// 알림 카테고리별 SVG 아이콘 경로
  String get svgAssetPath {
    switch (this) {
      case NotificationCategory.exchangeRequest:
        return 'assets/images/notificationExchangeYellowCircle.svg';
      case NotificationCategory.like:
        return 'assets/images/notificationLike.svg';
      case NotificationCategory.chat:
        return 'assets/images/notificationChat.svg';
      case NotificationCategory.announcement:
        return 'assets/images/notificationAnnouncement.svg';
    }
  }
}
