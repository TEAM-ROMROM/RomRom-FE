import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/screens/home_screen.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/category_completion_button.dart';
import 'package:romrom_fe/widgets/category_header.dart';

class CategorySelectionScreen extends StatefulWidget {
  const CategorySelectionScreen({super.key});

  @override
  State<CategorySelectionScreen> createState() =>
      _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  final memberApi = MemberApi();
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
                  await memberApi.savePreferredCategories(selectedCategories);
                  // 카테고리 선택 완료 후 홈화면 이동
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                  }
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
      runSpacing: 12.0.h,
      children: ItemCategories.values
          .map((category) => _buildCategoryChip(context, category))
          .toList(),
    );
  }

  /// 카테고리 chip css 일괄 지정
  Widget _buildCategoryChip(BuildContext context, ItemCategories category) {
    final bool isSelected = selectedCategories.contains(category.id);

    return RawChip(
      label: Text(
        category.name,
        style: CustomTextStyles.p2.copyWith(
          fontSize: adjustedFontSize(context, 14.0),
          color:
              isSelected ? AppColors.textColorBlack : AppColors.textColorWhite,
          wordSpacing: -0.32.w,
        ),
      ),
      labelPadding: EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: 16.0.w, vertical: 10.0.h),
      selected: isSelected,
      selectedColor: AppColors.primaryYellow,
      backgroundColor: AppColors.primaryBlack,
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color:
              isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
          strokeAlign: BorderSide.strokeAlignInside,
          width: 1.0.w,
        ),
        borderRadius: BorderRadiusDirectional.circular(100.r),
      ),
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
