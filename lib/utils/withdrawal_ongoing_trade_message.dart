import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

// 안내 목록에 이름까지 보여 줄 최대 거래 수 (나머지는 '외 N건')
const int maximumListedOngoingTradeCount = 3;

/// 탈퇴 전 진행 중 거래 안내 문구: 건수 > 거래별 '받는 물품 ↔ 보내는 물품 (상태)' 최대 3줄 > 나머지 건수
String buildOngoingTradeCancellationMessage(List<TradeRequestHistory> ongoingTrades) {
  final listedTradeLines = ongoingTrades.take(maximumListedOngoingTradeCount).map(_toTradeLine);
  final hiddenTradeCount = ongoingTrades.length - maximumListedOngoingTradeCount;
  return [
    '진행 중인 거래가 ${ongoingTrades.length}건 있어요.',
    '탈퇴하면 아래 거래가 모두 취소돼요.',
    '',
    ...listedTradeLines,
    if (hiddenTradeCount > 0) '외 $hiddenTradeCount건',
  ].join('\n');
}

/// 거래 1건 > '받는 물품 ↔ 보내는 물품 (상태)' (모르는 상태 > 진행 중)
String _toTradeLine(TradeRequestHistory ongoingTrade) {
  final takeItemName = ongoingTrade.takeItem.itemName ?? '물품';
  final giveItemName = ongoingTrade.giveItem.itemName ?? '물품';
  final tradeStatusLabel = TradeStatus.fromServerName(ongoingTrade.tradeStatus)?.label ?? '진행 중';
  return '$takeItemName ↔ $giveItemName ($tradeStatusLabel)';
}
