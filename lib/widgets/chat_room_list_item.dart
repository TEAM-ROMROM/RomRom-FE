import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 채팅방 리스트 아이템 위젯
class ChatRoomListItem extends StatelessWidget {
  final String? profileImageUrl;
  final String? memberId;
  final String nickname;
  final String location;
  final String timeAgo;
  final String messagePreview;
  final String? targetItemImageUrl;
  final int unreadCount;
  final bool isNew;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;

  const ChatRoomListItem({
    super.key,
    this.profileImageUrl,
    this.memberId,
    required this.nickname,
    required this.location,
    required this.timeAgo,
    required this.messagePreview,
    this.targetItemImageUrl,
    this.unreadCount = 0,
    this.isNew = false,
    required this.onTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: AppColors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          children: [
            // 1. 프로필 이미지 (40×40, 원형)
            GestureDetector(
              onTap: onProfileTap,
              child: UserProfileCircularAvatar(
                avatarSize: Size(40.w, 40.h),
                profileUrl: profileImageUrl,
                hasBorder: true,
              ),
            ),

            SizedBox(width: 16.w),

            // 2. 중앙 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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

                      SizedBox(width: 8.h),

                      // 둘째 줄: 장소 • 시간
                      // 장소
                      Text(
                        location,
                        style: CustomTextStyles.p3.copyWith(
                          color: AppColors.chatLocationTimeMessage,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 2.w),
                      // 중간점
                      Container(
                        width: 2.w,
                        height: 2.h,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.chatLocationTimeMessage,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      // 시간
                      Text(
                        timeAgo,
                        style: CustomTextStyles.p3.copyWith(
                          color: AppColors.chatLocationTimeMessage,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 7.h),

                  // 셋째 줄: 메시지 미리보기
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          messagePreview,
                          style: CustomTextStyles.p2.copyWith(color: AppColors.chatLocationTimeMessage),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 3. 읽지 않은 메시지 뱃지
                      if (unreadCount > 0) ...[
                        Padding(
                          padding: EdgeInsets.only(right: 10.0.w, left: 8.w),
                          child: Container(
                            width: 16.w,
                            height: 16.h,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.chatUnreadBadge),
                            alignment: Alignment.center,
                            child: Text(
                              // 99 초과 시 '99+' 표시
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: CustomTextStyles.p3.copyWith(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 40.w,
              height: 40.w,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: targetItemImageUrl != null
                    ? CachedImage(
                        imageUrl: targetItemImageUrl!,
                        fit: BoxFit.cover,

                        errorWidget: Container(color: AppColors.imagePlaceholderBackground),
                      )
                    : Container(color: AppColors.imagePlaceholderBackground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
