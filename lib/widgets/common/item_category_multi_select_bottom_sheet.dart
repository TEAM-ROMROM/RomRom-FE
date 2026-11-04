// 카테고리 복수 선택 바텀시트: 손잡이, 제목·선택 수, 카테고리 칩 목록(최대 개수 제한 선택), 초기화·완료 버튼
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/category_chip.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 물품 등록 희망 교환 카테고리(최대 3개)·검색 카테고리 필터(제한 없음) 공통
class ItemCategoryMultiSelectBottomSheet extends StatefulWidget {
  final String title;
  final List<ItemCategories> initialCategories;
  // null > 개수 제한 없음
  final int? maximumSelectionCount;

  const ItemCategoryMultiSelectBottomSheet({
    super.key,
    required this.title,
    required this.initialCategories,
    this.maximumSelectionCount,
  });

  /// 바텀시트 표시 > 완료 시 고른 카테고리 (선택 순서 유지), 완료 없이 닫으면 null
  static Future<List<ItemCategories>?> show({
    required BuildContext context,
    required String title,
    required List<ItemCategories> initialCategories,
    int? maximumSelectionCount,
  }) {
    return showModalBottomSheet<List<ItemCategories>>(
      context: context,
      backgroundColor: AppColors.primaryBlack,
      barrierColor: AppColors.opacity80Black,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (_) => ItemCategoryMultiSelectBottomSheet(
        title: title,
        initialCategories: initialCategories,
        maximumSelectionCount: maximumSelectionCount,
      ),
    );
  }

  @override
  State<ItemCategoryMultiSelectBottomSheet> createState() => _ItemCategoryMultiSelectBottomSheetState();
}

class _ItemCategoryMultiSelectBottomSheetState extends State<ItemCategoryMultiSelectBottomSheet> {
  late final List<ItemCategories> _selectedCategories = List.of(widget.initialCategories);

  /// 칩 탭 > 선택 토글 (최대 개수 도달 시 추가 대신 안내)
  void _onCategoryTap(ItemCategories category) {
    if (_selectedCategories.contains(category)) {
      setState(() => _selectedCategories.remove(category));
      return;
    }
    final maximumSelectionCount = widget.maximumSelectionCount;
    if (maximumSelectionCount != null && _selectedCategories.length >= maximumSelectionCount) {
      CommonSnackBar.show(context: context, message: '최대 $maximumSelectionCount개까지 고를 수 있어요', type: SnackBarType.info);
      return;
    }
    setState(() => _selectedCategories.add(category));
  }

  @override
  Widget build(BuildContext context) {
    final maximumSelectionCount = widget.maximumSelectionCount;
    final selectionCountText = maximumSelectionCount != null
        ? '${_selectedCategories.length}/$maximumSelectionCount'
        : '${_selectedCategories.length}개 선택';
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Container(
                width: 50,
                height: 4,
                decoration: BoxDecoration(color: AppColors.opacity50White, borderRadius: BorderRadius.circular(5)),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 26.w),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.title, style: CustomTextStyles.h2.copyWith(fontWeight: FontWeight.w700)),
                ),
                Text(selectionCountText, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(right: 24.w, left: 24.w, top: 24.h, bottom: 12.h),
              child: Wrap(
                spacing: 8.0.w,
                runSpacing: 12.0.h,
                children: [
                  for (final category in ItemCategories.values)
                    CategoryChip(
                      label: category.label,
                      isSelected: _selectedCategories.contains(category),
                      onTap: () => _onCategoryTap(category),
                      iconPath: category.iconPath,
                    ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 8, 24.w, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _selectedCategories.isEmpty ? null : () => setState(_selectedCategories.clear),
                    child: Text('초기화', style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: CompletionButton(
                      isEnabled: true,
                      buttonText: '완료',
                      enabledOnPressed: () => Navigator.of(context).pop(List<ItemCategories>.of(_selectedCategories)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
