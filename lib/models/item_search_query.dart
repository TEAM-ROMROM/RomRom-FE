import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_search_sort_field.dart';

/// 물품 검색 조건: 정리된 검색어, 카테고리 필터(비면 전체), 정렬 (#1008)
@immutable
class ItemSearchQuery {
  final String keyword;
  final List<ItemCategories> categories;
  final ItemSearchSortField sortField;

  const ItemSearchQuery({
    required this.keyword,
    this.categories = const [],
    this.sortField = ItemSearchSortField.latest,
  });

  ItemSearchQuery copyWith({String? keyword, List<ItemCategories>? categories, ItemSearchSortField? sortField}) {
    return ItemSearchQuery(
      keyword: keyword ?? this.keyword,
      categories: categories ?? this.categories,
      sortField: sortField ?? this.sortField,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemSearchQuery &&
          keyword == other.keyword &&
          listEquals(categories, other.categories) &&
          sortField == other.sortField;

  @override
  int get hashCode => Object.hash(keyword, Object.hashAll(categories), sortField);

  @override
  String toString() => 'ItemSearchQuery(keyword: $keyword, categories: ${categories.length}, sortField: $sortField)';
}
