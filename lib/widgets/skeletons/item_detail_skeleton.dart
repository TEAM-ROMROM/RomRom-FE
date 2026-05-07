import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 물품 상세 초기 로딩 스켈레톤
class ItemDetailSkeleton extends StatelessWidget {
  const ItemDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Skeleton.leaf(child: SizedBox(width: 393, height: 300)),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Skeleton.leaf(child: CircleAvatar(radius: 20, backgroundColor: AppColors.opacity10White)),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.leaf(child: SizedBox(width: 80, height: 13)),
                      SizedBox(height: 6),
                      Skeleton.leaf(child: SizedBox(width: 55, height: 11)),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(child: SizedBox(width: 264, height: 18)),
                  SizedBox(height: 10),
                  Skeleton.leaf(child: SizedBox(width: 157, height: 16)),
                  SizedBox(height: 16),
                  Skeleton.leaf(child: SizedBox(width: 311, height: 12)),
                  SizedBox(height: 6),
                  Skeleton.leaf(child: SizedBox(width: 264, height: 12)),
                  SizedBox(height: 6),
                  Skeleton.leaf(child: SizedBox(width: 187, height: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
