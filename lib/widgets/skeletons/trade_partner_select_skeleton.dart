import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 거래 파트너 선택 초기 로딩 스켈레톤
class TradePartnerSelectSkeleton extends StatelessWidget {
  const TradePartnerSelectSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, _) => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              const Skeleton.leaf(child: CircleAvatar(radius: 22, backgroundColor: AppColors.opacity10White)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.leaf(
                      child: Container(width: width * 0.35, height: 13, color: AppColors.opacity10White),
                    ),
                    const SizedBox(height: 6),
                    Skeleton.leaf(
                      child: Container(width: width * 0.25, height: 11, color: AppColors.opacity10White),
                    ),
                  ],
                ),
              ),
              Skeleton.leaf(
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
