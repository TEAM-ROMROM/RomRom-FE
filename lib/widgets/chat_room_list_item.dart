import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 채팅방 리스트 아이템 위젯
class ChatRoomListItem extends StatelessWidget {
  final String? accountStatus;
  final String? profileImageUrl;
  final String? memberId;
  final String nickname;
  final String location;
  final String timeAgo;
  final String messagePreview;
  final String? targetItemImageUrl;
  final String? myItemImageUrl;
  final int unreadCount;
  final bool isNew;
  final VoidCallback onTap;
  final VoidCallback? onProfileTap;

  const ChatRoomListItem({
    super.key,
    this.accountStatus,
    this.profileImageUrl,
    this.memberId,
    required this.nickname,
    required this.location,
    required this.timeAgo,
    required this.messagePreview,
    this.targetItemImageUrl,
    this.myItemImageUrl,
    this.unreadCount = 0,
    this.isNew = false,
    required this.onTap,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final double itemImageSize = 48.w;
    final double profileAvatarSize = 22.w;
    final bool isDeletedAccount = accountStatus == AccountStatus.deleteAccount.serverName;

    return AppPressable(
      onTap: onTap,
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Container(
        color: AppColors.transparent,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        child: Row(
          children: [
            // 왼쪽: 물품 이미지 + 우하단 프로필 아바타 오버레이
            Stack(
              clipBehavior: Clip.none,
              children: [
                SizedBox(
                  width: itemImageSize,
                  height: itemImageSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4.r),
                    child: targetItemImageUrl != null
                        ? CachedImage(
                            imageUrl: targetItemImageUrl!,
                            fit: BoxFit.cover,
                            errorWidget: Container(color: AppColors.imagePlaceholderBackground),
                          )
                        : Container(color: AppColors.imagePlaceholderBackground),
                  ),
                ),

                // 프로필 아바타 (22×22, 원형, 우하단 오버레이)
                Positioned(
                  right: -6.w,
                  bottom: -6.h,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryBlack, width: 2.w),
                    ),
                    child: GestureDetector(
                      onTap: onProfileTap,
                      child: UserProfileCircularAvatar(
                        avatarSize: Size(profileAvatarSize, profileAvatarSize),
                        profileUrl: profileImageUrl,
                        hasBorder: false,
                        isDeleteAccount: isDeletedAccount,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(width: 10.w),

            // 중앙 정보 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 첫 줄: 닉네임 • 장소 • 시간
                  Row(
                    children: [
                      Text(
                        isDeletedAccount ? '(탈퇴)$nickname' : nickname,
                        style: CustomTextStyles.p1.copyWith(
                          color: AppColors.textColorWhite,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      SizedBox(width: 8.h),

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
                      // 구분점
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

                  // 둘째 줄: 메시지 미리보기 + 내 물품 사진 + 읽지 않은 메시지 뱃지
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

                      // 읽지 않은 메시지 뱃지 (99 초과 시 '99+' 표시)
                      if (unreadCount > 0) ...[
                        Padding(
                          padding: EdgeInsets.only(right: 10.0.w, left: 8.w),
                          child: Container(
                            width: 16.w,
                            height: 16.h,
                            decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.chatUnreadBadge),
                            alignment: Alignment.center,
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: CustomTextStyles.p3.copyWith(
                                color: AppColors.textColorWhite,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // 오른쪽: 물품 이미지
            SizedBox(
              width: itemImageSize,
              height: itemImageSize,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: myItemImageUrl != null
                    ? CachedImage(
                        imageUrl: myItemImageUrl!,
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
