import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';
import 'package:romrom_fe/models/apis/responses/notification_history_response.dart';
import 'package:romrom_fe/providers/notification_list_provider.dart';
import 'package:romrom_fe/providers/notification_repository_provider.dart';
import 'package:romrom_fe/repositories/notification_repository.dart';

NotificationHistory notification(String id) => NotificationHistory(notificationHistoryId: id);

List<NotificationHistory> notifications(int count, {String prefix = 'n'}) =>
    List.generate(count, (index) => notification('$prefix$index'));

/// 요청 기록 1건 (pageNumber, pageSize)
typedef PageRequest = ({int pageNumber, int pageSize});

/// 서버 목록을 들고 페이지 단위로 잘라 주는 fake
class FakeNotificationRepository implements NotificationRepository {
  List<NotificationHistory> serverNotifications = [];
  int serverUnreadCount = 0;
  final List<PageRequest> pageRequests = [];
  int unreadCountRequestCount = 0;
  final List<String> deletedIds = [];
  final List<String> readIds = [];
  int deleteAllCount = 0;
  int markAllAsReadCount = 0;

  // 설정 시 목록 조회가 이 완료 신호를 기다림 (동시 요청 재현)
  Completer<void>? pageGate;
  bool shouldFailPageRequest = false;
  bool shouldFailUnreadCount = false;

  @override
  Future<NotificationHistoryResponse> getNotifications({required int pageNumber, required int pageSize}) async {
    pageRequests.add((pageNumber: pageNumber, pageSize: pageSize));
    final gate = pageGate;
    if (gate != null) await gate.future;
    if (shouldFailPageRequest) throw Exception('page failed');

    final start = (pageNumber * pageSize).clamp(0, serverNotifications.length);
    final end = (start + pageSize).clamp(0, serverNotifications.length);
    return NotificationHistoryResponse(
      notificationHistoryPage: NotificationHistoryPage(
        content: serverNotifications.sublist(start, end),
        number: pageNumber,
        last: end >= serverNotifications.length,
      ),
    );
  }

  @override
  Future<int> getUnreadCount() async {
    unreadCountRequestCount++;
    if (shouldFailUnreadCount) throw Exception('count failed');
    return serverUnreadCount;
  }

  @override
  Future<void> markAsRead(String notificationHistoryId) async {
    readIds.add(notificationHistoryId);
    serverUnreadCount = serverUnreadCount > 0 ? serverUnreadCount - 1 : 0;
  }

  @override
  Future<void> markAllAsRead() async {
    markAllAsReadCount++;
    serverUnreadCount = 0;
  }

  @override
  Future<void> delete(String notificationHistoryId) async {
    deletedIds.add(notificationHistoryId);
    serverNotifications = serverNotifications.where((n) => n.notificationHistoryId != notificationHistoryId).toList();
  }

  @override
  Future<void> deleteAll() async {
    deleteAllCount++;
    serverNotifications = [];
    serverUnreadCount = 0;
  }
}

List<String?> idsOf(ProviderContainer container) =>
    container.read(notificationListProvider).valueOrNull!.notifications.map((n) => n.notificationHistoryId).toList();

