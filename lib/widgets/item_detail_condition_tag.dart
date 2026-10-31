import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 물품 상세 페이지용 사용감 태그 위젯 (최소 50x23, 라벨 길이만큼 늘어남)
class ItemDetailConditionTag extends StatelessWidget {
  final String condition;

  const ItemDetailConditionTag({super.key, required this.condition});

  // 태그 모양 (홈 피드 네이티브 광고 "광고" 배지도 같은 값 사용)
  static EdgeInsets get padding => EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h);
  static BoxConstraints get constraints => BoxConstraints(minWidth: 50.w, minHeight: 23.h);
  static const Color backgroundColor = AppColors.conditionTagBackground;
  static double get borderRadius => 100.r;
  static TextStyle get textStyle => CustomTextStyles.p3.copyWith(
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlack,
    height: 1.0,
  );

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: condition,
      padding: padding,
      constraints: constraints,
      backgroundColor: backgroundColor,
      borderRadius: borderRadius,
      textStyle: textStyle,
      textAlign: TextAlign.center,
    );
  }
}
