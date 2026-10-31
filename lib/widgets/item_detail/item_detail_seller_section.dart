// 물품 상세 판매자 행: 프로필 사진, 닉네임, 회원 위치, 좋아요 버튼·개수
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class ItemDetailSellerSection extends StatelessWidget {
  final String? profileUrl;
  final bool isDeletedAccount;
  final String? nickname;
  final String memberLocationName;
  // 요청 관리에서 연 타인 물품: 닉네임 영역 최대 폭 제한
  final bool shouldLimitNicknameWidth;
  final bool isLiked;
  final int likeCount;
  final VoidCallback onProfileTap;
  final VoidCallback onLikeTap;

  const ItemDetailSellerSection({
    super.key,
    required this.profileUrl,
    required this.isDeletedAccount,
    required this.nickname,
    required this.memberLocationName,
    required this.shouldLimitNicknameWidth,
    required this.isLiked,
    required this.likeCount,
    required this.onProfileTap,
    required this.onLikeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          GestureDetector(
            onTap: onProfileTap,
            child: UserProfileCircularAvatar(
              avatarSize: const Size(40, 40),
              profileUrl: profileUrl,
              isDeleteAccount: isDeletedAccount,
            ),
          ),
          SizedBox(width: 10.w),
          GestureDetector(onTap: onProfileTap, child: _buildNicknameAndLocation()),
          const Spacer(),
          Column(
            children: [
              _buildLikeButton(),
              SizedBox(height: 2.h),
              Text(likeCount.toString(), style: CustomTextStyles.p2),
            ],
          ),
        ],
      ),
    );
  }

  /// 닉네임 + 회원 위치 (닉네임 없으면 '알 수 없음')
  Widget _buildNicknameAndLocation() {
    return Container(
      constraints: shouldLimitNicknameWidth ? BoxConstraints(maxWidth: 120.w) : null, // 최대 너비 설정
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(nickname ?? '알 수 없음', style: CustomTextStyles.p2, overflow: TextOverflow.ellipsis),
          SizedBox(height: 8.h),
          Text(
            memberLocationName,
            style: CustomTextStyles.p3.copyWith(
              color: AppColors.lightGray.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 좋아요 하트 버튼 (보이는 크기 32, 터치·리플 캔버스 56)
  Widget _buildLikeButton() {
    return SizedBox.square(
      dimension: 32.w,
      child: OverflowBox(
        maxWidth: 56.w,
        maxHeight: 56.w,
        child: Material(
          color: AppColors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkResponse(
            onTap: onLikeTap,
            radius: 18.w,
            customBorder: const CircleBorder(),
            highlightColor: AppColors.buttonHighlightColorGray,
            splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
            child: SizedBox.square(
              dimension: 56.w, // 리플/터치 캔버스
              child: Center(
                child: SizedBox.square(
                  dimension: 30.w,
                  child: SvgPicture.asset(
                    isLiked ? 'assets/images/like-heart-icon.svg' : 'assets/images/dislike-heart-icon.svg',
                    width: 30.w,
                    height: 30.h,
                    semanticsLabel: isLiked ? '좋아요 취소' : '좋아요',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
