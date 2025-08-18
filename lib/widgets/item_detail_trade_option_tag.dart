import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 물품 상세 페이지용 거래 옵션 태그 위젯
class ItemDetailTradeOptionTag extends StatelessWidget {
  final String option;

  const ItemDetailTradeOptionTag({
    super.key,
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 4.w),
      padding: EdgeInsets.symmetric(
        horizontal: 8.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFCACDFF),
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        option,
        style: CustomTextStyles.p3.copyWith(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryBlack,
          height: 1.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}