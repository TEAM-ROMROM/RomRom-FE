import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';

/// 물품 등록·수정 폼 값 스냅샷: 진입 시점 값 <-> 현재 값 비교로 미저장 변경 판정
/// 비교 대상 8종: 사진, 이름, 설명, 카테고리, 상태, 거래 방식, 가격(AI 여부 포함), 위치
@immutable
class RegisterFormSnapshot {
  final List<String> existingImageUrls;
  final List<String> newImagePaths;
  final String itemName;
  final String itemDescription;
  final ItemCategories? category;
  final List<ItemCondition> conditions;
  // 선택 순서는 의미 없음 > Set 비교
  final Set<ItemTradeOption> tradeOptions;
  // 콤마 포함 표시 문자열 (예: '12,000')
  final String priceText;
  final bool isAiPredictedPrice;
  final double? latitude;
  final double? longitude;

  const RegisterFormSnapshot({
    required this.existingImageUrls,
    required this.newImagePaths,
    required this.itemName,
    required this.itemDescription,
    required this.category,
    required this.conditions,
    required this.tradeOptions,
    required this.priceText,
    required this.isAiPredictedPrice,
    required this.latitude,
    required this.longitude,
  });

  /// 진입 시점 <-> 현재 값 다르면 true
  bool hasChangesFrom(RegisterFormSnapshot initialSnapshot) => this != initialSnapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RegisterFormSnapshot &&
          listEquals(existingImageUrls, other.existingImageUrls) &&
          listEquals(newImagePaths, other.newImagePaths) &&
          itemName == other.itemName &&
          itemDescription == other.itemDescription &&
          category == other.category &&
          listEquals(conditions, other.conditions) &&
          setEquals(tradeOptions, other.tradeOptions) &&
          priceText == other.priceText &&
          isAiPredictedPrice == other.isAiPredictedPrice &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(existingImageUrls),
    Object.hashAll(newImagePaths),
    itemName,
    itemDescription,
    category,
    Object.hashAll(conditions),
    Object.hashAllUnordered(tradeOptions),
    priceText,
    isAiPredictedPrice,
    latitude,
    longitude,
  );
}
