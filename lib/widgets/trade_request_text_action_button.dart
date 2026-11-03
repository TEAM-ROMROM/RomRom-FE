import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

/// 교환 요청 화면 노란 글자 보조 버튼 (다른 물품 선택·보낸 요청 보기·다시 확인)
class TradeRequestTextActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const TradeRequestTextActionButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      enableRipple: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w600, color: AppColors.primaryYellow),
        ),
      ),
    );
  }
}
