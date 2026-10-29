import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 물품 상세 페이지용 사용감 태그 위젯 (최소 50x23, 라벨 길이만큼 늘어남)
class ItemDetailConditionTag extends StatelessWidget {
  final String condition;

  const ItemDetailConditionTag({super.key, required this.condition});

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: condition,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      constraints: BoxConstraints(minWidth: 50.w, minHeight: 23.h),
      backgroundColor: AppColors.conditionTagBackground,
      borderRadius: 100.r,
      textStyle: CustomTextStyles.p3.copyWith(
        fontSize: 10.sp,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryBlack,
        height: 1.0,
      ),
      textAlign: TextAlign.center,
    );
  }
}
