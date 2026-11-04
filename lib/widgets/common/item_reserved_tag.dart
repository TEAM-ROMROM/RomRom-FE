import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 예약중 태그 (거래 상태 태그와 같은 크기·글자, #1005)
class ItemReservedTag extends StatelessWidget {
  const ItemReservedTag({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: '예약중',
      alignment: Alignment.center,
      width: 60.w,
      height: 23.h,
      borderRadius: 4.r,
      backgroundColor: AppColors.itemReservedTag,
      textStyle: CustomTextStyles.p3.copyWith(fontSize: 10.sp),
    );
  }
}
