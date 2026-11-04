import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/item_search_query.dart';

/// 물품 검색 결과 상태: 마지막 검색 조건(검색 전 null), 결과 목록, 다음 페이지 번호·여부, 다음 페이지 로딩·실패 (#1008)
@immutable
class ItemSearchState {
  // null > 아직 검색 전 (최근 검색어 표시)
  final ItemSearchQuery? searchQuery;
  final List<Item> items;
  final int nextPageNumber;
  final bool hasMore;
  final bool isLoadingMore;
  // 다음 페이지 실패 (목록 유지, 하단 다시 시도)
  final bool hasNextPageError;

  const ItemSearchState({
    this.searchQuery,
    this.items = const [],
    this.nextPageNumber = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.hasNextPageError = false,
  });

  bool get hasSearched => searchQuery != null;

  ItemSearchState copyWith({
    List<Item>? items,
    int? nextPageNumber,
    bool? hasMore,
    bool? isLoadingMore,
    bool? hasNextPageError,
  }) {
    return ItemSearchState(
      searchQuery: searchQuery,
      items: items ?? this.items,
      nextPageNumber: nextPageNumber ?? this.nextPageNumber,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasNextPageError: hasNextPageError ?? this.hasNextPageError,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSearchState &&
          searchQuery == other.searchQuery &&
          listEquals(items, other.items) &&
          nextPageNumber == other.nextPageNumber &&
          hasMore == other.hasMore &&
          isLoadingMore == other.isLoadingMore &&
          hasNextPageError == other.hasNextPageError;

  @override
  int get hashCode =>
      Object.hash(searchQuery, Object.hashAll(items), nextPageNumber, hasMore, isLoadingMore, hasNextPageError);

  @override
  String toString() =>
      'ItemSearchState(searchQuery: $searchQuery, items: ${items.length}, nextPageNumber: $nextPageNumber, '
      'hasMore: $hasMore, isLoadingMore: $isLoadingMore, hasNextPageError: $hasNextPageError)';
}
