import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/utils/trade_request_input_rules.dart';

void main() {
  group('parseTradeExtraChargeAmount', () {
    test('추가금 선택 + 콤마 금액 > 숫자', () {
      expect(
        parseTradeExtraChargeAmount(selectedOptions: {ItemTradeOption.additionalPrice}, amountText: '15,000'),
        15000,
      );
    });

    test('추가금 미선택 > 금액이 있어도 null', () {
      expect(
        parseTradeExtraChargeAmount(selectedOptions: {ItemTradeOption.deliveryOnly}, amountText: '15,000'),
        isNull,
      );
    });

    test('빈 입력·0원 > null (미입력 처리)', () {
      final extraChargeOptions = {ItemTradeOption.additionalPrice};
      expect(parseTradeExtraChargeAmount(selectedOptions: extraChargeOptions, amountText: ''), isNull);
      expect(parseTradeExtraChargeAmount(selectedOptions: extraChargeOptions, amountText: '0'), isNull);
    });
  });

  group('isTradeExtraChargeAmountValid', () {
    test('미입력·상한 이하 허용, 상한 초과 거부', () {
      expect(isTradeExtraChargeAmountValid(null), isTrue);
      expect(isTradeExtraChargeAmountValid(tradeExtraChargeMaximumAmount), isTrue);
      expect(isTradeExtraChargeAmountValid(tradeExtraChargeMaximumAmount + 1), isFalse);
    });
  });

  group('normalizeTradeRequestMessage', () {
    test('앞뒤 공백 제거, 줄바꿈·탭 > 공백, 빈 값 > null', () {
      expect(normalizeTradeRequestMessage('  주말 가능해요  '), '주말 가능해요');
      expect(normalizeTradeRequestMessage('첫 줄\n둘째\t줄'), '첫 줄 둘째 줄');
      expect(normalizeTradeRequestMessage('   '), isNull);
    });
  });
}
