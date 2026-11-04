import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 거래 상태 태그: 채팅 중·교환완료 (대기 상태는 빈 Container)
class TradeStatusTagWidget extends StatelessWidget {
  final TradeStatus status;

  const TradeStatusTagWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == TradeStatus.pending) return Container();

    final bool isChatting = status == TradeStatus.chatting;
    return AppTag.tradeState(
      label: isChatting ? '채팅 중' : '교환완료',
      backgroundColor: isChatting ? AppColors.tradeStatusIsChatting : AppColors.tradeStatusIsCompleted,
    );
  }
}
