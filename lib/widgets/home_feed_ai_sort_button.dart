import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// AI 물품 추천 버튼
class HomeFeedAiSortButton extends StatelessWidget {
  final bool isActive; // 활성화 상태를 나타내는 플래그
  final VoidCallback? onTap;
  const HomeFeedAiSortButton({super.key, this.isActive = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    // border
    final gradientBorder = GradientBoxBorder(
      gradient: LinearGradient(
        colors: AppColors.aiGradient.map((color) => color.withValues(alpha: isActive ? 1.0 : 0.4)).toList(),
        stops: const [0.0, 0.35, 0.70, 1.0],
      ),
      width: 1.w,
    );

    // 그림자
    final boxShadows = [
      BoxShadow(
        color: AppColors.aiButtonGlow.withValues(alpha: isActive ? 0.7 : 0.3), // 첫 번째 그림자 투명도 조절
        offset: const Offset(0, 0),
        blurRadius: 10.r,
        spreadRadius: 0.r,
      ),
      BoxShadow(
        color: Colors.white.withValues(alpha: isActive ? 1.0 : 0.3), // 두 번째 그림자 투명도 조절
        offset: const Offset(0, -1),
        blurRadius: 4.r,
        spreadRadius: 0.r,
      ),
    ];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 67.w,
        height: 24.h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryBlack,
          borderRadius: BorderRadius.circular(100.r),
          border: gradientBorder,
          boxShadow: boxShadows,
        ),
        child: Text('AI 분석', style: CustomTextStyles.p3.copyWith(fontSize: 10.sp)),
      ),
    );
  }
}
