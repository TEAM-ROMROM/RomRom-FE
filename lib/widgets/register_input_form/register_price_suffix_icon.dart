// 물품 등록 가격 입력칸 뒤 아이콘: AI 추천 가격 배지(사용 시) + 상세 보기 화살표
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/gradient_text.dart';

class RegisterPriceSuffixIcon extends StatelessWidget {
  final bool isAiPredictedPrice;

  const RegisterPriceSuffixIcon({super.key, required this.isAiPredictedPrice});

  @override
  Widget build(BuildContext context) {
    final Widget detailViewIcon = Icon(AppIcons.detailView, color: AppColors.opacity30White, size: 18.w);
    if (!isAiPredictedPrice) return detailViewIcon;

    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
            decoration: BoxDecoration(color: AppColors.primaryBlack, borderRadius: BorderRadius.circular(4.r)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/images/ai-recommend-price-star.svg', height: 14.h),
                SizedBox(width: 2.w),
                GradientText(
                  text: 'AI 추천 가격',
                  style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w600),
                  gradient: const LinearGradient(colors: AppColors.aiGradient, stops: [0.0, 0.35, 0.7, 1.0]),
                ),
              ],
            ),
          ),
          detailViewIcon,
        ],
      ),
    );
  }
}
