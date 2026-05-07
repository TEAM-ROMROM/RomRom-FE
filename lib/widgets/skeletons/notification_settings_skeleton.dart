import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 알림 설정 초기 로딩 스켈레톤
class NotificationSettingsSkeleton extends StatelessWidget {
  const NotificationSettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(children: [_buildGroup(width, 4), const SizedBox(height: 16), _buildGroup(width, 1)]),
    );
  }

  Widget _buildGroup(double width, int rowCount) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF34353D), borderRadius: BorderRadius.circular(10)),
      child: Column(children: List.generate(rowCount, (i) => _buildRow(width, i, rowCount))),
    );
  }

  Widget _buildRow(double width, int index, int total) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      child: SizedBox(
        height: 74,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.leaf(
                      child: Container(width: width * 0.35, height: 13, color: AppColors.opacity10White),
                    ),
                    const SizedBox(height: 8),
                    Skeleton.leaf(
                      child: Container(width: width * 0.55, height: 11, color: AppColors.opacity10White),
                    ),
                  ],
                ),
              ),
              Skeleton.leaf(
                child: Container(
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
