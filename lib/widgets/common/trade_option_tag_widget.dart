import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';

/// 거래 옵션 태그 위젯
class TradeOptionTagWidget extends StatelessWidget {
  final ItemTradeOption option;

  const TradeOptionTagWidget({
    super.key,
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62.w,
      height: 23.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        color: const Color(0x661D1E27), // rgba(29, 30, 39, 0.40)
      ),
      padding: EdgeInsets.symmetric(horizontal: 18.w),
      alignment: Alignment.center,
      child: Text(
        option.name,
        style: TextStyle(
          color: Colors.white,
          fontFamily: 'Pretendard',
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}