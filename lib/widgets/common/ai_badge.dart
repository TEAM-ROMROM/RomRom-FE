import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// AI 배지 위젯
class AiBadgeWidget extends StatelessWidget {
  const AiBadgeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 21.w,
      height: 20.h,
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.r),
        color: AppColors.aiTagBackground, // AI 태그 배경색
      ),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            colors: AppColors.aiGradient,
            stops: [0.0, 0.35, 0.70, 1.0],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds);
        },
        child: Text(
          'AI',
          style: CustomTextStyles.p3.copyWith(
            letterSpacing: -0.5.sp,
            color: AppColors.textColorWhite, // ShaderMask가 적용되기 위한 기본 색상
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
