import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/utils/withdrawal_ongoing_trade_message.dart';

TradeRequestHistory buildOngoingTrade(int index, {String tradeStatus = 'PENDING'}) => TradeRequestHistory(
  tradeRequestHistoryId: 'trade-$index',
  takeItem: Item(itemName: '받는물품$index'),
  giveItem: Item(itemName: '보내는물품$index'),
  itemTradeOptions: const [],
  tradeStatus: tradeStatus,
);

/// 탈퇴 전 진행 중 거래 안내: 건수, 최대 3줄, 나머지 건수, 모르는 상태 > 진행 중 (#1008)
void main() {
  test('건수·거래별 줄·상태 표시', () {
    final message = buildOngoingTradeCancellationMessage([
      buildOngoingTrade(1),
      buildOngoingTrade(2, tradeStatus: 'CHATTING'),
    ]);
    expect(message, contains('진행 중인 거래가 2건 있어요.'));
    expect(message, contains('받는물품1 ↔ 보내는물품1 (대기)'));
    expect(message, contains('받는물품2 ↔ 보내는물품2 (채팅 중)'));
  });

  test('3건 초과 > 3줄 + 외 N건, 모르는 상태 > 진행 중', () {
    final message = buildOngoingTradeCancellationMessage([
      buildOngoingTrade(1, tradeStatus: 'TRADE_COMPLETE_REQUESTED'),
      for (var index = 2; index <= 5; index++) buildOngoingTrade(index),
    ]);
    expect(message, contains('받는물품1 ↔ 보내는물품1 (진행 중)'));
    expect(message, isNot(contains('받는물품4')));
    expect(message, contains('외 2건'));
  });
}
