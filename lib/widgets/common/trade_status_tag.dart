import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 거래 상태 태그: 채팅 중·교환완료 (대기 상태는 빈 Container)
class TradeStatusTagWidget extends StatelessWidget {
  final TradeStatus status;

  const TradeStatusTagWidget({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == TradeStatus.pending) return Container();

    final bool isChatting = status == TradeStatus.chatting;
    return AppTag(
      label: isChatting ? '채팅 중' : '교환완료',
      alignment: Alignment.center,
      width: 60.w,
      height: 23.h,
      borderRadius: 4.r,
      backgroundColor: isChatting ? AppColors.tradeStatusIsChatting : AppColors.tradeStatusIsCompleted,
      textStyle: CustomTextStyles.p3.copyWith(fontSize: 10.sp),
    );
  }
}
