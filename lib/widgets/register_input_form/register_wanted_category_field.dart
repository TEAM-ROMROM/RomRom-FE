// 물품 등록 희망 교환 카테고리 입력칸 (선택): 고른 카테고리 이름 또는 안내 문구, 탭 > 복수 선택 바텀시트
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/item_wanted_category_policy.dart';

class RegisterWantedCategoryField extends StatelessWidget {
  static const String hintText = '상관없어요 (최대 $maximumWantedItemCategoryCount개 선택)';

  final List<ItemCategories> selectedCategories;
  final VoidCallback onTap;

  const RegisterWantedCategoryField({super.key, required this.selectedCategories, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedCategories.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: AppColors.opacity10White,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.opacity30White, width: 1.5.w),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasSelection ? selectedCategories.map((category) => category.label).join(', ') : hintText,
                style: CustomTextStyles.p2.copyWith(
                  color: hasSelection ? AppColors.textColorWhite : AppColors.opacity40White,
                ),
              ),
            ),
            Icon(AppIcons.detailView, color: AppColors.opacity30White, size: 18.w),
          ],
        ),
      ),
    );
  }
}
