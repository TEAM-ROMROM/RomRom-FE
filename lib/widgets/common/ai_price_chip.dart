import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';

/// AI 추천 가격 칩 위젯
/// ItemPriceScreen 카드 내부 및 RegisterInputForm 가격 행 우측에 공통 사용
class AiPriceChipWidget extends StatelessWidget {
  const AiPriceChipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.primaryBlack, borderRadius: BorderRadius.circular(4)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.7, 1.0]).createShader(bounds),
            child: Icon(Icons.auto_awesome, size: 12.sp, color: AppColors.textColorWhite),
          ),
          SizedBox(width: 3.w),
          GradientText(
            text: 'AI 추천 가격',
            style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.3.sp),
            gradient: const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.7, 1.0]),
          ),
        ],
      ),
    );
  }
}
