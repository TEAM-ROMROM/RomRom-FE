import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/ai_price_basis.dart';

void main() {
  group('AiPriceBasis.isSameInput', () {
    const aiPriceBasis = AiPriceBasis(itemName: '의자', itemDescription: '튼튼한 원목 의자입니다', itemCondition: 'SLIGHTLY_USED');

    test('같은 입력 (앞뒤 공백 차이 무시) > true', () {
      expect(
        aiPriceBasis.isSameInput(itemName: ' 의자 ', itemDescription: '튼튼한 원목 의자입니다\n', itemCondition: 'SLIGHTLY_USED'),
        true,
      );
    });

    test('제목 변경 > false', () {
      expect(
        aiPriceBasis.isSameInput(itemName: '책상', itemDescription: '튼튼한 원목 의자입니다', itemCondition: 'SLIGHTLY_USED'),
        false,
      );
    });

    test('설명 변경 > false', () {
      expect(
        aiPriceBasis.isSameInput(itemName: '의자', itemDescription: '다리 하나가 흔들려요', itemCondition: 'SLIGHTLY_USED'),
        false,
      );
    });

    test('물건 상태 변경 > false', () {
      expect(aiPriceBasis.isSameInput(itemName: '의자', itemDescription: '튼튼한 원목 의자입니다', itemCondition: 'NEW'), false);
    });
  });
}
