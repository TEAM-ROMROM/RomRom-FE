import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 요청 관리 페이지용 거래 옵션 태그 위젯
class RequestManagementTradeOptionTag extends StatelessWidget {
  final ItemTradeOption option;

  const RequestManagementTradeOptionTag({
    super.key,
    required this.option,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62.w,
      height: 23.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100.r),
        color: AppColors.secondaryBlack2,
      ),
      padding: EdgeInsets.fromLTRB(18.w, 6.h, 18.w, 7.h),
      child: Text(
        option.label,
        style: CustomTextStyles.p3.copyWith(
          fontSize: 10.sp,
        ),
      ),
    );
  }
}
