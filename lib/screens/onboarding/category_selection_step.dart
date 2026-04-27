import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/widgets/common/category_chip.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
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
  bool _isSaving = false;

  bool get isSelectedCategories => selectedCategories.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 1.h),
              // 카테고리 칩 표시
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 180.h + MediaQuery.of(context).padding.bottom),
                  child: _buildCategoryChips(context),
                ),
              ),
            ],
          ),
        ),

        // 완료 버튼 - CategoryCompletionButton 위젯으로 변경
        Positioned(
          left: 24.w,
          right: 24.w,
          bottom: 63.h + MediaQuery.of(context).padding.bottom,
          child: Center(
            child: CompletionButton(
              isEnabled: isSelectedCategories,
              isLoading: _isSaving,
              enabledOnPressed: () async {
                if (_isSaving) return;
                setState(() => _isSaving = true);
                try {
                  await memberApi.savePreferredCategories(selectedCategories);

                  // 온보딩 완료 시 코치마크 미표시 상태로 초기화
                  final userInfo = UserInfo();
                  await userInfo.getUserInfo();
                  await userInfo.saveLoginStatus(
                    isFirstLogin: userInfo.isFirstLogin ?? true,
                    isFirstItemPosted: userInfo.isFirstItemPosted ?? false,
                    isItemCategorySaved: true, // 카테고리 저장 완료 상태로 설정
                    isMemberLocationSaved: userInfo.isMemberLocationSaved ?? false,
                    isMarketingInfoAgreed: userInfo.isMarketingInfoAgreed ?? false,
                    isRequiredTermsAgreed: userInfo.isRequiredTermsAgreed ?? false,
                    isCoachMarkShown: false, // 명시적으로 false 설정
                  );
                  debugPrint('온보딩 완료: isItemCategorySaved=true, isCoachMarkShown=false로 설정됨');

                  // FCM 토큰 발급 및 저장
                  await FirebaseService().handleFcmToken();

                  await RomAuthApi().fetchAndSaveMemberInfo();
                  widget.onComplete();
                } catch (e) {
                  debugPrint("Error: $e");
                  if (mounted) {
                    CommonSnackBar.show(context: context, message: '카테고리 저장에 실패했습니다: $e', type: SnackBarType.error);
                  }
                } finally {
                  if (mounted) {
                    setState(() => _isSaving = false);
                  }
                }
              },
              buttonText: '완료',
            ),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          child: IgnorePointer(
            child: Container(
              height: 161.h,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 1],
                  colors: [AppColors.primaryBlack.withValues(alpha: 0.0), AppColors.primaryBlack],
                ),
              ),
            ),
          ),
        ),
      ],
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
    return CategoryChip(
      label: category.label,
      isSelected: selectedCategories.contains(category.id),
      onTap: () => _toggleCategorySelection(category.id, !selectedCategories.contains(category.id)),
      iconPath: category.iconPath,
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
