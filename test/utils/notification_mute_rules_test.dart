import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/utils/notification_mute_rules.dart';

void main() {
  group('toNotificationSettingTypes', () {
    test('유형별 설정 항목: 롬롬 소식은 content + marketing, 관리자 제재는 없음', () {
      expect(toNotificationSettingTypes(NotificationType.tradeRequestReceived), [NotificationSettingType.transaction]);
      expect(toNotificationSettingTypes(NotificationType.chatMessageReceived), [NotificationSettingType.chat]);
      expect(toNotificationSettingTypes(NotificationType.itemLiked), [NotificationSettingType.activity]);
      expect(toNotificationSettingTypes(NotificationType.announcement), [
        NotificationSettingType.content,
        NotificationSettingType.marketing,
      ]);
      expect(toNotificationSettingTypes(NotificationType.itemDeletedByAdmin), isEmpty);
    });
  });

  group('isNotificationTypeMuted', () {
    test('롬롬 소식: 둘 중 하나라도 꺼지면 꺼짐, 둘 다 켜져야 켜짐', () {
      final partlyEnabledSettings = {NotificationSettingType.content: true, NotificationSettingType.marketing: false};
      final fullyEnabledSettings = {NotificationSettingType.content: true, NotificationSettingType.marketing: true};

      expect(isNotificationTypeMuted(partlyEnabledSettings, NotificationType.announcement), true);
      expect(isNotificationTypeMuted(fullyEnabledSettings, NotificationType.announcement), false);
    });

    test('설정 미로드(키 없음)는 꺼짐, 관리자 제재는 항상 켜짐', () {
      expect(isNotificationTypeMuted(const {}, NotificationType.chatMessageReceived), true);
      expect(isNotificationTypeMuted(const {}, NotificationType.itemDeletedByAdmin), false);
    });
  });
}
