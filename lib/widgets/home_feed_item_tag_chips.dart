import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 홈 피드 아이템의  태그 위젯

/// 홈 피드 아이템의 상태 태그 위젯
/// : 미개봉, 사용감 적음, 사용감 적당함, 사용감 많음
class HomeFeedConditionTag extends StatelessWidget {
  final ItemCondition condition;
  const HomeFeedConditionTag({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24.h,
      constraints: BoxConstraints(
        minWidth: 62.w, // 최소 가로 길이
      ),
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(color: AppColors.conditionTagBackground, borderRadius: BorderRadius.circular(100.r)),
      child: Text(
        condition.label,
        style: CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: Colors.black),
      ),
    );
  }
}

/// transactionType 태그
/// : 직거래, 택배, 추가금
class HomeFeedTransactionTypeTag extends StatelessWidget {
  final ItemTradeOption type;
  const HomeFeedTransactionTypeTag({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62.w,
      height: 24.h,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 7.h),
      decoration: BoxDecoration(color: AppColors.transactionTagBackground, borderRadius: BorderRadius.circular(100.r)),
      child: Text(
        type.label,
        style: CustomTextStyles.p3.copyWith(fontSize: 10.sp, color: Colors.black),
      ),
    );
  }
}
