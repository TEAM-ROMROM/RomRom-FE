import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/foreground_push_refresher.dart';

void main() {
  late int notificationListReloadCount;
  late int notificationUnreadCountRefreshCount;
  late int receivedTradeRequestsReloadCount;
  late int myItemsReloadCount;
  late bool shouldFailReceivedTradeRequestsReload;
  late ForegroundPushRefresher refresher;

  setUp(() {
    notificationListReloadCount = 0;
    notificationUnreadCountRefreshCount = 0;
    receivedTradeRequestsReloadCount = 0;
    myItemsReloadCount = 0;
    shouldFailReceivedTradeRequestsReload = false;
    refresher = ForegroundPushRefresher(
      reloadNotificationList: () async => notificationListReloadCount++,
      refreshNotificationUnreadCount: () async => notificationUnreadCountRefreshCount++,
      reloadReceivedTradeRequests: () async {
        receivedTradeRequestsReloadCount++;
        if (shouldFailReceivedTradeRequestsReload) throw Exception('received reload failed');
      },
      reloadMyItems: () async => myItemsReloadCount++,
    );
  });

  /// 갱신 횟수 (알림 목록, 받은 요청, 내 물품)
  List<int> reloadCounts() => [notificationListReloadCount, receivedTradeRequestsReloadCount, myItemsReloadCount];

  group('ForegroundPushRefresher.onForegroundPush', () {
    test('교환 요청 수신은 알림 목록과 받은 요청을 갱신한다', () async {
      await refresher.onForegroundPush({'notificationType': 'TRADE_REQUEST_RECEIVED'});

      expect(reloadCounts(), [1, 1, 0]);
    });

    test('게시글 삭제는 알림 목록과 내 물품을 갱신한다', () async {
      await refresher.onForegroundPush({'notificationType': 'ITEM_DELETED_BY_ADMIN'});

      expect(reloadCounts(), [1, 0, 1]);
    });

    test('좋아요와 공지는 알림 목록만 갱신한다', () async {
      await refresher.onForegroundPush({'notificationType': 'ITEM_LIKED'});
      expect(reloadCounts(), [1, 0, 0]);

      await refresher.onForegroundPush({'notificationType': 'ANNOUNCEMENT'});
      expect(reloadCounts(), [2, 0, 0]);
    });

    test('채팅 메시지는 미확인 개수만 다시 받고 목록·요청·물품은 갱신하지 않는다', () async {
      await refresher.onForegroundPush({'notificationType': 'CHAT_MESSAGE_RECEIVED'});

      expect(reloadCounts(), [0, 0, 0]);
      expect(notificationUnreadCountRefreshCount, 1);
    });

    test('알 수 없는 종류와 null은 알림 목록만 갱신한다', () async {
      await refresher.onForegroundPush({'notificationType': 'NEW_UNKNOWN'});
      expect(reloadCounts(), [1, 0, 0]);

      await refresher.onForegroundPush({});
      expect(reloadCounts(), [2, 0, 0]);
    });

    test('갱신 하나가 실패해도 나머지는 실행되고 예외가 밖으로 나가지 않는다', () async {
      shouldFailReceivedTradeRequestsReload = true;

      await refresher.onForegroundPush({'notificationType': 'TRADE_REQUEST_RECEIVED'});

      expect(reloadCounts(), [1, 1, 0]);
    });
  });
}
