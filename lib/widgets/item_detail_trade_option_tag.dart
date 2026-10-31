import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 물품 상세 페이지용 거래 옵션 태그 위젯 (고정 50x23, 알약형)
class ItemDetailTradeOptionTag extends StatelessWidget {
  final String option;

  const ItemDetailTradeOptionTag({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: option,
      height: 23.h,
      width: 50.w,
      alignment: Alignment.center,
      backgroundColor: AppColors.transactionTagBackground,
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
