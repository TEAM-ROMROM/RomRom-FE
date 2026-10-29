import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/register_form_snapshot.dart';

/// 기준 스냅샷 생성 (지정 필드만 덮어쓰기)
RegisterFormSnapshot buildSnapshot({
  List<String> existingImageUrls = const ['https://image/1.webp'],
  List<String> newImagePaths = const [],
  String itemName = '자전거',
  String itemDescription = '거의 새 것인 자전거입니다',
  ItemCategories? category = ItemCategories.shoes,
  List<ItemCondition> conditions = const [ItemCondition.sealed],
  Set<ItemTradeOption> tradeOptions = const {ItemTradeOption.directTradeOnly},
  String priceText = '12,000',
  bool isAiPredictedPrice = false,
  double? latitude = 37.5,
  double? longitude = 127.0,
}) {
  return RegisterFormSnapshot(
    existingImageUrls: existingImageUrls,
    newImagePaths: newImagePaths,
    itemName: itemName,
    itemDescription: itemDescription,
    category: category,
    conditions: conditions,
    tradeOptions: tradeOptions,
    priceText: priceText,
    isAiPredictedPrice: isAiPredictedPrice,
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  group('RegisterFormSnapshot 미저장 변경 판정', () {
    final initialSnapshot = buildSnapshot();

    test('같은 값 > 변경 없음', () {
      expect(buildSnapshot().hasChangesFrom(initialSnapshot), isFalse);
      expect(buildSnapshot().hashCode, initialSnapshot.hashCode);
    });

    test('거래 방식 선택 순서만 다름 > 변경 없음', () {
      const firstOption = ItemTradeOption.directTradeOnly;
      const secondOption = ItemTradeOption.deliveryOnly;
      final orderedSnapshot = buildSnapshot(tradeOptions: {firstOption, secondOption});
      final reversedSnapshot = buildSnapshot(tradeOptions: {secondOption, firstOption});
      expect(reversedSnapshot.hasChangesFrom(orderedSnapshot), isFalse);
    });

    test('필드 하나라도 다름 > 변경 있음', () {
      final changedSnapshots = <String, RegisterFormSnapshot>{
        '새 사진 추가': buildSnapshot(newImagePaths: ['/tmp/new.jpg']),
        '기존 사진 삭제': buildSnapshot(existingImageUrls: []),
        '이름': buildSnapshot(itemName: '킥보드'),
        '설명': buildSnapshot(itemDescription: '설명을 바꿨습니다 열자 이상'),
        '카테고리': buildSnapshot(category: ItemCategories.beauty),
        '상태': buildSnapshot(conditions: [ItemCondition.heavilyUsed]),
        '거래 방식': buildSnapshot(tradeOptions: {ItemTradeOption.additionalPrice}),
        '가격': buildSnapshot(priceText: '15,000'),
        'AI 가격 사용': buildSnapshot(isAiPredictedPrice: true),
        '위치': buildSnapshot(latitude: 37.6),
      };
      changedSnapshots.forEach((fieldName, changedSnapshot) {
        expect(changedSnapshot.hasChangesFrom(initialSnapshot), isTrue, reason: fieldName);
      });
    });

    test('등록 빈 폼 기준 > 이름만 입력해도 변경 있음', () {
      final emptyFormSnapshot = buildSnapshot(
        existingImageUrls: [],
        itemName: '',
        itemDescription: '',
        category: null,
        conditions: [],
        tradeOptions: {},
        priceText: '0',
        latitude: null,
        longitude: null,
      );
      final typedSnapshot = buildSnapshot(
        existingImageUrls: [],
        itemName: '가',
        itemDescription: '',
        category: null,
        conditions: [],
        tradeOptions: {},
        priceText: '0',
        latitude: null,
        longitude: null,
      );
      expect(typedSnapshot.hasChangesFrom(emptyFormSnapshot), isTrue);
    });
  });
}
