import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 홈 피드 초기 로딩 스켈레톤 — PageView 전체화면 shimmer
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      child: Container(
        width: width,
        height: height,
        color: AppColors.primaryBlack,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton.leaf(
              child: Container(width: width, height: height * 0.6, color: AppColors.opacity10White),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(
                    child: Container(width: width * 0.55, height: 18, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 10),
                  Skeleton.leaf(
                    child: Container(width: width * 0.35, height: 15, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 10),
                  Skeleton.leaf(
                    child: Container(width: width * 0.45, height: 13, color: AppColors.opacity10White),
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
