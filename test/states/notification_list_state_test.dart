import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';
import 'package:romrom_fe/states/notification_list_state.dart';

void main() {
  group('NotificationListState', () {
    final first = NotificationHistory(notificationHistoryId: 'n1');
    final second = NotificationHistory(notificationHistoryId: 'n2');

    test('기본값: 빈 목록, 미확인 0, 다음 페이지 0, 더 있음, 추가 로딩 아님', () {
      final state = NotificationListState();
      expect(state.notifications, isEmpty);
      expect(state.unreadCount, 0);
      expect(state.nextPageNumber, 0);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
    });

    test('copyWith는 지정한 필드만 바꾼다', () {
      final state = NotificationListState(notifications: [first], unreadCount: 3, nextPageNumber: 1);
      final next = state.copyWith(unreadCount: 0, isLoadingMore: true);
      expect(next.notifications, [first]);
      expect(next.unreadCount, 0);
      expect(next.nextPageNumber, 1);
      expect(next.hasMore, true);
      expect(next.isLoadingMore, true);
    });

    test('같은 값이면 == 와 hashCode가 같다', () {
      final a = NotificationListState(notifications: [first, second], unreadCount: 2, nextPageNumber: 1);
      final b = NotificationListState(notifications: [first, second], unreadCount: 2, nextPageNumber: 1);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('목록 순서·필드가 다르면 다르다', () {
      final a = NotificationListState(notifications: [first, second]);
      expect(a == NotificationListState(notifications: [second, first]), false);
      expect(a == a.copyWith(hasMore: false), false);
      expect(a == a.copyWith(isLoadingMore: true), false);
    });

    test('notifications는 외부에서 변경할 수 없다', () {
      final state = NotificationListState(notifications: [first]);
      expect(() => state.notifications.add(second), throwsUnsupportedError);
    });
  });
}
