import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/widgets/common/item_reserved_tag.dart';
import 'package:romrom_fe/widgets/common/trade_status_tag.dart';

/// 물품 거래 상태 태그: 교환완료 > 교환완료, 예약중 > 예약중, 그 외 > 표시 없음
class ItemTradeStateTag extends StatelessWidget {
  final Item item;

  const ItemTradeStateTag({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item.itemStatus == ItemStatus.exchanged.serverName) {
      return const TradeStatusTagWidget(status: TradeStatus.traded);
    }
    if (item.isReserved == true) return const ItemReservedTag();
    return const SizedBox.shrink();
  }
}
