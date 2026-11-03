import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';
import 'package:romrom_fe/models/apis/responses/notification_history_response.dart';
import 'package:romrom_fe/providers/notification_repository_provider.dart';
import 'package:romrom_fe/providers/notification_unread_count_provider.dart';
import 'package:romrom_fe/repositories/notification_repository.dart';
import 'package:romrom_fe/states/notification_list_state.dart';
import 'package:romrom_fe/utils/notification_read_rules.dart';

/// 알림 목록·미확인 개수 단일 소유 provider
/// 구독: 알림 화면(목록), 홈 탭(배지)
final notificationListProvider = AsyncNotifierProvider<NotificationListNotifier, NotificationListState>(
  NotificationListNotifier.new,
);

/// 알림 목록 1페이지 크기
const int notificationPageSize = 20;

/// 알림함 나갈 때 개별 읽음 요청 동시 실행 수 (일괄 읽음 API 없음, 서버 부하 제한)
const int notificationMarkAsReadConcurrency = 4;

/// loadMore 실패 후 재시도 대기 시간 (스크롤 알림마다 즉시 재시도 방지)
@visibleForTesting
const Duration notificationLoadMoreRetryCooldown = Duration(seconds: 3);

/// 알림 목록: 첫 페이지 로드, 다음 페이지, 읽음·삭제 후 서버 재조회
/// 재조회는 불러온 페이지 수만큼 page 0에서 한 번에 받음 > 스크롤 깊이 유지
class NotificationListNotifier extends AsyncNotifier<NotificationListState> {
  NotificationRepository get _repository => ref.read(notificationRepositoryProvider);

  // loadMore 진행 중 여부 (스크롤 이벤트 연속 발생 시 같은 페이지 중복 조회 차단)
  bool _isLoadMoreInFlight = false;

  // 마지막 loadMore 실패 시각 (재시도 대기 판정용, 성공 시 초기화)
  DateTime? _lastLoadMoreFailedAt;

  // 목록 교체 세대 (재조회마다 증가 > 이전 세대의 늦은 응답 폐기)
  int _listGeneration = 0;

  // build 세대 (세션 초기화(invalidate)마다 증가 > 이전 세션 loadMore가 새 세션 진행 표시 해제 방지)
  int _buildGeneration = 0;

  // 현재 시각 공급자 (테스트에서 교체)
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  /// 첫 페이지 로드 (invalidate 시 notifier 인스턴스 재사용 > 세션별 필드 초기화 후 조회)
  @override
  Future<NotificationListState> build() {
    _listGeneration++;
    _buildGeneration++;
    _isLoadMoreInFlight = false;
    _lastLoadMoreFailedAt = null;
    return _fetchFirstPages(pageCount: 1);
  }

  /// 서버 재조회: 첫 로드·재시도 진행 중이면 무시 > 불러온 페이지 수만큼 재조회
  /// 실패 시 이전 목록 유지 + 에러 (화면 blank 방지)
  Future<void> reload() async {
    if (state.isLoading && !state.hasValue) return;

    final generation = ++_listGeneration;
    final previous = state.valueOrNull;
    final pageCount = max(1, previous?.nextPageNumber ?? 1);
    // 데이터 없는 재시도는 로딩으로 전환 (화면 스켈레톤 표시, 중복 탭 차단)
    if (previous == null) state = const AsyncLoading<NotificationListState>();

    final next = await AsyncValue.guard(() => _fetchFirstPages(pageCount: pageCount));
    if (generation != _listGeneration) return; // 더 최근 재조회 있음

    if (next.hasError) {
      // 에러 대입 시 현재 값이 자동 보존됨 > 폐기될 loadMore의 로딩 표시만 먼저 해제
      final current = state.valueOrNull;
      if (current != null && current.isLoadingMore) state = AsyncData(current.copyWith(isLoadingMore: false));
      state = next;
      return;
    }
    _lastLoadMoreFailedAt = null;
    state = next;
  }

  /// 다음 페이지 조회: 남은 페이지·진행 중·재시도 대기 확인 > 조회 > 뒤에 추가
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;
    if (state.isLoading || _isLoadMoreInFlight || _isInLoadMoreRetryCooldown()) return;

    _isLoadMoreInFlight = true;
    final generation = _listGeneration;
    final buildGeneration = _buildGeneration;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final response = await _repository.getNotifications(
        pageNumber: current.nextPageNumber,
        pageSize: notificationPageSize,
      );
      if (generation != _listGeneration) return; // 재조회로 목록 교체됨 > 결과 폐기

