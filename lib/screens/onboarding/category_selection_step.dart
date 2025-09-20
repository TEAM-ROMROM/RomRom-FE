import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

class CategorySelectionStep extends StatefulWidget {
  final VoidCallback onComplete;

  const CategorySelectionStep({super.key, required this.onComplete});

  @override
  State<CategorySelectionStep> createState() => _CategorySelectionStepState();
}

class _CategorySelectionStepState extends State<CategorySelectionStep> {
  final List<int> selectedCategories = [];
  final memberApi = MemberApi();

  bool get isSelectedCategories => selectedCategories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 32.h),
          // 카테고리 칩 표시
          Expanded(
            child: SingleChildScrollView(
              child: _buildCategoryChips(context),
            ),
          ),

          // 완료 버튼 - CategoryCompletionButton 위젯으로 변경
          Padding(
            padding: EdgeInsets.only(bottom: 48.h),
            child: Center(
              child: CompletionButton(
                isEnabled: isSelectedCategories,
                enabledOnPressed: () async {
                  try {
                    await memberApi.savePreferredCategories(selectedCategories);
                    widget.onComplete();
                  } catch (e) {
                    debugPrint("Error: $e");
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('카테고리 저장에 실패했습니다: $e')),
                      );
                    }
                  }
                },
                buttonText: '완료',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return Wrap(
      spacing: 8.0.w,
      runSpacing: 12.0.h,
      children: ItemCategories.values
          .map((category) => _buildCategoryChip(context, category))
          .toList(),
    );
  }

  Widget _buildCategoryChip(BuildContext context, ItemCategories category) {
    final bool isSelected = selectedCategories.contains(category.id);

    return RawChip(
      label: Text(
        category.label,
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
