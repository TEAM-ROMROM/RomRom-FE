import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 16),
              _OverviewCardSkeleton(),
              SizedBox(height: 16),
              _ExchangeCardSkeleton(),
              SizedBox(height: 16),
              _ReviewCardSkeleton(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCardSkeleton extends StatelessWidget {
  const _OverviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 35, backgroundColor: AppColors.opacity10White),
                SizedBox(width: 16),
                ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 120, height: 20)),
              ],
            ),
            SizedBox(height: 28),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.opacity10White,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: SizedBox(width: double.infinity, height: 44),
            ),
            SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.opacity10White,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: SizedBox(width: double.infinity, height: 44),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeCardSkeleton extends StatelessWidget {
  const _ExchangeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 20),
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 80, height: 16)),
            SizedBox(height: 19),
            Row(
              children: [
                _ItemCardSkeleton(),
                SizedBox(width: 12),
                _ItemCardSkeleton(),
                SizedBox(width: 12),
                _ItemCardSkeleton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCardSkeleton extends StatelessWidget {
  const _ItemCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.opacity10White,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          child: SizedBox(width: 100, height: 100),
        ),
        SizedBox(height: 8),
        ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 80, height: 14)),
        SizedBox(height: 8),
        ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 60, height: 12)),
        SizedBox(height: 6),
        ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 70, height: 11)),
      ],
    );
  }
}

class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10)),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 80, height: 16)),
            SizedBox(height: 16),
            _ReviewRowSkeleton(),
            SizedBox(height: 16),
            _ReviewRowSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _ReviewRowSkeleton extends StatelessWidget {
  const _ReviewRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        CircleAvatar(radius: 18, backgroundColor: AppColors.opacity10White),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 100, height: 13)),
            SizedBox(height: 6),
            ColoredBox(color: AppColors.opacity10White, child: SizedBox(width: 160, height: 11)),
          ],
        ),
      ],
    );
  }
}
