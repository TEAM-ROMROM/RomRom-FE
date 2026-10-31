// 물품 등록 카테고리 선택 바텀시트: 손잡이, 제목, 카테고리 칩 목록 (탭 즉시 닫힘)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/category_chip.dart';

class RegisterCategoryBottomSheet extends StatelessWidget {
  final ItemCategories? selectedCategory;
  final ValueChanged<ItemCategories> onCategoryTap;

  const RegisterCategoryBottomSheet({super.key, required this.selectedCategory, required this.onCategoryTap});

  /// 바텀시트 표시 > 고른 카테고리 (고르지 않고 닫으면 기존 선택 그대로)
  static Future<ItemCategories?> show({
    required BuildContext context,
    required ItemCategories? selectedCategory,
  }) async {
    ItemCategories? tempSelected = selectedCategory;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.primaryBlack,
      barrierColor: AppColors.opacity80Black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setInnerState) {
            return RegisterCategoryBottomSheet(
              selectedCategory: tempSelected,
              onCategoryTap: (category) {
                // 닫히는 동안 고른 칩 선택 표시 유지
                setInnerState(() {
                  tempSelected = category;
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
    return tempSelected;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0.h),
              child: Container(
                width: 50.w,
                height: 4.h,
                decoration: BoxDecoration(color: AppColors.opacity50White, borderRadius: BorderRadius.circular(5.r)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(left: 26.w, bottom: 12.h),
            child: Text(
              ItemTextFieldPhrase.category.label,
              style: CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(right: 24.w, left: 24.w, top: 24.h, bottom: 12.h),
              child: Wrap(
                spacing: 8.0.w,
                runSpacing: 12.0.h,
                children: ItemCategories.values.map((category) {
                  return CategoryChip(
                    label: category.label,
                    isSelected: selectedCategory == category,
                    onTap: () => onCategoryTap(category),
                    iconPath: category.iconPath,
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
