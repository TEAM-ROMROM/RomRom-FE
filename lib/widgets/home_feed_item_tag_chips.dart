import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
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
  final ItemTradeOption type;
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
        colors: AppColors.aiGradient
            .map((color) => color.withValues(alpha: isActive ? 1.0 : 0.4))
            .toList(),
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
