import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 홈 탭 피드 로딩 스켈레톤
/// 실제 HomeFeedItemWidget 레이아웃을 그대로 반영:
///  - 전체화면 배경 이미지
///  - 우측 상단: 알림/메뉴 아이콘
///  - 우측 중간: 좋아요 버튼
///  - 하단: 페이지 인디케이터 + 아이템 정보 + 프로필
///  - 좌하단: 태그 칩들 + 제목 + 가격
class HomeTabSkeleton extends StatelessWidget {
  const HomeTabSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final double topOffset = topPadding + (Platform.isAndroid ? 16.h : 8.h);

    return SizedBox.expand(
      child: Stack(
        children: [
          // ─── 배경 전체 ───────────────────────────────────────
          Skeleton.leaf(
            child: Container(width: double.infinity, height: double.infinity, color: AppColors.secondaryBlack1),
          ),

          // ─── 우측 상단: 알림 + 메뉴 아이콘 ──────────────────
          Positioned(
            right: 16.w,
            top: topOffset,
            child: Row(
              children: [
                // 알림 아이콘
                Skeleton.leaf(
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: const BoxDecoration(color: AppColors.opacity20White, shape: BoxShape.circle),
                  ),
                ),
                SizedBox(width: 10.w),
                // 메뉴 아이콘
                Skeleton.leaf(
                  child: Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: const BoxDecoration(color: AppColors.opacity20White, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),

          // ─── 우측 중간: 좋아요 버튼 ──────────────────────────
          Positioned(
            right: 16.w,
            bottom: 200.h,
            child: Column(
              children: [
                // 좋아요 하트
                Skeleton.leaf(
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: const BoxDecoration(color: AppColors.opacity20White, shape: BoxShape.circle),
                  ),
                ),
                SizedBox(height: 4.h),
                // 좋아요 수
                Skeleton.leaf(
                  child: Container(width: 24.w, height: 12.h, color: AppColors.opacity20White),
                ),
              ],
            ),
          ),

          // ─── 하단 정보 영역 ───────────────────────────────────
          Positioned(
            left: 24.w,
            right: 70.w,
            bottom: 80.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 위치 + 날짜 행
                Row(
                  children: [
                    Skeleton.leaf(
                      child: Container(width: 12.w, height: 12.h, color: AppColors.opacity20White),
                    ),
                    SizedBox(width: 4.w),
                    Skeleton.leaf(
                      child: Container(width: 120.w, height: 12.h, color: AppColors.opacity20White),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                // 태그 칩 행
                Row(
                  children: [
                    _chip(60.w),
                    SizedBox(width: 6.w),
                    _chip(44.w),
                    SizedBox(width: 6.w),
                    _chip(52.w),
                    SizedBox(width: 6.w),
                    _chip(44.w),
                  ],
                ),
                SizedBox(height: 8.h),
                // 제목
                Skeleton.leaf(
                  child: Container(width: 180.w, height: 20.h, color: AppColors.opacity20White),
                ),
                SizedBox(height: 8.h),
                // 가격
                Skeleton.leaf(
                  child: Container(width: 100.w, height: 22.h, color: AppColors.opacity20White),
                ),
                SizedBox(height: 12.h),
                // 프로필 영역
                Row(
                  children: [
                    // 프로필 원형 이미지
                    Skeleton.leaf(
                      child: Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: const BoxDecoration(color: AppColors.opacity20White, shape: BoxShape.circle),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // AI 뱃지 자리
                    Skeleton.leaf(
                      child: Container(
                        width: 44.w,
                        height: 20.h,
                        decoration: BoxDecoration(
                          color: AppColors.opacity20White,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── 하단 페이지 인디케이터 ──────────────────────────
          Positioned(
            bottom: 56.h,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (i) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  child: Skeleton.leaf(
                    child: Container(
                      width: i == 0 ? 16.w : 6.w,
                      height: 6.h,
                      decoration: BoxDecoration(
                        color: i == 0 ? AppColors.opacity60White : AppColors.opacity20White,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(double width) {
    return Skeleton.leaf(
      child: Container(
        width: width,
        height: 22.h,
        decoration: BoxDecoration(color: AppColors.opacity20White, borderRadius: BorderRadius.circular(4.r)),
      ),
    );
  }
}
