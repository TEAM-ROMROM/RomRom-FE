import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/category.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/screens/home_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<int> selectedCategories = [];

  bool get hasSelectedCategories =>
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
            _buildHeader(context), // 카테고리 선택 안내 문구 빌드
            SizedBox(height: 32.h),
            _buildCategoryChips(context), // 카테고리 선택 choiceChip 빌드
            SizedBox(height: 56.0.h),
            _buildCompletionButton(context), // 선택 완료 버튼 빌드
          ],
        ),
      ),
    );
  }

  /// 카테고리 선택 안내 문구 빌드
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('카테고리를 선택', style: Theme.of(context).textTheme.headlineLarge),
        SizedBox(height: 12.h),
        Text('관심있는 분야를 선택해주세요!',
            style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }

  /// 카테고리 선택 choiceChip 빌드
  Widget _buildCategoryChips(BuildContext context) {
    return Wrap(
      spacing: 8.0.w,
      children: Category.values
          .map((category) => _buildCategoryChip(context, category))
          .toList(),
    );
  }

  /// 카테고리 chip css 일괄 지정
  Widget _buildCategoryChip(BuildContext context, Category category) {
    final bool isSelected = selectedCategories.contains(category.id);

    return ChoiceChip(
      label: Text(category.name),
      labelStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: isSelected
                ? AppColors.textColor_black
                : AppColors.textColor_white,
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
                color: AppColors.textColor_white,
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
      debugPrint("$selectedCategories");
    });
  }

  /// 선택 완료 버튼 빌드
  Widget _buildCompletionButton(BuildContext context) {
    final TextStyle? buttonTextStyle =
        Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: hasSelectedCategories
                  ? AppColors.textColor_black
                  : AppColors.textColor_black.withValues(alpha: 0.7),
            );

    return Center(
      child: TextButton(
        onPressed: hasSelectedCategories ? _navigateToHomeScreen : null,
        style: TextButton.styleFrom(
          backgroundColor: hasSelectedCategories
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.7),
          padding: EdgeInsets.symmetric(
              horizontal: 104.0.w, vertical: 16.0.h), // 여기에 padding 추가
        ),
        child: Text('선택 완료', style: buttonTextStyle),
      ),
    );
  }

  /// 홈 화면으로 라우팅
  void _navigateToHomeScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (BuildContext context) => const HomeScreen(),
      ),
    );
  }
}
