import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 채팅방 리스트 아이템 위젯
class ChatRoomListItem extends StatelessWidget {
  final String? profileImageUrl;
  final String nickname;
  final String location;
  final String timeAgo;
  final String messagePreview;
  final int unreadCount;
  final bool isNew;
  final VoidCallback onTap;

  const ChatRoomListItem({
    super.key,
    this.profileImageUrl,
    required this.nickname,
    required this.location,
    required this.timeAgo,
    required this.messagePreview,
    this.unreadCount = 0,
    this.isNew = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            // 1. 프로필 이미지 (48×48, 원형)
            UserProfileCircularAvatar(
              avatarSize: Size(48.w, 48.h),
              profileUrl: profileImageUrl,
            ),

            SizedBox(width: 12.w),

            // 2. 중앙 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 첫 줄: 닉네임
                  Text(
                    nickname,
                    style: CustomTextStyles.p1.copyWith(
                      color: AppColors.textColorWhite,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 4.h),

                  // 둘째 줄: 장소 • 시간
                  Row(
                    children: [
                      // 장소
                      Flexible(
                        child: Text(
                          location,
                          style: CustomTextStyles.p3.copyWith(
                            color: AppColors.chatLocationTimeMessage,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // 중간점
                      Container(
                        width: 2.w,
                        height: 2.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.chatLocationTimeMessage,
                        ),
                      ),
                      SizedBox(width: 4.w),
                      // 시간
                      Text(
                        timeAgo,
                        style: CustomTextStyles.p3.copyWith(
                          color: AppColors.chatLocationTimeMessage,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // 셋째 줄: 메시지 미리보기
                  Text(
                    messagePreview,
                    style: CustomTextStyles.p2.copyWith(
                      color: AppColors.chatLocationTimeMessage,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 3. 읽지 않은 메시지 뱃지
            if (unreadCount > 0) ...[
              SizedBox(width: 12.w),
              Container(
                width: 20.w,
                height: 20.h,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.chatUnreadBadge,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: CustomTextStyles.p3.copyWith(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

