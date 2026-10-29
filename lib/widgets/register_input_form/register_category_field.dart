// 물품 등록 카테고리 입력칸: 선택값·안내 문구 표시, 미선택 오류 테두리·문구
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_text_field_phrase.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RegisterCategoryField extends StatelessWidget {
  final ItemCategories? selectedCategory;
  // 터치했거나 제출 시도 후 미선택이면 오류 표시
  final bool shouldShowError;
  final VoidCallback onTap;

  const RegisterCategoryField({
    super.key,
    required this.selectedCategory,
    required this.shouldShowError,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isErrorVisible = shouldShowError && selectedCategory == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: isErrorVisible ? AppColors.errorContainer : AppColors.opacity10White,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isErrorVisible ? AppColors.errorBorder : AppColors.opacity30White,
                width: 1.5.w,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCategory?.label ?? ItemTextFieldPhrase.category.hintText,
                    style: CustomTextStyles.p2.copyWith(
                      color: selectedCategory != null ? AppColors.textColorWhite : AppColors.opacity40White,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isErrorVisible)
          Padding(
            padding: EdgeInsets.only(top: 8.0.h),
            child: Text(
              ItemTextFieldPhrase.category.errorText,
              style: CustomTextStyles.p3.copyWith(color: AppColors.errorBorder),
            ),
          ),
      ],
    );
  }
}
