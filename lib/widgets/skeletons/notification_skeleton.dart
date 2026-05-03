import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 알림 목록 스켈레톤
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(itemCount, (index) => _NotificationSkeletonItem(key: ValueKey(index))),
    );
  }
}

class _NotificationSkeletonItem extends StatelessWidget {
  const _NotificationSkeletonItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      textBoneBorderRadius: const TextBoneBorderRadius.fromHeightFactor(.3),
      ignoreContainers: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아이콘 원형
            Skeleton.leaf(
              child: Container(
                width: 40.w,
                height: 40.w,
                decoration: const BoxDecoration(color: AppColors.opacity20White, shape: BoxShape.circle),
              ),
            ),
            SizedBox(width: 12.w),
            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(
                    child: Text(
                      '알림 제목 텍스트가 여기에 표시됩니다',
                      style: CustomTextStyles.p2.copyWith(color: AppColors.opacity80White),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Skeleton.leaf(
                    child: Text('2시간 전', style: CustomTextStyles.p3.copyWith(color: AppColors.opacity40White)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