      final page = response.notificationHistoryPage;
      final fetched = page?.content ?? const <NotificationHistory>[];
      final latest = state.valueOrNull ?? current;
      state = AsyncData(
        latest.copyWith(
          notifications: [...latest.notifications, ...fetched],
          nextPageNumber: current.nextPageNumber + 1,
          hasMore: _hasMorePages(page, fetchedCount: fetched.length, pageSize: notificationPageSize),
          isLoadingMore: false,
        ),
      );
      _lastLoadMoreFailedAt = null;
    } catch (error, stackTrace) {
      if (generation != _listGeneration) return;
      debugPrint('[notification list] load more failed : $error');
      _lastLoadMoreFailedAt = now();
      final latest = state.valueOrNull ?? current;
      // 로딩 표시 해제 > 에러 대입 (현재 목록 자동 보존, 화면에서 스낵바 처리)
      state = AsyncData(latest.copyWith(isLoadingMore: false));
      state = AsyncError<NotificationListState>(error, stackTrace);
    } finally {
      // (성공·실패 공통, 세션 초기화 뒤면 새 세션 표시 유지)
      if (buildGeneration == _buildGeneration) _isLoadMoreInFlight = false;
    }
  }

  /// 단건 읽음: API > 재조회 (재조회는 기다리지 않음, 딥링크 이동 지연 방지)
  Future<void> markAsRead(String notificationHistoryId) async {
    await _repository.markAsRead(notificationHistoryId);
    unawaited(reload());
  }

  /// 전체 읽음: API > 재조회 (홈 배지 0 반영)
  Future<void> markAllAsRead() async {
    await _repository.markAllAsRead();
    await reload();
  }

  /// 알림함 나갈 때 읽음: 두 탭 모두 봄 > 전체 읽음, 한 탭만 봄 > 그 탭의 읽지 않은 알림만 읽음 > 재조회
  /// (보지 않은 탭 알림은 읽지 않음 상태 유지)
  Future<void> markVisitedTabsAsRead({required bool hasVisitedActivityTab, required bool hasVisitedNewsTab}) async {
    if (hasVisitedActivityTab && hasVisitedNewsTab) return markAllAsRead();

    final unreadNotificationIds = findUnreadNotificationIdsInTabs(
      state.valueOrNull?.notifications ?? const <NotificationHistory>[],
      includeActivityTab: hasVisitedActivityTab,
      includeNewsTab: hasVisitedNewsTab,
    );
    if (unreadNotificationIds.isEmpty) return;
    // 동시 실행 수 제한 묶음 순차 처리 (건별 실패는 로그만, 나머지 계속)
    for (var start = 0; start < unreadNotificationIds.length; start += notificationMarkAsReadConcurrency) {
      final end = min(start + notificationMarkAsReadConcurrency, unreadNotificationIds.length);
      await Future.wait(unreadNotificationIds.sublist(start, end).map(_markAsReadOrLog));
    }
    // 일부 실패해도 서버 기준으로 배지 반영
    await reload();
  }

  Future<void> _markAsReadOrLog(String notificationHistoryId) async {
    try {
      await _repository.markAsRead(notificationHistoryId);
    } catch (error) {
      debugPrint('[notification list] mark as read failed : $error');
    }
  }

  /// 단건 삭제: API > 재조회 (수동 제거 금지)
  Future<void> delete(String notificationHistoryId) async {
    await _repository.delete(notificationHistoryId);
    await reload();
  }

  /// 전체 삭제: API > 재조회
  Future<void> deleteAll() async {
    await _repository.deleteAll();
    await reload();
  }

  /// 미확인 개수만 재조회 (목록 유지, 실패 시 기존 값 유지, 배지 provider와 같은 값)
  Future<void> refreshUnreadCount() async {
    final generation = _listGeneration;
    final unreadCount = await ref.read(notificationUnreadCountProvider.notifier).refresh();
    final current = state.valueOrNull;
    if (unreadCount == null || current == null || generation != _listGeneration) return;
    state = AsyncData(current.copyWith(unreadCount: unreadCount));
  }

  /// 첫 [pageCount]페이지 한 번에 조회 + 미확인 개수 (병렬)
  Future<NotificationListState> _fetchFirstPages({required int pageCount}) async {
    final pageSize = notificationPageSize * pageCount;
    final unreadCountFuture = _fetchUnreadCountOrZero();
    final response = await _repository.getNotifications(pageNumber: 0, pageSize: pageSize);
    final page = response.notificationHistoryPage;
    final fetched = page?.content ?? const <NotificationHistory>[];

    return NotificationListState(
      notifications: fetched,
      unreadCount: await unreadCountFuture,
      nextPageNumber: pageCount,
      hasMore: _hasMorePages(page, fetchedCount: fetched.length, pageSize: pageSize),
    );
  }

  /// 미확인 개수 (배지 provider 경유 > 같은 값 공유), 실패는 목록 로드를 막지 않음 (0으로 폴백)
  Future<int> _fetchUnreadCountOrZero() async =>
      await ref.read(notificationUnreadCountProvider.notifier).refresh() ?? 0;

  /// 서버 last 값 우선, 없으면 꽉 찬 페이지일 때만 더 있음으로 판단
  bool _hasMorePages(NotificationHistoryPage? page, {required int fetchedCount, required int pageSize}) {
    final isLastPage = page?.last;
    if (isLastPage != null) return !isLastPage;
    return fetchedCount >= pageSize;
  }

  bool _isInLoadMoreRetryCooldown() {
    final failedAt = _lastLoadMoreFailedAt;
    if (failedAt == null) return false;
    return now().difference(failedAt) < notificationLoadMoreRetryCooldown;
  }
}
