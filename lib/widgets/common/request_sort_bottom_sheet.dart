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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // 드래그 핸들
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppColors.opacity30White, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // "정렬" 레이블
          Text('정렬', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x1AFFFFFF)),
          // 옵션 목록
          ...RequestSortType.values.map((type) => _buildOption(context, type)),
          const SizedBox(height: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0x1AFFFFFF), width: 1)),
        ),
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
