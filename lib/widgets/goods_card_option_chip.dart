// lib/widgets/goods_card_option_chip.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/goods_card_scale_utils.dart';

class GoodsCardOptionChip extends StatelessWidget {
  final String goodsOption;

  const GoodsCardOptionChip({
    super.key,
    required this.goodsOption,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.watch<GoodsCardScaleProvider>().scale;

    return Container(
      width: cs.s(72),
      height: cs.s(29),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.goodsCardOptionChip,
        borderRadius: cs.radius(100),
      ),
      child: Text(
        goodsOption,
        style: CustomTextStyles.p3.copyWith(
          fontSize: cs.fontSize(CustomTextStyles.p3.fontSize!),
        ),
      ),
    );
  }
}
