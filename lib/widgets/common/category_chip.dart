import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({super.key, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return RawChip(
      label: Text(
        label,
        style: CustomTextStyles.p2.copyWith(
          fontSize: 14.0.w,
          color: isSelected ? AppColors.textColorBlack : AppColors.textColorWhite,
          wordSpacing: -0.32.w,
        ),
      ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.0.h),
      selected: isSelected,
      selectedColor: AppColors.primaryYellow,
      backgroundColor: AppColors.primaryBlack,
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.circular(100.r)),
      side: BorderSide(
        color: isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
        strokeAlign: BorderSide.strokeAlignOutside,
        width: 1.0.w,
      ),
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onTap(),
    );
  }
}