void main() {
  group('notificationListProvider', () {
    late FakeNotificationRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeNotificationRepository();
      container = ProviderContainer(overrides: [notificationRepositoryProvider.overrideWithValue(fake)]);
    });
    tearDown(() => container.dispose());

    test('첫 로드는 page 0(크기 notificationPageSize) + 미확인 개수', () async {
      fake.serverNotifications = notifications(25);
      fake.serverUnreadCount = 4;

      final state = await container.read(notificationListProvider.future);

      expect(fake.pageRequests, [(pageNumber: 0, pageSize: notificationPageSize)]);
      expect(state.notifications.length, notificationPageSize);
      expect(state.unreadCount, 4);
      expect(state.nextPageNumber, 1);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
    });

    test('첫 로드 진행 중 reload는 무시 (요청 1회)', () async {
      fake.serverNotifications = notifications(3);
      final firstLoad = container.read(notificationListProvider.future);

      await container.read(notificationListProvider.notifier).reload();
      await firstLoad;

      expect(fake.pageRequests.length, 1);
    });

    test('미확인 개수 조회 실패해도 목록은 표시 (개수 0)', () async {
      fake.serverNotifications = notifications(3);
      fake.shouldFailUnreadCount = true;

      final state = await container.read(notificationListProvider.future);

      expect(state.notifications.length, 3);
      expect(state.unreadCount, 0);
      expect(state.hasMore, false);
    });

    test('loadMore는 page 1을 뒤에 붙이고 마지막 페이지면 hasMore false', () async {
      fake.serverNotifications = notifications(25);
      await container.read(notificationListProvider.future);

      await container.read(notificationListProvider.notifier).loadMore();

      final state = container.read(notificationListProvider).valueOrNull!;
      expect(fake.pageRequests.last, (pageNumber: 1, pageSize: notificationPageSize));
      expect(state.notifications.length, 25);
      expect(idsOf(container).last, 'n24');
      expect(state.nextPageNumber, 2);
      expect(state.hasMore, false);
      expect(state.isLoadingMore, false);
    });

    test('hasMore false면 loadMore 무시', () async {
      fake.serverNotifications = notifications(5);
      await container.read(notificationListProvider.future);

      await container.read(notificationListProvider.notifier).loadMore();

      expect(fake.pageRequests.length, 1);
    });

    test('동시 loadMore 2회 > 요청 1회, 진행 중 isLoadingMore true', () async {
      fake.serverNotifications = notifications(45);
      await container.read(notificationListProvider.future);
      final notifier = container.read(notificationListProvider.notifier);

      fake.pageGate = Completer<void>();
      final firstLoad = notifier.loadMore();
      final secondLoad = notifier.loadMore();
      expect(container.read(notificationListProvider).valueOrNull!.isLoadingMore, true);

      fake.pageGate!.complete();
      await Future.wait([firstLoad, secondLoad]);

      expect(fake.pageRequests.where((request) => request.pageNumber == 1).length, 1);
      expect(container.read(notificationListProvider).valueOrNull!.notifications.length, 40);
      expect(container.read(notificationListProvider).valueOrNull!.isLoadingMore, false);
    });

    test('loadMore 실패 > 기존 목록 유지 + 에러, 대기 시간 안 재시도 차단, 경과 후 허용', () async {
      fake.serverNotifications = notifications(25);
      await container.read(notificationListProvider.future);
      final notifier = container.read(notificationListProvider.notifier);
      var fakeNow = DateTime(2026, 10, 29, 12);
      notifier.now = () => fakeNow;

      fake.shouldFailPageRequest = true;
      await notifier.loadMore();
      final failed = container.read(notificationListProvider);
      expect(failed.hasError, true);
      expect(failed.valueOrNull!.notifications.length, notificationPageSize);
      expect(failed.valueOrNull!.isLoadingMore, false);

      await notifier.loadMore();
      expect(fake.pageRequests.length, 2, reason: '대기 시간 안에는 재시도하지 않음');

      fakeNow = fakeNow.add(notificationLoadMoreRetryCooldown);
      fake.shouldFailPageRequest = false;
      await notifier.loadMore();
      expect(fake.pageRequests.length, 3);
      expect(container.read(notificationListProvider).hasError, false);
      expect(container.read(notificationListProvider).valueOrNull!.notifications.length, 25);
    });

    test('delete > 서버 재조회 결과로 교체 (수동 제거 아님)', () async {
      fake.serverNotifications = notifications(3);
      await container.read(notificationListProvider.future);
      // 삭제 사이 서버에 새 알림 도착 — 재조회여야만 보임
      fake.serverNotifications = [notification('new'), ...fake.serverNotifications];

      await container.read(notificationListProvider.notifier).delete('n1');

      expect(fake.deletedIds, ['n1']);
      expect(fake.pageRequests.last.pageNumber, 0);
      expect(idsOf(container), ['new', 'n0', 'n2']);
    });

    test('재조회는 불러온 페이지 수만큼 page 0에서 한 번에 다시 받음', () async {
      fake.serverNotifications = notifications(45);
      await container.read(notificationListProvider.future);
      final notifier = container.read(notificationListProvider.notifier);
      await notifier.loadMore();

      await notifier.delete('n0');

      expect(fake.pageRequests.last, (pageNumber: 0, pageSize: notificationPageSize * 2));
      final state = container.read(notificationListProvider).valueOrNull!;
      expect(state.notifications.length, 40);
      expect(state.nextPageNumber, 2);
      expect(state.hasMore, true);

      // 이어서 page 2 > 중복·누락 없이 끝까지
      await notifier.loadMore();
      expect(fake.pageRequests.last, (pageNumber: 2, pageSize: notificationPageSize));
      expect(idsOf(container).toSet().length, 44);
      expect(container.read(notificationListProvider).valueOrNull!.hasMore, false);
    });

    test('markAllAsRead > 서버 재조회로 unreadCount 0', () async {
      fake.serverNotifications = notifications(3);
      fake.serverUnreadCount = 3;
      await container.read(notificationListProvider.future);

      await container.read(notificationListProvider.notifier).markAllAsRead();

      expect(fake.markAllAsReadCount, 1);
      expect(fake.unreadCountRequestCount, 2);
      expect(container.read(notificationListProvider).valueOrNull!.unreadCount, 0);
    });

    test('markAsRead > API 호출 후 재조회로 미확인 개수 반영', () async {
      fake.serverNotifications = notifications(3);
      fake.serverUnreadCount = 2;
      await container.read(notificationListProvider.future);

      await container.read(notificationListProvider.notifier).markAsRead('n0');
      // 재조회는 기다리지 않으므로 다음 이벤트 루프까지 진행
      await pumpEventQueue();

      expect(fake.readIds, ['n0']);
      expect(container.read(notificationListProvider).valueOrNull!.unreadCount, 1);
    });

    test('deleteAll > 재조회로 빈 목록', () async {
      fake.serverNotifications = notifications(3);
      await container.read(notificationListProvider.future);

      await container.read(notificationListProvider.notifier).deleteAll();

      expect(fake.deleteAllCount, 1);
      expect(container.read(notificationListProvider).valueOrNull!.notifications, isEmpty);
    });

    test('refreshUnreadCount는 목록은 두고 미확인 개수만 갱신', () async {
      fake.serverNotifications = notifications(3);
      fake.serverUnreadCount = 1;
      await container.read(notificationListProvider.future);
      fake.serverUnreadCount = 5;

      await container.read(notificationListProvider.notifier).refreshUnreadCount();

      expect(fake.pageRequests.length, 1);
      expect(container.read(notificationListProvider).valueOrNull!.unreadCount, 5);
    });

    test('loadMore 진행 중 reload > 늦게 온 loadMore 결과는 버림', () async {
      fake.serverNotifications = notifications(45);
      await container.read(notificationListProvider.future);
      final notifier = container.read(notificationListProvider.notifier);

      fake.pageGate = Completer<void>();
      final staleLoad = notifier.loadMore();
      fake.serverNotifications = notifications(2, prefix: 'fresh');
      final reload = notifier.reload();
      fake.pageGate!.complete();
      await Future.wait([staleLoad, reload]);

      expect(idsOf(container), ['fresh0', 'fresh1']);
      expect(container.read(notificationListProvider).valueOrNull!.isLoadingMore, false);
    });

    test('loadMore 진행 중 reload 실패 > 이전 목록 유지 + 로딩 표시 해제', () async {
      fake.serverNotifications = notifications(45);
      await container.read(notificationListProvider.future);
      final notifier = container.read(notificationListProvider.notifier);

      fake.pageGate = Completer<void>();
      final staleLoad = notifier.loadMore();
      final reload = notifier.reload();
      fake.shouldFailPageRequest = true;
      fake.pageGate!.complete();
      await Future.wait([staleLoad, reload]);

      final state = container.read(notificationListProvider);
      expect(state.hasError, true);
      expect(state.valueOrNull!.notifications.length, notificationPageSize);
      expect(state.valueOrNull!.isLoadingMore, false);
    });

    test('첫 로드 실패 후 reload > 로딩 거쳐 데이터', () async {
      fake.shouldFailPageRequest = true;
      await expectLater(container.read(notificationListProvider.future), throwsException);
      expect(container.read(notificationListProvider).hasValue, false);

      fake.shouldFailPageRequest = false;
      fake.serverNotifications = notifications(2);
      final reload = container.read(notificationListProvider.notifier).reload();
      expect(container.read(notificationListProvider).isLoading, true);
      await reload;

      expect(container.read(notificationListProvider).valueOrNull!.notifications.length, 2);
    });

    test('데이터 있는 상태에서 reload 실패 > 이전 목록 유지 + 에러', () async {
      fake.serverNotifications = notifications(2);
      await container.read(notificationListProvider.future);

      fake.shouldFailPageRequest = true;
      await container.read(notificationListProvider.notifier).reload();

      final state = container.read(notificationListProvider);
      expect(state.hasError, true);
      expect(state.valueOrNull!.notifications.length, 2);
    });

    test('세션 초기화(invalidate) 후 > 이전 loadMore 실패 대기 시간 무시하고 바로 loadMore', () async {
      fake.serverNotifications = notifications(25);
      await container.read(notificationListProvider.future);
      final notifier = container.read(notificationListProvider.notifier);
      notifier.now = () => DateTime(2026, 10, 29, 12);
      fake.shouldFailPageRequest = true;
      await notifier.loadMore();
      expect(fake.pageRequests.length, 2);

      fake.shouldFailPageRequest = false;
      container.invalidate(notificationListProvider);
      await container.read(notificationListProvider.future);
      await container.read(notificationListProvider.notifier).loadMore();

      expect(fake.pageRequests.length, 4, reason: '새 첫 페이지 + 대기 없이 다음 페이지');
    });
  });
}
