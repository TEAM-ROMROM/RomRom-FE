import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/providers/home_feed_repository_provider.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/repositories/home_feed_repository.dart';
import 'package:romrom_fe/states/home_feed_state.dart';

/// 홈 피드 단일 소유 provider.
/// MainScreen이 IndexedStack이라 탭 전환 시 HomeTabScreen.initState가 재실행되지 않으므로
/// 로컬 상태로 들면 stale해진다 — provider 구독으로 갱신 보장.
final homeFeedProvider = AsyncNotifierProvider<HomeFeedNotifier, HomeFeedState>(HomeFeedNotifier.new);

/// 자동 새로고침 throttle 간격 — spec §2.1.
@visibleForTesting
const Duration kHomeFeedRefreshThrottle = Duration(seconds: 30);

/// seen-set LRU 최대 크기 — spec §2.1.
@visibleForTesting
const int kHomeFeedSeenSetMaxSize = 100;

/// loadMore 실패 후 재시도 대기 시간 (스크롤 알림마다 즉시 재시도 방지)
@visibleForTesting
const Duration loadMoreRetryCooldown = Duration(seconds: 3);

/// 한 페이지 조회 크기.
const int _kPageSize = 10;

/// 추천순 섞기 시드 상한 (0 ~ 2^31-1, 서버 Long 범위 안)
const int _kFeedSeedUpperBound = 1 << 31;

/// 정렬 폴백 순서 — spec §3.1.
const List<ItemSortField> _kFallbackOrder = [
  ItemSortField.recommended,
  ItemSortField.distance,
  ItemSortField.preferredCategory,
  ItemSortField.createdDate,
];

class HomeFeedNotifier extends AsyncNotifier<HomeFeedState> {
  HomeFeedRepository get _repo => ref.read(homeFeedRepositoryProvider);

  // loadMore 진행 중 여부 (스크롤 이벤트 연속 발생 시 같은 페이지 중복 조회 차단)
  bool _isLoadMoreInFlight = false;

  // 마지막 loadMore 실패 시각 (재시도 대기 판정용, 성공 시 초기화)
  DateTime? _lastLoadMoreFailedAt;

  // build 세대 (세션 초기화(invalidate)마다 증가 > 이전 세션의 늦은 loadMore·refresh 결과 폐기)
  int _buildGeneration = 0;

  // 현재 시각 공급자 (테스트에서 교체)
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  // 세션 시드 생성기 (테스트에서 교체)
  static final Random _feedSeedRandom = Random();
  @visibleForTesting
  int Function() generateFeedSeed = () => _feedSeedRandom.nextInt(_kFeedSeedUpperBound);

  /// 첫 페이지 로드 (invalidate 시 notifier 인스턴스 재사용 > 세션별 필드 초기화 > 저장된 최근 본 물품 복원 후 조회)
  @override
  Future<HomeFeedState> build() async {
    _buildGeneration++;
    _isLoadMoreInFlight = false;
    _lastLoadMoreFailedAt = null;
    return _fetchInitial(seenItemIds: await _loadPersistedSeenItemIds());
  }

  /// 정렬 폴백을 돌아 첫 비어있지 않은 결과를 반환 (새 세션: 새 시드 + 최근 본 물품 스냅샷 고정).
  /// 시간 함수(DateTime.now())는 호출하지 않는다 — lastRefreshAt는 호출자가 결정.
  Future<HomeFeedState> _fetchInitial({required LinkedHashSet<String> seenItemIds}) async {
    List<Item> items = const [];
    ItemSortField pickedSort = ItemSortField.recommended;
    final feedSeed = generateFeedSeed();
    final sessionRecentlySeenItemIds = _buildSessionRecentlySeenItemIds(seenItemIds);

    for (final sortField in _kFallbackOrder) {
      items = await _repo.fetchPage(
        pageNumber: 0,
        pageSize: _kPageSize,
        sortField: sortField,
        recentlySeenItemIds: sessionRecentlySeenItemIds,
        feedSeed: feedSeed,
      );
      debugPrint('[HomeFeed] sortField=${sortField.serverName} → ${items.length}개');
      if (items.isNotEmpty) {
        pickedSort = sortField;
        break;
      }
    }

    final feedItems = await _toFeedItems(items, startIndex: 0);
    final reordered = _reorderBySeen(feedItems, seenItemIds);

    return HomeFeedState(
      items: reordered,
      currentPage: 0,
      hasMoreItems: items.isNotEmpty,
      currentSortField: pickedSort,
      seenItemIds: seenItemIds,
      lastRefreshAt: null,
      feedSeed: feedSeed,
      sessionRecentlySeenItemIds: sessionRecentlySeenItemIds,
    );
  }

