import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/models/home_feed_item.dart';

@immutable
class HomeFeedState {
  /// 현재 화면에 표시할 피드 (seen 재정렬 적용 완료된 상태)
  final List<HomeFeedItem> items;

  /// 현재까지 로드한 페이지 번호 (다음 loadMore는 +1 페이지를 요청)
  final int currentPage;

  /// 추가 페이지 로드 가능 여부
  final bool hasMoreItems;

  /// 정렬 폴백으로 결정된 현재 정렬 필드 (loadMore 시 동일 필드 유지)
  final ItemSortField currentSortField;

  /// 직전 자동 새로고침 완료 시각 (throttle 계산용). null이면 한 번도 안 함.
  final DateTime? lastRefreshAt;

  /// 피드가 통째로 교체(refresh)된 횟수. loadMore(append)에서는 증가하지 않는다.
  /// 화면은 이 값의 변화로 append/replace를 명시적으로 구분한다 (위치기반 id 역추론의 오분류 방지, #904).
  final int feedRevision;

  /// 이번 세션 추천순 섞기 시드 (첫 페이지 조회 시 새로 생성, loadMore는 같은 값 유지) (#966)
  final int? feedSeed;

  /// 이번 세션 요청에 보내는 최근 본 물품 스냅샷 (최근 본 순, 세션 시작 시 고정 > 페이지 경계 중복·누락 방지) (#966)
  final List<String> sessionRecentlySeenItemIds;

  HomeFeedState({
    List<HomeFeedItem> items = const [],
    this.currentPage = 0,
    this.hasMoreItems = true,
    this.currentSortField = ItemSortField.recommended,
    this.lastRefreshAt,
    this.feedRevision = 0,
    this.feedSeed,
    List<String> sessionRecentlySeenItemIds = const [],
  }) : items = List.unmodifiable(items),
       sessionRecentlySeenItemIds = List.unmodifiable(sessionRecentlySeenItemIds);

  HomeFeedState copyWith({
    List<HomeFeedItem>? items,
    int? currentPage,
    bool? hasMoreItems,
    ItemSortField? currentSortField,
    DateTime? lastRefreshAt,
    int? feedRevision,
    int? feedSeed,
    List<String>? sessionRecentlySeenItemIds,
  }) {
    return HomeFeedState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      currentSortField: currentSortField ?? this.currentSortField,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      feedRevision: feedRevision ?? this.feedRevision,
      feedSeed: feedSeed ?? this.feedSeed,
      sessionRecentlySeenItemIds: sessionRecentlySeenItemIds ?? this.sessionRecentlySeenItemIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeFeedState &&
          runtimeType == other.runtimeType &&
          listEquals(items, other.items) &&
          currentPage == other.currentPage &&
          hasMoreItems == other.hasMoreItems &&
          currentSortField == other.currentSortField &&
          lastRefreshAt == other.lastRefreshAt &&
          feedRevision == other.feedRevision &&
          feedSeed == other.feedSeed &&
          listEquals(sessionRecentlySeenItemIds, other.sessionRecentlySeenItemIds);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    currentPage,
    hasMoreItems,
    currentSortField,
    lastRefreshAt,
    feedRevision,
    feedSeed,
    Object.hashAll(sessionRecentlySeenItemIds),
  );

  @override
  String toString() =>
      'HomeFeedState(items=${items.length}, page=$currentPage, hasMore=$hasMoreItems, sort=$currentSortField, lastRefresh=$lastRefreshAt, rev=$feedRevision, seed=$feedSeed, sessionSeen=${sessionRecentlySeenItemIds.length})';
}
