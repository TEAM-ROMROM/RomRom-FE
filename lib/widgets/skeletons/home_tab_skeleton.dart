import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 홈 탭 피드 로딩 스켈레톤
///
/// 단순하게 3개 덩어리:
///  1. 전체 배경 shimmer
///  2. 하단 텍스트 블록 (제목/태그/가격 영역)
///  3. 하단 카드 덱 어두운 영역
class HomeTabSkeleton extends StatelessWidget {
  const HomeTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // 1. 전체 배경
          Skeleton.leaf(
            child: Container(width: double.infinity, height: double.infinity, color: AppColors.secondaryBlack1),
          ),

          // 2. 하단 텍스트 블록 — 제목/태그/가격 영역 하나의 둥근 사각형
          Positioned(
            left: 24.w,
            right: 80.w,
            bottom: 170.h,
            child: Skeleton.leaf(
              child: Container(
                height: 130.h,
                decoration: BoxDecoration(color: AppColors.opacity20White, borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),

          // 3. 하단 카드 덱 영역 — 화면 하단 어두운 블록
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Skeleton.leaf(
              child: Container(height: 150.h, color: AppColors.opacity20Black),
            ),
          ),
        ],
      ),
    );
  }
}
