import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:skeletonizer/skeletonizer.dart';

import 'package:romrom_fe/models/app_colors.dart';

class RegisterInputFormSkeleton extends StatelessWidget {
  const RegisterInputFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White),
      child: Padding(
        padding: EdgeInsets.only(right: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.h),
            // 이미지 업로드 영역
            const SkeletonRectanglar(),

            // 제목 필드
            Skeleton.keep(child: Text('제목', style: CustomTextStyles.p1)),
            SizedBox(height: 8.h),
            const SkeletonRectanglar(width: double.infinity, height: 46),

            // 카테고리 필드
            SizedBox(height: 20.h),
            Skeleton.keep(child: Text('카테고리', style: CustomTextStyles.p1)),
            SizedBox(height: 8.h),
            const SkeletonRectanglar(width: double.infinity, height: 46),

            // 물건 설명 필드
            Skeleton.keep(child: Text('물건 설명', style: CustomTextStyles.p1)),
            SizedBox(height: 8.h),
            const SkeletonRectanglar(width: double.infinity, height: 140),

            // 물건 상태 필드
            SizedBox(height: 20.h),
            Skeleton.keep(child: Text('물건 상태', style: CustomTextStyles.p1)),
            SizedBox(height: 16.h),
            const SkeletonRectanglar(width: double.infinity, height: 68),

            // 거래방식 필드
            Skeleton.keep(child: Text('거래방식', style: CustomTextStyles.p1)),
            SizedBox(height: 16.h),
            const SkeletonRectanglar(width: double.infinity, height: 30),

            // 적정 가격 필드
            Skeleton.keep(child: Text('적정 가격', style: CustomTextStyles.p1)),
            SizedBox(height: 8.h),
            const SkeletonRectanglar(width: double.infinity, height: 46),
          ],
        ),
      ),
    );
  }
}

class SkeletonRectanglar extends StatelessWidget {
  final double width;
  final double height;

  const SkeletonRectanglar({super.key, this.width = 80, this.height = 80});

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: width.w,
        height: height.h,
        decoration: BoxDecoration(
          color: AppColors.opacity20White,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.opacity30White, width: 1.5.w),
        ),
        margin: EdgeInsets.only(bottom: 24.h),
      ),
    );
  }
}
