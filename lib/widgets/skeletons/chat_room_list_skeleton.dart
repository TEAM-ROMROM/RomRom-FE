import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 채팅방 리스트 스켈레톤 - SliverList 버전
class ChatRoomListSkeletonSliver extends StatelessWidget {
  const ChatRoomListSkeletonSliver({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Column(
            children: [
              const _SkeletonChatRoomItem(),
              SizedBox(height: 8.h),
            ],
          );
        },
        childCount: itemCount,
      ),
    );
  }
}

/// 스켈레톤 채팅방 아이템 한 줄
class _SkeletonChatRoomItem extends StatelessWidget {
  const _SkeletonChatRoomItem();

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
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            // 프로필 이미지 (원형, 40×40)
            Skeleton.leaf(
              child: Container(
                width: 40.w,
                height: 40.h,
                decoration: const BoxDecoration(
                  color: AppColors.opacity20White,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            SizedBox(width: 12.w),

            // 텍스트 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 첫 줄: 닉네임 + 위치 + 시간
                  Row(
                    children: [
                      Skeleton.leaf(
                        child: Text(
                          '닉네임',
                          style: CustomTextStyles.p1.copyWith(
                            color: AppColors.textColorWhite,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Skeleton.leaf(
                        child: Text(
                          '화양동',
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.chatLocationTimeMessage,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Skeleton.leaf(
                        child: Container(
                          width: 2.w,
                          height: 2.h,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.chatLocationTimeMessage,
                          ),
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Skeleton.leaf(
                        child: Text(
                          '2시간 전',
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.chatLocationTimeMessage,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 7.h),

                  // 메시지 미리보기
                  Skeleton.leaf(
                    child: Text(
                      '채팅 메시지 미리보기입니다',
                      style: CustomTextStyles.p2.copyWith(
                        color: AppColors.chatLocationTimeMessage,
                      ),
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
