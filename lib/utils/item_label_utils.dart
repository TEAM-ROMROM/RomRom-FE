// lib/utils/item_label_utils.dart
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';

/// 물품 상태(ItemCondition) 서버 이름 → 표시 레이블 변환
String? itemConditionLabel(String? serverName) {
  if (serverName == null) return null;
  try {
    return ItemCondition.fromServerName(serverName).label;
  } catch (_) {
    return null;
  }
}

/// 거래 방식(ItemTradeOption) 서버 이름 목록 → 표시 레이블 목록 변환
List<String> itemTradeOptionLabels(List<String>? serverNames) {
  if (serverNames == null) return [];
  return serverNames
      .map((name) {
        try {
          return ItemTradeOption.fromServerName(name).label;
        } catch (_) {
          return null;
        }
      })
      .whereType<String>()
      .toList();
}

/// 물품 상태 + 거래 방식 태그 목록 생성 (null 값 제외)
List<String> itemTagLabels({String? condition, List<String>? tradeOptions}) {
  return [?itemConditionLabel(condition), ...itemTradeOptionLabels(tradeOptions)];
}
