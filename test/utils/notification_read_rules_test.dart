import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';
import 'package:romrom_fe/utils/notification_read_rules.dart';

NotificationHistory notificationOf(NotificationType type) =>
    NotificationHistory(notificationHistoryId: type.name, notificationType: type.serverName);

void main() {
  group('isRomromNewsNotification', () {
    test('공지·이벤트·혜택은 롬롬 소식 탭 (#1021)', () {
      expect(isRomromNewsNotification(notificationOf(NotificationType.announcement)), isTrue);
      expect(isRomromNewsNotification(notificationOf(NotificationType.marketing)), isTrue);
    });

    test('그 외 알림·종류 없음은 활동 및 채팅 탭', () {
      expect(isRomromNewsNotification(notificationOf(NotificationType.keywordItemRegistered)), isFalse);
      expect(isRomromNewsNotification(notificationOf(NotificationType.chatMessageReceived)), isFalse);
      expect(isRomromNewsNotification(NotificationHistory(notificationHistoryId: 'none')), isFalse);
    });
  });
}
