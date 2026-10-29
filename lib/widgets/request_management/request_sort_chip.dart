// 요청 목록 정렬 칩 (보더 pill 스타일) - 탭하면 정렬 선택 바텀시트 표시
import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/request_sort_bottom_sheet.dart';

class RequestSortChip extends StatelessWidget {
  final RequestSortType currentSort;
  final ValueChanged<RequestSortType> onChanged;

  const RequestSortChip({super.key, required this.currentSort, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => RequestSortBottomSheet.show(context: context, currentSort: currentSort, onSelected: onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.opacity50PrimaryYellow, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentSort.label,
              style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryYellow, size: 14),
          ],
        ),
      ),
    );
  }
}
