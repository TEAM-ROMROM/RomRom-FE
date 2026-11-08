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

    test('확장 유형: 수락·거절·완료는 교환 알림, 후기는 활동 알림, 모르는 알림은 없음 (#1007)', () {
      for (final tradeType in [
        NotificationType.tradeRequestAccepted,
        NotificationType.tradeRequestRejected,
        NotificationType.tradeCompleted,
      ]) {
        expect(toNotificationSettingTypes(tradeType), [NotificationSettingType.transaction]);
      }
      expect(toNotificationSettingTypes(NotificationType.tradeReviewReceived), [NotificationSettingType.activity]);
      expect(toNotificationSettingTypes(NotificationType.unknown), isEmpty);
    });

    test('끄기 메뉴: 대응 설정 없는 관리자 제재·모르는 알림은 숨김', () {
      expect(canToggleNotificationType(NotificationType.tradeCompleted), isTrue);
      expect(canToggleNotificationType(NotificationType.itemDeletedByAdmin), isFalse);
      expect(canToggleNotificationType(NotificationType.unknown), isFalse);
    });

    test('키워드 알림: 대응 설정 없음 > 끄기 메뉴 숨김, 항상 켜짐 (끄기 = 키워드 삭제, #1020)', () {
      expect(toNotificationSettingTypes(NotificationType.keywordItemRegistered), isEmpty);
      expect(canToggleNotificationType(NotificationType.keywordItemRegistered), isFalse);
      expect(isNotificationTypeMuted(const {}, NotificationType.keywordItemRegistered), isFalse);
    });
  });

  group('이벤트·혜택 (#1021)', () {
    test('대응 설정은 마케팅 수신 하나 > 끄기 메뉴 제공', () {
      expect(toNotificationSettingTypes(NotificationType.marketing), [NotificationSettingType.marketing]);
      expect(canToggleNotificationType(NotificationType.marketing), isTrue);
    });

    test('마케팅 수신만 보고 판정 (콘텐츠 설정과 무관)', () {
      final marketingOffSettings = {NotificationSettingType.content: true, NotificationSettingType.marketing: false};
      final marketingOnSettings = {NotificationSettingType.content: false, NotificationSettingType.marketing: true};

      expect(isNotificationTypeMuted(marketingOffSettings, NotificationType.marketing), isTrue);
      expect(isNotificationTypeMuted(marketingOnSettings, NotificationType.marketing), isFalse);
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
