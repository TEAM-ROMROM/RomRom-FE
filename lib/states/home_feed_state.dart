import 'dart:collection';

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

  /// 본 아이템 itemId 집합 — 삽입순 보존(LRU). 최대 [kHomeFeedSeenSetMaxSize].
  final LinkedHashSet<String> seenItemIds;

  /// 직전 자동 새로고침 완료 시각 (throttle 계산용). null이면 한 번도 안 함.
  final DateTime? lastRefreshAt;

  /// 피드가 통째로 교체(refresh)된 횟수. loadMore(append)에서는 증가하지 않는다.
  /// 화면은 이 값의 변화로 append/replace를 명시적으로 구분한다 (위치기반 id 역추론의 오분류 방지, #904).
  final int feedRevision;

  HomeFeedState({
    List<HomeFeedItem> items = const [],
    this.currentPage = 0,
    this.hasMoreItems = true,
    this.currentSortField = ItemSortField.recommended,
    LinkedHashSet<String>? seenItemIds,
    this.lastRefreshAt,
    this.feedRevision = 0,
  }) : items = List.unmodifiable(items),
       // LinkedHashSet 타입 명시가 필요 (Set 리터럴은 LinkedHashSet 타입 보장 안 함)
       // ignore: prefer_collection_literals
       seenItemIds = seenItemIds ?? LinkedHashSet<String>();

  HomeFeedState copyWith({
    List<HomeFeedItem>? items,
    int? currentPage,
    bool? hasMoreItems,
    ItemSortField? currentSortField,
    LinkedHashSet<String>? seenItemIds,
    DateTime? lastRefreshAt,
    int? feedRevision,
  }) {
    return HomeFeedState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMoreItems: hasMoreItems ?? this.hasMoreItems,
      currentSortField: currentSortField ?? this.currentSortField,
      seenItemIds: seenItemIds ?? this.seenItemIds,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      feedRevision: feedRevision ?? this.feedRevision,
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
          setEquals(seenItemIds, other.seenItemIds) &&
          lastRefreshAt == other.lastRefreshAt &&
          feedRevision == other.feedRevision;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    currentPage,
    hasMoreItems,
    currentSortField,
    Object.hashAll(seenItemIds),
    lastRefreshAt,
    feedRevision,
  );

  @override
  String toString() =>
      'HomeFeedState(items=${items.length}, page=$currentPage, hasMore=$hasMoreItems, sort=$currentSortField, seen=${seenItemIds.length}, lastRefresh=$lastRefreshAt, rev=$feedRevision)';
}
