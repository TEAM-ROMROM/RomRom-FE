import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

class CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String iconPath;

  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppPressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Container(
            height: 80.w,
            width: 80.w,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.categoryChipSelected : AppColors.categoryChipUnselected,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: isSelected ? AppColors.categoryChipBorder : AppColors.transparent,
                width: 1.0.w,
              ),
            ),
            child: Center(
              child: SvgPicture.asset(iconPath, width: 40.w, height: 40.w),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(label, style: CustomTextStyles.p2),
      ],
    );
  }
}
