// 홈 피드 카드 좋아요 버튼: 하트(눌림 상태별 아이콘, 탭 시 spring 튕김 + 햅틱), 56px 터치·리플 영역, 좋아요 수(바뀔 때 위아래 슬라이드)
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 홈 피드 좋아요 버튼: 좋아요 여부·수 표시, 탭 동작은 상위 콜백
class HomeFeedItemLikeButton extends StatefulWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback onTap;

  const HomeFeedItemLikeButton({super.key, required this.isLiked, required this.likeCount, required this.onTap});

  // 탭 순간 하트에 주는 확대 속도 (배율/s, pressSpring 기준 최대 약 1.2배 > 약 300ms 안에 1.0 정착)
  static const double heartBounceVelocityPerSecond = 9.5;

  // 좋아요 수 슬라이드 이동량 (글자 높이 대비 비율)
  static const double countSlideOffsetFraction = 0.6;

  @override
  State<HomeFeedItemLikeButton> createState() => _HomeFeedItemLikeButtonState();
}

class _HomeFeedItemLikeButtonState extends State<HomeFeedItemLikeButton> with SingleTickerProviderStateMixin {
  // 하트 확대량 (0 = 원래 크기, 표시 배율 = 1 + 값), unbounded: spring 넘침 허용
  late final AnimationController _heartBounceController;

  // 좋아요 수 증가 여부 (증가: 아래에서 위로, 감소: 위에서 아래로 슬라이드)
  bool _isCountIncreasing = true;

  @override
  void initState() {
    super.initState();
    _heartBounceController = AnimationController.unbounded(vsync: this);
  }

  @override
  void didUpdateWidget(HomeFeedItemLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.likeCount != oldWidget.likeCount) {
      _isCountIncreasing = widget.likeCount > oldWidget.likeCount;
    }
  }

  @override
  void dispose() {
    _heartBounceController.dispose();
    super.dispose();
  }

  /// 탭: 햅틱 > 현재 크기에서 확대 속도를 주고 spring 복귀 (연타해도 끊김 없이 이어짐) > 상위 콜백
  void _onHeartTapped() {
    HapticFeedback.lightImpact();
    _heartBounceController.animateWith(
      SpringSimulation(
        AppMotion.pressSpring,
        _heartBounceController.value,
        0.0,
        HomeFeedItemLikeButton.heartBounceVelocityPerSecond,
        snapToEnd: true,
      ),
    );
    widget.onTap();
  }

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
                onTap: _onHeartTapped,
                customBorder: const CircleBorder(),
                highlightColor: AppColors.buttonHighlightColorGray,
                splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                child: SizedBox.square(
                  dimension: 56.w, // 리플/터치 캔버스
                  child: Center(
                    // 하트 크기만 프레임마다 갱신 (아이콘 재빌드 없음)
                    child: ScaleTransition(
                      scale: _heartBounceController.drive(Tween<double>(begin: 1.0, end: 2.0)),
                      child: SizedBox.square(
                        dimension: 30.w,
                        child: SvgPicture.asset(
                          widget.isLiked ? 'assets/images/like-heart-icon.svg' : 'assets/images/dislike-heart-icon.svg',
                          fit: BoxFit.contain,
                          semanticsLabel: widget.isLiked ? '좋아요 취소' : '좋아요',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        _buildLikeCount(),
      ],
    );
  }

  /// 좋아요 수: 바뀔 때 새 숫자는 들어오고 이전 숫자는 반대쪽으로 빠지며 페이드 (글자 줄 밖은 잘라냄)
  Widget _buildLikeCount() {
    final double slideDirection = _isCountIncreasing ? 1.0 : -1.0;
    final ValueKey<int> currentCountKey = ValueKey<int>(widget.likeCount);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: AppMotion.fast,
        switchInCurve: AppMotion.entry,
        switchOutCurve: AppMotion.accelerate,
        transitionBuilder: (countChild, animation) {
          // 새 숫자: 증가 시 아래에서 / 이전 숫자: 증가 시 위로 빠짐 (나가는 쪽은 animation 역재생)
          final bool isIncomingCount = countChild.key == currentCountKey;
          final double hiddenOffsetY =
              (isIncomingCount ? slideDirection : -slideDirection) * HomeFeedItemLikeButton.countSlideOffsetFraction;
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: Offset(0, hiddenOffsetY), end: Offset.zero).animate(animation),
              child: countChild,
            ),
          );
        },
        child: Text(widget.likeCount.toString(), key: currentCountKey, style: CustomTextStyles.p2),
      ),
    );
  }
}
