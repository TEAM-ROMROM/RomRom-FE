import 'package:flutter/foundation.dart';

/// 우선노출(롬업) 활성화된 itemId 집합을 단일 소유하는 상태.
@immutable
class PromotionState {
  final Set<String> promotedItemIds;

  const PromotionState({this.promotedItemIds = const {}});

  bool isPromoted(String itemId) => promotedItemIds.contains(itemId);

  PromotionState copyWith({Set<String>? promotedItemIds}) =>
      PromotionState(promotedItemIds: promotedItemIds ?? this.promotedItemIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionState && runtimeType == other.runtimeType && setEquals(promotedItemIds, other.promotedItemIds);

  @override
  int get hashCode => Object.hashAll(promotedItemIds);

  @override
  String toString() => 'PromotionState(promoted: ${promotedItemIds.length})';
}
