import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/price_tag.dart';
import 'package:romrom_fe/enums/transaction_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 홈 피드 아이템의  태그 위젯

/// 홈 피드 아이템의 상태 태그 위젯
/// : 미개봉, 사용감 적음, 사용감 적당함, 사용감 많음
class HomeFeedConditionTag extends StatelessWidget {
  final ItemCondition condition;
  const HomeFeedConditionTag({
    super.key,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24.h,
      constraints: BoxConstraints(
        minWidth: 62.w, // 최소 가로 길이
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.conditionTagBackground,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        condition.name,
        style:
            CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: Colors.black),
      ),
    );
  }
}

/// transactionType 태그
/// : 직거래, 택배, 추가금
class HomeFeedTransactionTypeTag extends StatelessWidget {
  final TransactionType type;
  const HomeFeedTransactionTypeTag({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62.w,
      height: 24.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: AppColors.transactionTagBackground,
        borderRadius: BorderRadius.circular(100.r),
      ),
      child: Text(
        type.name,
        style:
            CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: Colors.black),
      ),
    );
  }
}

/// 활성화된 AI 분석 버튼
class HomeFeedAiTag extends StatelessWidget {
  final bool isActive; // 활성화 상태를 나타내는 플래그
  const HomeFeedAiTag({
    super.key,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    // border
    final gradientBorder = GradientBoxBorder(
      gradient: LinearGradient(
        colors: [
          AppColors.aiTagGradientBorder1
              .withValues(alpha: isActive ? 1.0 : 0.4),
          AppColors.aiTagGradientBorder2
              .withValues(alpha: isActive ? 1.0 : 0.4),
          AppColors.aiTagGradientBorder3
              .withValues(alpha: isActive ? 1.0 : 0.4),
          AppColors.aiTagGradientBorder4
              .withValues(alpha: isActive ? 1.0 : 0.4),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ),
      width: 1.w,
    );

    // 그림자
    final boxShadows = [
      BoxShadow(
        color: AppColors.aiButtonGlow
            .withValues(alpha: isActive ? 0.7 : 0.3), // 첫 번째 그림자 투명도 조절
        offset: const Offset(0, 0),
        blurRadius: 10.r,
        spreadRadius: 0.r,
      ),
      BoxShadow(
        color: Colors.white
            .withValues(alpha: isActive ? 1.0 : 0.3), // 두 번째 그림자 투명도 조절
        offset: const Offset(0, -1),
        blurRadius: 4.r,
        spreadRadius: 0.r,
      ),
    ];

    return Container(
      width: 67.w,
      height: 24.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(100.r),
        border: gradientBorder,
        boxShadow: boxShadows,
      ),
      child: Text(
        'AI 분석',
        style: CustomTextStyles.p3.copyWith(fontSize: 10.sp),
      ),
    );
  }
}

/// AI 분석 적정가 태그 생성
class HomeFeedAiAnalysisTag extends StatelessWidget {
  final PriceTag tag; // PriceTag enum을 사용하여 태그를 정의
  const HomeFeedAiAnalysisTag({super.key, required this.tag});

  @override
  Widget build(BuildContext context) {
    // border
    final gradientBorder = GradientBoxBorder(
      gradient: LinearGradient(
        colors: [
          AppColors.aiTagGradientBorder1.withValues(alpha: 1.0),
          AppColors.aiTagGradientBorder2.withValues(alpha: 1.0),
          AppColors.aiTagGradientBorder3.withValues(alpha: 1.0),
          AppColors.aiTagGradientBorder4.withValues(alpha: 1.0),
        ],
        stops: const [0.0, 0.35, 0.70, 1.0],
      ),
      width: 1.w,
    );

    return tag == PriceTag.aiAnalyzed
        ? Container(
            width: 64.w,
            height: 17.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryBlack,
              borderRadius: BorderRadius.circular(100.r),
              border: gradientBorder,
            ),
            child: Text(
              tag.name,
              style: CustomTextStyles.p3.copyWith(fontSize: 9.sp),
            ),
          )
        : Container(
            width: 46.w,
            height: 17.h,
            decoration: BoxDecoration(
              color: AppColors.opacity80White,
              borderRadius: BorderRadius.circular(100.r),
            ),
            child: Row(
              // mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tag.name,
                  style: CustomTextStyles.p3
                      .copyWith(fontSize: 9.sp, color: AppColors.primaryBlack),
                ),
              ],
            ),
          );
  }
}
