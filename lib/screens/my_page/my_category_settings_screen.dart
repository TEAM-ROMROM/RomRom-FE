import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/common_app_bar.dart';

/// 선호 카테고리 설정 화면
class MyCategorySettingsScreen extends StatefulWidget {
  const MyCategorySettingsScreen({super.key});

  @override
  State<MyCategorySettingsScreen> createState() => _MyCategorySettingsScreenState();
}

class _MyCategorySettingsScreenState extends State<MyCategorySettingsScreen> {
  final List<int> selectedCategories = [];
  final memberApi = MemberApi();
  bool _isLoading = true;

  bool get isSelectedCategories => selectedCategories.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadPreferredCategories();
  }

  /// 기존 선호 카테고리 로드
  Future<void> _loadPreferredCategories() async {
    try {
      final memberResponse = await memberApi.getMemberInfo();
      final categories = memberResponse.memberItemCategories;
      if (categories != null && mounted) {
        setState(() {
          selectedCategories.clear();
          for (final category in categories) {
            if (category.itemCategory != null) {
              try {
                final itemCategory = ItemCategories.fromServerName(category.itemCategory!);
                selectedCategories.add(itemCategory.id);
              } catch (e) {
                debugPrint('카테고리 변환 실패: ${category.itemCategory}');
              }
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('선호 카테고리 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      appBar: CommonAppBar(title: '선호 카테고리 설정', showBottomBorder: true, onBackPressed: () => Navigator.pop(context)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.only(right: 24.0.w, left: 24.0.w, top: 56.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 1.h),
                  // 카테고리 칩 표시
                  SingleChildScrollView(child: _buildCategoryChips(context)),
                  Expanded(child: Container()),

                  // 저장하기 버튼
                  Padding(
                    padding: EdgeInsets.only(bottom: 76.h + MediaQuery.of(context).padding.bottom),
                    child: Center(
                      child: CompletionButton(
                        isEnabled: isSelectedCategories,
                        enabledOnPressed: () async {
                          try {
                            final isSuccess = await memberApi.savePreferredCategories(selectedCategories);

                            if (mounted && isSuccess) {
                              CommonSnackBar.show(
                                context: context,
                                message: '선호 카테고리가 저장되었습니다',
                                type: SnackBarType.success,
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            debugPrint('선호 카테고리 저장 실패: $e');
                            if (context.mounted) {
                              CommonSnackBar.show(
                                context: context,
                                message: '카테고리 저장에 실패했습니다: $e',
                                type: SnackBarType.error,
                              );
                            }
                          }
                        },
                        buttonText: '저장하기',
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    return Wrap(
      spacing: 8.0.w,
      runSpacing: 12.0.h,
      children: ItemCategories.values.map((category) => _buildCategoryChip(context, category)).toList(),
    );
  }

  Widget _buildCategoryChip(BuildContext context, ItemCategories category) {
    final bool isSelected = selectedCategories.contains(category.id);

    return RawChip(
      label: Text(
        category.label,
        style: CustomTextStyles.p2.copyWith(
          fontSize: adjustedFontSize(context, 14.0),
          color: isSelected ? AppColors.textColorBlack : AppColors.textColorWhite,
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
          color: isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
          strokeAlign: BorderSide.strokeAlignOutside,
          width: 1.0.w,
        ),
        borderRadius: BorderRadiusDirectional.circular(100.r),
      ),
      checkmarkColor: Colors.transparent,
      showCheckmark: false,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (bool selected) => _toggleCategorySelection(category.id, selected),
    );
  }

  void _toggleCategorySelection(int categoryId, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedCategories.add(categoryId);
      } else {
        selectedCategories.remove(categoryId);
      }
      debugPrint('선택 카테고리: $selectedCategories');
    });
  }
}
