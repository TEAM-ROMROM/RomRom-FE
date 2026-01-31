import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class TradeStatusTagWidget extends StatelessWidget {
  final TradeStatus status;

  const TradeStatusTagWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isChatting = status == TradeStatus.chatting;

    return status == TradeStatus.pending
        ? Container()
        : Container(
            alignment: Alignment.center,
            width: 60.w,
            height: 23.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4.r),
              color: isChatting ? AppColors.tradeStatusIsChatting : AppColors.tradeStatusIsCompleted,
            ),
            child: Text(isChatting ? '채팅 중' : '거래완료', style: CustomTextStyles.p3.copyWith(fontSize: 10.sp)),
          );
  }
}
