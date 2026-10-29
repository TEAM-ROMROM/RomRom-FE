import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 요청 관리 페이지용 거래 옵션 태그 위젯 (고정 너비 62, 알약형)
class RequestManagementTradeOptionTag extends StatelessWidget {
  final ItemTradeOption option;

  const RequestManagementTradeOptionTag({super.key, required this.option});

  @override
  Widget build(BuildContext context) {
    return AppTag(
      label: option.label,
      width: 62.w,
      alignment: Alignment.center,
      borderRadius: 100.r,
      backgroundColor: AppColors.secondaryBlack2,
      padding: EdgeInsets.fromLTRB(18.w, 6, 18.w, 7),
      textStyle: CustomTextStyles.p3.copyWith(fontSize: 10.sp),
    );
  }
}
