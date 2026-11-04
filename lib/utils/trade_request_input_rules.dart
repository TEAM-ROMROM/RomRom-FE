// 교환 요청 입력 판정 순수 함수: 추가금 파싱·범위, 한 줄 메시지 정리 (서버 TradeRequestContentPolicy와 같은 기준, #1005)
import 'package:romrom_fe/enums/item_trade_option.dart';

// 추가금 최대 금액 (원, 서버 상한과 동일)
const int tradeExtraChargeMaximumAmount = 10000000;

// 한 줄 메시지 최대 글자 수 (서버 varchar(100)과 동일)
const int tradeRequestMessageMaxLength = 100;

/// 추가금 입력 > 전송 값 (추가금 미선택·빈 입력·0원 > null, 콤마 제거)
/// 0원: 콤마 포맷터가 지운 칸을 '0'으로 채움 > 미입력과 같게 처리
int? parseTradeExtraChargeAmount({required Set<ItemTradeOption> selectedOptions, required String amountText}) {
  if (!selectedOptions.contains(ItemTradeOption.additionalPrice)) return null;
  final digits = amountText.replaceAll(RegExp(r'[^0-9]'), '');
  final extraChargeAmount = int.tryParse(digits);
  if (extraChargeAmount == null || extraChargeAmount == 0) return null;
  return extraChargeAmount;
}

/// 추가금 범위 안인지 (null = 미입력 > 허용)
bool isTradeExtraChargeAmountValid(int? extraChargeAmount) {
  if (extraChargeAmount == null) return true;
  return extraChargeAmount >= 0 && extraChargeAmount <= tradeExtraChargeMaximumAmount;
}

/// 한 줄 메시지 > 전송 값 (앞뒤 공백 제거, 줄바꿈은 공백으로, 빈 값 > null)
String? normalizeTradeRequestMessage(String messageText) {
  final singleLineMessage = messageText.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
  return singleLineMessage.isEmpty ? null : singleLineMessage;
}
