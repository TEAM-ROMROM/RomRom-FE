import 'package:flutter/foundation.dart';

/// 우선노출(롬업) 진행 상태: 광고·활성화 처리 중인 itemId 집합
/// 노출 중 여부는 서버 물품 필드(isPromoted·promotionExpiresAt)가 단일 원본
@immutable
class PromotionState {
  final Set<String> promotingItemIds;

  const PromotionState({this.promotingItemIds = const {}});

  bool isPromoting(String itemId) => promotingItemIds.contains(itemId);

  PromotionState copyWith({Set<String>? promotingItemIds}) =>
      PromotionState(promotingItemIds: promotingItemIds ?? this.promotingItemIds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PromotionState &&
          runtimeType == other.runtimeType &&
          setEquals(promotingItemIds, other.promotingItemIds);

  @override
  int get hashCode => Object.hashAllUnordered(promotingItemIds);

  @override
  String toString() => 'PromotionState(promoting: ${promotingItemIds.length})';
}
