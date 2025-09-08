import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 내 물품 목록 스켈레톤 - SliverList 버전 (ListView 없음)
class RegisterTabSkeletonSliver extends StatelessWidget {
  const RegisterTabSkeletonSliver({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final int childCount =
        (itemCount * 2) - 1; // item, divider, item, divider ...

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index.isOdd) {
              // 구분선
              return Divider(
                thickness: 1.5,
                color: AppColors.opacity10White,
                height: 32.h,
              );
            }
            final tileIndex = index ~/ 2;
            return _SkeletonTile(index: tileIndex);
          },
          childCount: childCount,
        ),
      ),
    );
  }
}

/// 스켈레톤 타일 한 줄
class _SkeletonTile extends StatelessWidget {
  const _SkeletonTile({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: AppColors.opacity10White,
        highlightColor: AppColors.opacity30White,
      ),
      textBoneBorderRadius: const TextBoneBorderRadius.fromHeightFactor(.3),
      ignoreContainers: true,
      child: SizedBox(
        height: 90.h,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 이미지 썸네일
            Skeleton.leaf(
              child: Container(
                width: 90.w,
                height: 90.h,
                decoration: BoxDecoration(
                  color: AppColors.opacity20White,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
            SizedBox(width: 16.h),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Skeleton.leaf(
                    child: Text(
                      '물건 제목 $index',
                      style: CustomTextStyles.p1
                          .copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Skeleton.leaf(
                    child: Text(
                      '$index시간 전',
                      style: CustomTextStyles.p2
                          .copyWith(color: AppColors.opacity60White),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Skeleton.leaf(
                    child: Text(
                      '${formatPrice(10000)}원',
                      style: CustomTextStyles.p1,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Skeleton.leaf(
                    child: Row(
                      children: [
                        Icon(
                          AppIcons.itemRegisterHeart,
                          size: 14.sp,
                          color: AppColors.opacity60White,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '5',
                          style: CustomTextStyles.p2
                              .copyWith(color: AppColors.opacity60White),
                        ),
                      ],
                    ),
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
