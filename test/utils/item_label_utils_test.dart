import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/item_label_utils.dart';

/// 미지 서버값 폴백: 물품 상태·거래 방식 라벨은 모르는 값을 제외 (예외 없음)
void main() {
  test('itemConditionLabel > 아는 값은 라벨, 모르는 값·null 은 null', () {
    expect(itemConditionLabel('SEALED'), '미개봉');
    expect(itemConditionLabel('NEW_CONDITION'), isNull);
    expect(itemConditionLabel(null), isNull);
  });

  test('itemTradeOptionLabels > 모르는 값 제외, 순서 유지', () {
    expect(itemTradeOptionLabels(['DIRECT_ONLY', 'NEW_OPTION', 'DELIVERY_ONLY']), ['직거래', '택배']);
    expect(itemTradeOptionLabels(null), isEmpty);
  });

  test('itemTagLabels > 모르는 상태·옵션 모두 제외', () {
    expect(itemTagLabels(condition: 'NEW_CONDITION', tradeOptions: ['NEW_OPTION']), isEmpty);
    expect(itemTagLabels(condition: 'SEALED', tradeOptions: ['EXTRA_CHARGE']), ['미개봉', '추가금']);
  });
}
