import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/services/push_notification_routing.dart';

/// 푸시 탭 공통 경로 (#984): Android 포그라운드 로컬 알림 payload <-> FCM data, data > 딥링크
void main() {
  final chatPushData = <String, dynamic>{
    'deepLink': 'romrom://chat/room?chatRoomId=room-1',
    'notificationType': NotificationType.chatMessageReceived.serverName,
  };

  test('로컬 알림 payload 왕복 > 같은 FCM data', () {
    final payload = encodePushNotificationPayload(chatPushData);

    expect(decodePushNotificationPayload(payload), chatPushData);
  });

  test('payload 없음·JSON 아님·객체 아님 > null (탭 무시)', () {
    expect(decodePushNotificationPayload(null), isNull);
    expect(decodePushNotificationPayload(''), isNull);
    expect(decodePushNotificationPayload('not json'), isNull);
    expect(decodePushNotificationPayload('[1, 2]'), isNull);
  });

  test('FCM data > 딥링크 주소·알림 타입·부가 값', () {
    final pendingDeepLink = buildPendingDeepLinkFromPushData(chatPushData)!;

    expect(pendingDeepLink.uri.queryParameters['chatRoomId'], 'room-1');
    expect(pendingDeepLink.notificationType, NotificationType.chatMessageReceived);
    expect(pendingDeepLink.extraData, chatPushData);
  });

  test('deepLink 없음 > null, 모르는 알림 타입 > 타입 없이 딥링크 유지', () {
    expect(buildPendingDeepLinkFromPushData(const {'notificationType': 'X'}), isNull);
    expect(buildPendingDeepLinkFromPushData(const {'deepLink': ''}), isNull);

    final pendingDeepLink = buildPendingDeepLinkFromPushData(const {
      'deepLink': 'romrom://chat/room?chatRoomId=room-1',
      'notificationType': 'UNKNOWN_TYPE',
    });
    expect(pendingDeepLink?.notificationType, isNull);
    expect(pendingDeepLink?.uri.host, 'chat');
  });
}
