import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class GoodsCardOptionChip extends StatelessWidget {
  const GoodsCardOptionChip({
    super.key,
    required this.goodsOption,
  });

  final String goodsOption;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72.w,
      height: 29.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.goodsCardOptionChip,
        borderRadius: BorderRadius.all(
          Radius.circular(100.r),
        ),
      ),
      child: Text(
        goodsOption,
        style: CustomTextStyles.p3.copyWith(
          color: AppColors.textColorWhite,
        ),
      ),
    );
  }
}
