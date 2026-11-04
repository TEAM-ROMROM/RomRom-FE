// 물품 검색 필터 줄: 카테고리 선택 칩(선택 수 표시), 정렬 칩 4개 (가로 스크롤)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_search_sort_field.dart';
import 'package:romrom_fe/widgets/register_option_chip.dart';

class ItemSearchFilterBar extends StatelessWidget {
  final List<ItemCategories> selectedCategories;
  final ItemSearchSortField selectedSortField;
  final VoidCallback onCategoryFilterTap;
  final ValueChanged<ItemSearchSortField> onSortFieldSelected;

  const ItemSearchFilterBar({
    super.key,
    required this.selectedCategories,
    required this.selectedSortField,
    required this.onCategoryFilterTap,
    required this.onSortFieldSelected,
  });

  @override
  Widget build(BuildContext context) {
    final categoryChipLabel = selectedCategories.isEmpty ? '카테고리 전체' : '카테고리 ${selectedCategories.length}';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        children: [
          RegisterOptionChip(
            itemOption: categoryChipLabel,
            isSelected: selectedCategories.isNotEmpty,
            onTap: onCategoryFilterTap,
          ),
          SizedBox(width: 12.w),
          for (final sortField in ItemSearchSortField.values) ...[
            RegisterOptionChip(
              itemOption: sortField.label,
              isSelected: sortField == selectedSortField,
              onTap: () => onSortFieldSelected(sortField),
            ),
            SizedBox(width: 8.w),
          ],
        ],
      ),
    );
  }
}