  /// 다음 페이지 로드 (세션 시드·스냅샷 유지). 빈 페이지면 새 세션으로 page 0 되감기 (seen 기록 유지 > 서버가 본 물품 뒤로).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMoreItems) return;
    if (state.isLoading || _isLoadMoreInFlight) return;
    if (_isInLoadMoreRetryCooldown()) return;

    _isLoadMoreInFlight = true;
    final buildGeneration = _buildGeneration;
    try {
      var nextPage = current.currentPage + 1;
      var feedSeed = current.feedSeed;
      var sessionRecentlySeenItemIds = current.sessionRecentlySeenItemIds;
      var fetched = await _repo.fetchPage(
        pageNumber: nextPage,
        pageSize: _kPageSize,
        sortField: current.currentSortField,
        recentlySeenItemIds: sessionRecentlySeenItemIds,
        feedSeed: feedSeed,
      );

      // 풀 소진 > 새 세션(새 시드 + 지금까지 본 물품 스냅샷)으로 page 0 되감기 > 안 본 물품 먼저, 본 물품은 새 순서로
      if (fetched.isEmpty) {
        nextPage = 0;
        feedSeed = generateFeedSeed();
        sessionRecentlySeenItemIds = _buildSessionRecentlySeenItemIds(current.seenItemIds);
        fetched = await _repo.fetchPage(
          pageNumber: nextPage,
          pageSize: _kPageSize,
          sortField: current.currentSortField,
          recentlySeenItemIds: sessionRecentlySeenItemIds,
          feedSeed: feedSeed,
        );
      }

      final converted = await _toFeedItems(fetched, startIndex: current.items.length);
      if (buildGeneration != _buildGeneration) return; // 세션 초기화됨 > 결과 폐기
      // 되감기 중 markSeen 반영분 포함 (최신 seen 기준 재정렬)
      final latestSeenItemIds = state.valueOrNull?.seenItemIds ?? current.seenItemIds;
      final reordered = _reorderBySeen(converted, latestSeenItemIds);

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...reordered],
          currentPage: nextPage,
          hasMoreItems: fetched.isNotEmpty,
          seenItemIds: latestSeenItemIds,
          feedSeed: feedSeed,
          sessionRecentlySeenItemIds: sessionRecentlySeenItemIds,
        ),
      );
      _lastLoadMoreFailedAt = null;
    } catch (e, st) {
      if (buildGeneration != _buildGeneration) return;
      _lastLoadMoreFailedAt = now();
      // loadMore 실패는 사용자 가시 액션 — 에러로 surface하여 화면에서 SnackBar 처리.
      state = AsyncError<HomeFeedState>(e, st).copyWithPrevious(state);
    } finally {
      // (성공·실패 공통, 세션 초기화 뒤면 새 세션 표시 유지)
      if (buildGeneration == _buildGeneration) _isLoadMoreInFlight = false;
    }
  }

  /// 자동 새로고침. throttle 통과 시 page 0 다시 조회.
  /// 실패는 silent — 기존 items 유지.
  Future<void> refresh({required RefreshTrigger trigger}) async {
    final current = state.valueOrNull;
    if (current == null) return; // 아직 최초 로드도 안 된 상태 — 무시
    if (state.isLoading) return; // 중복 진행 방지

    if (_shouldThrottle(current.lastRefreshAt)) {
      debugPrint('[HomeFeed] refresh throttled (trigger=$trigger)');
      return;
    }

    debugPrint('[HomeFeed] refresh start (trigger=$trigger)');
    final buildGeneration = _buildGeneration;
    try {
      // 새로고침 중 loading 표시를 위해 loading 상태로 전환 (이전 데이터는 보존)
      state = const AsyncLoading<HomeFeedState>().copyWithPrevious(state);

      final next = await _fetchInitial(seenItemIds: current.seenItemIds);
      if (buildGeneration != _buildGeneration) return; // 세션 초기화됨 > 결과 폐기
      // feedRevision 증가 = 화면에 "통째 교체(replace)"임을 명시적으로 통지 (page 0 점프 + 광고 슬롯 리셋 트리거)
      state = AsyncData(next.copyWith(lastRefreshAt: DateTime.now(), feedRevision: current.feedRevision + 1));
    } catch (e) {
      // silent fail — 기존 데이터 유지
      debugPrint('[HomeFeed] refresh failed silently: $e');
      if (buildGeneration != _buildGeneration) return;
      state = AsyncData(current);
    }
  }

  /// 첫 로드 실패 후 재시도: 로딩 전환 > 첫 페이지 조회 > 성공 시 데이터, 실패 시 에러
  /// 데이터가 이미 있거나 진행 중이면 무시 (refresh는 데이터 없으면 무시하므로 별도 경로)
  Future<void> retryInitialLoad() async {
    if (state.hasValue || state.isLoading) return;

    state = const AsyncLoading<HomeFeedState>();
    state = await AsyncValue.guard(() async => _fetchInitial(seenItemIds: await _loadPersistedSeenItemIds()));
  }

  /// 사용자가 본 아이템을 seen-set에 추가 (LRU 갱신 > 기기 저장, 저장 실패는 무시).
  void markSeen(String itemId) {
    final current = state.valueOrNull;
    if (current == null) return;

    final next = LinkedHashSet<String>.from(current.seenItemIds);
    // 이미 있으면 MRU 갱신을 위해 제거 후 다시 추가
    next.remove(itemId);
    next.add(itemId);
    while (next.length > kHomeFeedSeenSetMaxSize) {
      next.remove(next.first); // LRU 제거
    }

    state = AsyncData(current.copyWith(seenItemIds: next));
    unawaited(_repo.saveRecentlySeenItemIds(next.toList()));
  }

  /// 저장된 최근 본 물품 > seen-set (오래된 순 유지, 최대 [kHomeFeedSeenSetMaxSize]개, 최근 것 우선)
  Future<LinkedHashSet<String>> _loadPersistedSeenItemIds() async {
    final persistedSeenItemIds = await _repo.loadRecentlySeenItemIds();
    final overflowCount = max(0, persistedSeenItemIds.length - kHomeFeedSeenSetMaxSize);
    return LinkedHashSet<String>.from(persistedSeenItemIds.skip(overflowCount));
  }

  /// seen-set(오래된 순) > 세션 요청 스냅샷 (최근 본 순)
  List<String> _buildSessionRecentlySeenItemIds(LinkedHashSet<String> seenItemIds) =>
      List.unmodifiable(seenItemIds.toList().reversed);

  /// 물품 > 피드 항목 변환 (표시 주소 병렬 조회 > 순수 변환)
  Future<List<HomeFeedItem>> _toFeedItems(List<Item> items, {required int startIndex}) async {
    final locationTexts = await ref.read(itemAddressResolverProvider).resolveLocationTexts(items);
    return HomeFeedItem.fromItems(items, startIndex: startIndex, locationTexts: locationTexts);
  }

  bool _isInLoadMoreRetryCooldown() {
    final failedAt = _lastLoadMoreFailedAt;
    if (failedAt == null) return false;
    return now().difference(failedAt) < loadMoreRetryCooldown;
  }

  bool _shouldThrottle(DateTime? last) {
    if (last == null) return false;
    return DateTime.now().difference(last) < kHomeFeedRefreshThrottle;
  }

  /// seen 아이템을 응답 끝으로 재정렬 (필터링하지 않음).
  List<HomeFeedItem> _reorderBySeen(List<HomeFeedItem> fresh, Set<String> seenIds) {
    final unseen = <HomeFeedItem>[];
    final seen = <HomeFeedItem>[];
    for (final item in fresh) {
      final uuid = item.itemUuid;
      if (uuid != null && seenIds.contains(uuid)) {
        seen.add(item);
      } else {
        unseen.add(item);
      }
    }
    return [...unseen, ...seen];
  }
}
