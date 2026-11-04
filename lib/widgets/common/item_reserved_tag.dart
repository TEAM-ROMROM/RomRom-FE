import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/widgets/common/app_tag.dart';

/// 예약중 태그 (거래 상태 태그와 같은 크기·글자, #1005)
class ItemReservedTag extends StatelessWidget {
  const ItemReservedTag({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTag.tradeState(label: '예약중', backgroundColor: AppColors.itemReservedTag);
  }
}
