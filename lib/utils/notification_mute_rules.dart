// 알림 유형 <-> 알림 설정 항목 매핑, 유형별 꺼짐 판정 (순수 함수)
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/notification_type.dart';

/// 알림 유형 > 대응 설정 항목 목록 (announcement는 content + marketing 묶음)
List<NotificationSettingType> toNotificationSettingTypes(NotificationType type) {
  switch (type) {
    case NotificationType.tradeRequestReceived:
      return [NotificationSettingType.transaction];
    case NotificationType.chatMessageReceived:
      return [NotificationSettingType.chat];
    case NotificationType.itemLiked:
      return [NotificationSettingType.activity];
    case NotificationType.announcement:
      // announcement는 content + marketing 묶음
      return [NotificationSettingType.content, NotificationSettingType.marketing];
    case NotificationType.itemDeletedByAdmin:
      // 관리자 제재 통보는 끌 수 없는 강제 알림 → 대응 설정 없음(항상 활성으로 간주)
      return const [];
  }
}

/// 설정 상태 > 알림 유형 꺼짐 여부 (대응 설정 중 하나라도 꺼짐·미설정이면 꺼짐)
bool isNotificationTypeMuted(Map<NotificationSettingType, bool> settings, NotificationType type) {
  final settingTypes = toNotificationSettingTypes(type);
  // 모두 enabled여야 unmuted. 하나라도 false면 muted.
  return !settingTypes.every((settingType) => settings[settingType] ?? false);
}
