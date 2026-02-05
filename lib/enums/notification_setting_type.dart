/// 알림 설정 타입
enum NotificationSettingType {
  marketing,
  activity,
  chat,
  content,
  transaction,
}

/// 알림 설정 타입 확장
extension NotificationSettingTypeExtension on NotificationSettingType {
  /// 설정 제목
  String get title {
    switch (this) {
      case NotificationSettingType.marketing:
        return '마케팅 수신 동의';
      case NotificationSettingType.activity:
        return '활동 알림';
      case NotificationSettingType.chat:
        return '채팅 알림';
      case NotificationSettingType.content:
        return '콘텐츠 알림';
      case NotificationSettingType.transaction:
        return '거래 알림';
    }
  }

  /// 설정 설명
  String get description {
    switch (this) {
      case NotificationSettingType.marketing:
        return '이벤트, 혜택 등 광고성 정보 수신';
      case NotificationSettingType.activity:
        return '작성한 글에 대한 좋아요 알림';
      case NotificationSettingType.chat:
        return '메시지 도착 시 실시간 알림';
      case NotificationSettingType.content:
        return '인기글, 정보성글 등의 콘텐츠 알림';
      case NotificationSettingType.transaction:
        return '교환 요청 등의 알림';
    }
  }
}
