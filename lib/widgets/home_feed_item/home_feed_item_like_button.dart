// 홈 피드 카드 좋아요 버튼: 하트(눌림 상태별 아이콘), 56px 터치·리플 영역, 좋아요 수
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 홈 피드 좋아요 버튼: 좋아요 여부·수 표시, 탭 동작은 상위 콜백
class HomeFeedItemLikeButton extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const HomeFeedItemLikeButton({super.key, required this.isLiked, required this.likeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox.square(
          dimension: 32.w,
          child: OverflowBox(
            maxWidth: 56.w,
            maxHeight: 56.w,
            child: Material(
              color: AppColors.transparent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkResponse(
                radius: 18.w,
                containedInkWell: false,
                onTap: onTap,
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
                        fit: BoxFit.contain,
                        semanticsLabel: isLiked ? '좋아요 취소' : '좋아요',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        Text(likeCount.toString(), style: CustomTextStyles.p2),
      ],
    );
  }
}
