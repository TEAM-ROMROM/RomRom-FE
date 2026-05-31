import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/home_feed_item.dart';
import 'package:romrom_fe/providers/home_feed_repository_provider.dart';
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

/// 한 페이지 조회 크기.
const int _kPageSize = 10;

/// 정렬 폴백 순서 — spec §3.1.
const List<ItemSortField> _kFallbackOrder = [
  ItemSortField.recommended,
  ItemSortField.distance,
  ItemSortField.preferredCategory,
  ItemSortField.createdDate,
];

class HomeFeedNotifier extends AsyncNotifier<HomeFeedState> {
  HomeFeedRepository get _repo => ref.read(homeFeedRepositoryProvider);

  @override
  Future<HomeFeedState> build() => _fetchInitial(seenItemIds: LinkedHashSet<String>());

  /// 정렬 폴백을 돌아 첫 비어있지 않은 결과를 반환.
  /// 시간 함수(DateTime.now())는 호출하지 않는다 — lastRefreshAt는 호출자가 결정.
  Future<HomeFeedState> _fetchInitial({required LinkedHashSet<String> seenItemIds}) async {
    List<Item> items = const [];
    ItemSortField pickedSort = ItemSortField.recommended;

    for (final sortField in _kFallbackOrder) {
      items = await _repo.fetchPage(pageNumber: 0, pageSize: _kPageSize, sortField: sortField);
      debugPrint('[HomeFeed] sortField=${sortField.serverName} → ${items.length}개');
      if (items.isNotEmpty) {
        pickedSort = sortField;
        break;
      }
    }

    final feedItems = await HomeFeedItem.fromItems(items, startIndex: 0);
    final reordered = _reorderBySeen(feedItems, seenItemIds);

    return HomeFeedState(
      items: reordered,
      currentPage: 0,
      hasMoreItems: items.isNotEmpty,
      currentSortField: pickedSort,
      seenItemIds: seenItemIds,
      lastRefreshAt: null,
    );
  }

  /// 다음 페이지 로드. 빈 페이지면 page 0으로 되감기 + seen-set 클리어 ("또돌이표").
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMoreItems) return;
    if (state.isLoading) return;

    try {
      var nextPage = current.currentPage + 1;
      var fetched = await _repo.fetchPage(
        pageNumber: nextPage,
        pageSize: _kPageSize,
        sortField: current.currentSortField,
      );

      var seen = current.seenItemIds;

      // 풀 소진 → page 0 되감기 + seen-set 클리어 (자연스럽게 새 순서로 다시 보임)
      if (fetched.isEmpty) {
        nextPage = 0;
        seen = LinkedHashSet<String>();
        fetched = await _repo.fetchPage(
          pageNumber: nextPage,
          pageSize: _kPageSize,
          sortField: current.currentSortField,
        );
      }

      final converted = await HomeFeedItem.fromItems(fetched, startIndex: current.items.length);
      final reordered = _reorderBySeen(converted, seen);

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...reordered],
          currentPage: nextPage,
          hasMoreItems: fetched.isNotEmpty,
          seenItemIds: seen,
        ),
      );
    } catch (e, st) {
      // loadMore 실패는 사용자 가시 액션 — 에러로 surface하여 화면에서 SnackBar 처리.
      state = AsyncError<HomeFeedState>(e, st).copyWithPrevious(state);
    }
  }

  /// 자동 새로고침. throttle 통과 시 page 0 다시 조회.
  /// 실패는 silent — 기존 items 유지.
  Future<void> refresh({required RefreshTrigger trigger}) async {
    final current = state.value;
    if (current == null) return; // 아직 최초 로드도 안 된 상태 — 무시
    if (state.isLoading) return; // 중복 진행 방지

    if (_shouldThrottle(current.lastRefreshAt)) {
      debugPrint('[HomeFeed] refresh throttled (trigger=$trigger)');
      return;
    }

    debugPrint('[HomeFeed] refresh start (trigger=$trigger)');
    try {
      // 새로고침 중 loading 표시를 위해 loading 상태로 전환 (이전 데이터는 보존)
      state = const AsyncLoading<HomeFeedState>().copyWithPrevious(state);

      final next = await _fetchInitial(seenItemIds: current.seenItemIds);
      state = AsyncData(next.copyWith(lastRefreshAt: DateTime.now()));
    } catch (e) {
      // silent fail — 기존 데이터 유지
      debugPrint('[HomeFeed] refresh failed silently: $e');
      state = AsyncData(current);
    }
  }

  /// 사용자가 본 아이템을 seen-set에 추가 (LRU 갱신).
  void markSeen(String itemId) {
    final current = state.value;
    if (current == null) return;

    final next = LinkedHashSet<String>.from(current.seenItemIds);
    // 이미 있으면 MRU 갱신을 위해 제거 후 다시 추가
    next.remove(itemId);
    next.add(itemId);
    while (next.length > kHomeFeedSeenSetMaxSize) {
      next.remove(next.first); // LRU 제거
    }

    state = AsyncData(current.copyWith(seenItemIds: next));
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
