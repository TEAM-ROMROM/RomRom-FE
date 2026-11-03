// 교환 상대 선택 행: 상대 물품 이미지·프로필, 닉네임(탈퇴 표시)·동네·시각, 마지막 메시지 (선택 시 노란 강조)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class TradePartnerRow extends StatelessWidget {
  final ChatRoomDetailDto room;
  final bool isSelected;
  // 탈퇴 상대 (닉네임 앞 '(탈퇴)', 탈퇴 아바타)
  final bool isDeletedPartner;

  const TradePartnerRow({super.key, required this.room, required this.isSelected, required this.isDeletedPartner});

  @override
  Widget build(BuildContext context) {
    final member = room.targetMember;
    final nickname = isDeletedPartner ? '(탈퇴)${member?.nickname ?? ''}' : member?.nickname ?? '알 수 없음';
    final location = room.targetMemberEupMyeonDong ?? '';
    // 채팅 목록과 같은 날짜 기준 표시 (오늘 시각·어제·날짜)
    final timeAgo = formatListTimestamp(room.lastMessageTime);
    final messagePreview = room.lastMessageContent ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: 16.h, left: 12.w, right: 12.w),
      padding: EdgeInsets.only(bottom: 14.h, left: 16.w, top: 16.h, right: 16.w),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryYellow.withValues(alpha: 0.1) : AppColors.primaryBlack,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected ? AppColors.primaryYellow.withValues(alpha: 0.3) : AppColors.transparent,
          width: 1.w,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Row(
        children: [
          // 물품 이미지 + 프로필 오버레이
          Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                width: 48.w,
                height: 48.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: room.targetItemImageUrl != null
                      ? CachedImage(
                          imageUrl: room.targetItemImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: Container(color: AppColors.imagePlaceholderBackground),
                        )
                      : Container(color: AppColors.imagePlaceholderBackground),
                ),
              ),
              Positioned(
                right: -4.w,
                bottom: -4.h,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.secondaryBlack1, width: 2.w),
                  ),
                  child: UserProfileCircularAvatar(
                    avatarSize: Size(22.w, 22.w),
                    profileUrl: member?.profileUrl,
                    hasBorder: false,
                    isDeleteAccount: isDeletedPartner,
                  ),
                ),
              ),
            ],
          ),

          // 가로 간격
          SizedBox(width: 10.w),

          // 닉네임 + 위치 + 시간 + 채팅내용
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        nickname,
                        style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (location.isNotEmpty || timeAgo.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Text(
                        location,
                        style: CustomTextStyles.p3.copyWith(
                          color: AppColors.chatLocationTimeMessage,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Container(
                        width: 2.w,
                        height: 2.w,
                        margin: EdgeInsets.symmetric(horizontal: 2.w),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.chatLocationTimeMessage,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: CustomTextStyles.p3.copyWith(
                          color: AppColors.chatLocationTimeMessage,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                if (messagePreview.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    messagePreview,
                    style: CustomTextStyles.p2.copyWith(
                      color: AppColors.chatLocationTimeMessage,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
