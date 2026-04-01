import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

/// 알림 바텀시트 채팅 - 알림 미리보기 위젯
class NotificationBotomSheetChattingPreview extends StatelessWidget {
  const NotificationBotomSheetChattingPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 59),
      child: _NotificationBottomSheetChattingCardAnimation(),
    );
  }
}

/// 알림 shadow1 → shadow2 → 카드 순차 slide+fadeIn 애니메이션
class _NotificationBottomSheetChattingCardAnimation extends StatefulWidget {
  const _NotificationBottomSheetChattingCardAnimation();

  @override
  State<_NotificationBottomSheetChattingCardAnimation> createState() => _NotificationBottomSheetCardAnimationState();
}

class _NotificationBottomSheetCardAnimationState extends State<_NotificationBottomSheetChattingCardAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _shadow1Controller;
  late final AnimationController _shadow2Controller;
  late final AnimationController _cardController;
  late final Animation<double> _shadow1Fade;
  late final Animation<double> _shadow2Fade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _shadow1Slide;
  late final Animation<Offset> _shadow2Slide;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _shadow1Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    _shadow2Controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _shadow1Fade = CurvedAnimation(parent: _shadow1Controller, curve: Curves.easeOut);
    _shadow2Fade = CurvedAnimation(parent: _shadow2Controller, curve: Curves.easeOut);
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    _shadow1Slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _shadow1Controller, curve: Curves.easeOut));
    _shadow2Slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _shadow2Controller, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _shadow1Controller.forward().then((_) {
      if (mounted) {
        _shadow2Controller.forward().then((_) {
          if (mounted) _cardController.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _shadow1Controller.dispose();
    _shadow2Controller.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 알림 shadow 표현 container1
        FadeTransition(
          opacity: _shadow1Fade,
          child: SlideTransition(
            position: _shadow1Slide,
            child: Padding(
              padding: const EdgeInsets.only(left: 22, right: 22, top: 25),
              child: Container(
                height: 57,
                decoration: BoxDecoration(
                  color: AppColors.notificationBottomSheetChattingContainerBottom,
                  borderRadius: BorderRadius.circular(22.r),
                ),
              ),
            ),
          ),
        ),

        /// 알림 shadow 표현 container2
        FadeTransition(
          opacity: _shadow2Fade,
          child: SlideTransition(
            position: _shadow2Slide,
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 17),
              child: Container(
                height: 57,
                decoration: BoxDecoration(
                  color: AppColors.notificationBottomSheetChattingContainerMiddle,
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 10.0, color: AppColors.opacity15Black)],
                ),
              ),
            ),
          ),
        ),

        /// 알림 container
        FadeTransition(
          opacity: _cardFade,
          child: SlideTransition(
            position: _cardSlide,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.notificationBottomSheetChattingContainerTop,
                borderRadius: BorderRadius.circular(22.r),
                boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 10.0, color: AppColors.opacity15Black)],
              ),
              child: Row(
                children: [
                  const UserProfileCircularAvatar(avatarSize: Size(40, 40), isDeleteAccount: true, hasBorder: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('롬롬', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Text(
                                  '신사동',
                                  style: CustomTextStyles.p3.copyWith(
                                    color: AppColors.opacity60White,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Container(
                                  width: 2,
                                  height: 2,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.opacity60White,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '3시간 전',
                                  style: CustomTextStyles.p3.copyWith(
                                    color: AppColors.opacity60White,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('오늘 거래 가능할까요? 🥹', style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400)),
                            Container(
                              width: 16,
                              height: 16,
                              margin: const EdgeInsets.only(right: 8),
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: AppColors.chatUnreadBadge, shape: BoxShape.circle),
                              child: Text('5', style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
