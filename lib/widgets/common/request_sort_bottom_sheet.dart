import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RequestSortBottomSheet {
  const RequestSortBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required RequestSortType currentSort,
    required ValueChanged<RequestSortType> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSortSheet(currentSort: currentSort, onSelected: onSelected),
    );
  }
}

class _RequestSortSheet extends StatelessWidget {
  final RequestSortType currentSort;
  final ValueChanged<RequestSortType> onSelected;

  const _RequestSortSheet({required this.currentSort, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: AppColors.opacity30White, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          // "정렬" 제목 — 좌측 정렬, 굵게
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '정렬',
              style: CustomTextStyles.p1.copyWith(color: AppColors.textColorWhite, fontWeight: FontWeight.w600),
            ),
          ),
          // 옵션 목록 — 디바이더 없음
          ...RequestSortType.values.map((type) => _buildOption(context, type)),
          SizedBox(height: 16 + bottomInset),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, RequestSortType type) {
    final isSelected = type == currentSort;
    return InkWell(
      onTap: () {
        onSelected(type);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type.label,
              style: CustomTextStyles.p1.copyWith(
                color: isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: AppColors.primaryYellow, size: 18),
          ],
        ),
      ),
    );
  }
}
