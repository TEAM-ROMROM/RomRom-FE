import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 찜 목록 초기 로딩 스켈레톤
class MyLikeListSkeleton extends StatelessWidget {
  const MyLikeListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(color: AppColors.opacity10White, thickness: 1.5),
      itemBuilder: (_, _) => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Skeleton.leaf(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(
                    child: Container(width: width * 0.45, height: 13, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 6),
                  Skeleton.leaf(
                    child: Container(width: width * 0.3, height: 11, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 6),
                  Skeleton.leaf(
                    child: Container(width: width * 0.55, height: 11, color: AppColors.opacity10White),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
