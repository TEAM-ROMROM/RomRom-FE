import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/services/api/member_api.dart';
import 'package:romrom_fe/widgets/category_completion_button.dart';
import 'package:romrom_fe/widgets/category_header.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<int> selectedCategories = [];

  bool get isSelectedCategories =>
      selectedCategories.isNotEmpty; // 카테고리 선택했는지 bool로 반환

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 160.h),
            // 카테고리 화면 헤더 문구
            const CategoryHeader(
                headLine: '카테고리 선택', subHeadLine: '관심있는 분야를 선택해주세요!'),
            SizedBox(height: 32.h),
            _buildCategoryChips(context), // 카테고리 선택 choiceChip 빌드
            SizedBox(height: 56.0.h),
            // 카테고리 선택 완료 버튼
            CategoryCompletionButton(
                isEnabled: isSelectedCategories,
                enabledOnPressed: () async {
                  await postCategoryPreferences(context, selectedCategories);
                },
                buttonText: '선택 완료'),
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  /// 카테고리 선택 choiceChip 빌드
  Widget _buildCategoryChips(BuildContext context) {
    return Wrap(
      spacing: 8.0.w,
      children: ItemCategories.values
          .map((category) => _buildCategoryChip(context, category))
          .toList(),
    );
  }

  /// 카테고리 chip css 일괄 지정
  Widget _buildCategoryChip(BuildContext context, ItemCategories category) {
    final bool isSelected = selectedCategories.contains(category.id);

    return ChoiceChip(
      label: Text(category.name),
      labelStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isSelected
                ? AppColors.textColorBlack
                : AppColors.textColorWhite,
          ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.0.h),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        side: isSelected
            ? BorderSide.none
            : const BorderSide(
                color: AppColors.textColorWhite,
                strokeAlign: BorderSide.strokeAlignInside,
                width: 1.0,
              ),
        borderRadius: BorderRadiusDirectional.circular(100.r),
      ),
      showCheckmark: false,
      onSelected: (bool selected) =>
          _toggleCategorySelection(category.id, selected),
    );
  }

  /// 선택하면 categoryId 리스트 추가
  void _toggleCategorySelection(int categoryId, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedCategories.add(categoryId);
      } else {
        selectedCategories.remove(categoryId);
      }
      debugPrint("선택 카테고리 : $selectedCategories");
    });
  }
}
