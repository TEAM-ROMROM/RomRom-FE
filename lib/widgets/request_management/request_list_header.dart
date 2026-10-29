// 요청 목록 헤더 (제목 + 정렬 칩 + 완료 포함 토글) - 받은 요청 탭에서만 표시
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completed_toggle_switch.dart';
import 'package:romrom_fe/widgets/request_management/request_sort_chip.dart';

class RequestListHeader extends StatelessWidget {
  final bool isRightSelected;
  final RequestSortType currentSort;
  final bool showCompletedRequests;
  final ValueChanged<RequestSortType> onSortChanged;
  final ValueChanged<bool> onToggleCompleted;

  const RequestListHeader({
    super.key,
    required this.isRightSelected,
    required this.currentSort,
    required this.showCompletedRequests,
    required this.onSortChanged,
    required this.onToggleCompleted,
  });

  @override
  Widget build(BuildContext context) {
    // 보낸 요청에서는 헤더 표시 안함
    if (isRightSelected) {
      return const SizedBox.shrink();
    }

    // 받은 요청에서만 헤더 표시
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 토글을 한 줄에 배치
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 제목
              Text('요청 목록', style: CustomTextStyles.h3),
              // 정렬 칩 (보더 pill) + 완료 표시 토글
              Row(
                children: [
                  RequestSortChip(currentSort: currentSort, onChanged: onSortChanged),
                  const SizedBox(width: 12),
                  Text(
                    '완료 포함',
                    style: CustomTextStyles.p3.copyWith(
                      color: AppColors.opacity50White,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5.sp,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  CompletedToggleSwitch(value: showCompletedRequests, onChanged: onToggleCompleted),
                ],
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // 설명 텍스트
          Text('내 물품에 온 교환 요청이에요', style: CustomTextStyles.p2.copyWith(color: AppColors.requestManagementDescription)),
        ],
      ),
    );
  }
}
