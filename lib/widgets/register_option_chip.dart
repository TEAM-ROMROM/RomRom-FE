import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../models/app_colors.dart';
import '../models/app_theme.dart';

/// 물품 등록 시 옵션 토글칩 위젯
/// : 물품 상태 / 거래 방식 선택
class RegisterOptionChip extends StatelessWidget {
  final String itemOption; // 옵션 이름 (추가금, 직거래, 택배)
  final bool isSelected;
  final VoidCallback? onTap;

  const RegisterOptionChip({super.key, required this.itemOption, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final chipColor = isSelected ? AppColors.primaryYellow : AppColors.itemCardOptionChip.withValues(alpha: 0.6);
    final chipRadius = BorderRadius.circular(100.r);

    final textStyle = CustomTextStyles.p2.copyWith(
      fontWeight: FontWeight.w600,
      color: isSelected ? AppColors.primaryBlack : AppColors.textColorWhite.withValues(alpha: 0.6),
    );

    final horizontalPadding = itemOption.length >= 4 ? 8.w : 20.w;

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(color: chipColor, borderRadius: chipRadius),
        child: InkWell(
          borderRadius: chipRadius,
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.h),
            child: Text(itemOption, style: textStyle),
          ),
        ),
      ),
    );
  }
}
