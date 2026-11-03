import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/notification_list_provider.dart';
import 'package:romrom_fe/providers/notification_repository_provider.dart';
import 'package:romrom_fe/providers/notification_unread_count_provider.dart';

import 'notification_list_provider_test.dart' show FakeNotificationRepository, notifications;

ProviderContainer _makeContainer(FakeNotificationRepository repository) {
  final container = ProviderContainer(overrides: [notificationRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  return container;
}

/// 홈 알림 배지: 미확인 수만 조회 (알림 목록 조회 없음), 목록 provider와 같은 값 공유
void main() {
  test('첫 조회: 미확인 수 API만 호출, 알림 목록은 받지 않음', () async {
    final repository = FakeNotificationRepository()..serverUnreadCount = 3;
    final container = _makeContainer(repository);

    expect(await container.read(notificationUnreadCountProvider.future), 3);
    expect(repository.unreadCountRequestCount, 1);
    expect(repository.pageRequests, isEmpty);
  });

  test('refresh: 첫 조회 진행 중이면 같은 결과 기다림 (중복 요청 없음)', () async {
    final repository = FakeNotificationRepository()..serverUnreadCount = 2;
    final container = _makeContainer(repository);
    container.read(notificationUnreadCountProvider);

    expect(await container.read(notificationUnreadCountProvider.notifier).refresh(), 2);
    expect(repository.unreadCountRequestCount, 1);
  });

  test('refresh 실패: 기존 값 유지, null 반환', () async {
    final repository = FakeNotificationRepository()..serverUnreadCount = 4;
    final container = _makeContainer(repository);
    await container.read(notificationUnreadCountProvider.future);

    repository.shouldFailUnreadCount = true;
    final refreshedCount = await container.read(notificationUnreadCountProvider.notifier).refresh();

    expect(refreshedCount, isNull);
    expect(container.read(notificationUnreadCountProvider).valueOrNull, 4);
  });

  test('알림 목록 전체 읽음 > 배지 provider도 0 (같은 미확인 수 공유)', () async {
    final repository = FakeNotificationRepository()
      ..serverNotifications = notifications(3)
      ..serverUnreadCount = 3;
    final container = _makeContainer(repository);
    expect(await container.read(notificationUnreadCountProvider.future), 3);
    await container.read(notificationListProvider.future);

    await container.read(notificationListProvider.notifier).markAllAsRead();

    expect(container.read(notificationUnreadCountProvider).valueOrNull, 0);
    expect(container.read(notificationListProvider).valueOrNull!.unreadCount, 0);
  });
}
