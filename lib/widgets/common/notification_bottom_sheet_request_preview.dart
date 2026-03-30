import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 알림 바텀시트 교환 요청 - 알림 미리보기 위젯
class NotificationBotomSheetRequestPreview extends StatelessWidget {
  const NotificationBotomSheetRequestPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.w),
          child: Container(
            height: 135.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.transparent,
              borderRadius: BorderRadius.vertical(top: Radius.circular(38.r)),
              border: Border(
                top: BorderSide(width: 9.w, color: AppColors.secondaryBlack1),
                right: BorderSide(width: 9.w, color: AppColors.secondaryBlack1),
                left: BorderSide(width: 9.w, color: AppColors.secondaryBlack1),
              ),
            ),
            child: const _NotificationBottomSheetRequestCardAnimation(),
          ),
        ),
        Center(
          child: Container(
            height: 135.h,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.primaryBlack, AppColors.primaryBlack, AppColors.transparent],
                stops: [0.0, 0.1, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 알림 요청 shadow → 알림 요청 카드 순차 slide+fadeIn 애니메이션
class _NotificationBottomSheetRequestCardAnimation extends StatefulWidget {
  const _NotificationBottomSheetRequestCardAnimation();

  @override
  State<_NotificationBottomSheetRequestCardAnimation> createState() =>
      _NotificationBottomSheetRequestCardAnimationState();
}

class _NotificationBottomSheetRequestCardAnimationState extends State<_NotificationBottomSheetRequestCardAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _shadowController;
  late final AnimationController _cardController;
  late final Animation<double> _shadowFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _shadowSlide;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _shadowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _cardController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));

    _shadowFade = CurvedAnimation(parent: _shadowController, curve: Curves.easeOut);
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);

    _shadowSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _shadowController, curve: Curves.easeOut));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardController, curve: Curves.easeOut));

    _shadowController.forward().then((_) {
      if (mounted) _cardController.forward();
    });
  }

  @override
  void dispose() {
    _shadowController.dispose();
    _cardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// 알림 shadow 표현 container
        FadeTransition(
          opacity: _shadowFade,
          child: SlideTransition(
            position: _shadowSlide,
            child: Padding(
              padding: EdgeInsets.only(left: 16.0.w, right: 16.0.w, top: 19.0.w),
              child: Container(
                height: 57.h,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlack1,
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 4.0, color: AppColors.opacity15Black)],
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
            child: Padding(
              padding: EdgeInsets.only(left: 8.0.w, right: 8.0.w, top: 8.0.w),
              child: Container(
                height: 60.h,
                padding: EdgeInsets.all(13.w),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBlack2,
                  borderRadius: BorderRadius.circular(22.r),
                  boxShadow: const [BoxShadow(offset: Offset(0, 4), blurRadius: 4.0, color: AppColors.opacity15Black)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34.w,
                      height: 34.w,
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlack,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: SvgPicture.asset('assets/images/romrom-logo.svg'),
                    ),
                    SizedBox(width: 8.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('내 물건에 교환 요청', style: CustomTextStyles.p2.copyWith(fontSize: 13.sp)),
                        SizedBox(height: 4.h),
                        Text('받은 요청을 지금 확인해볼까요?', style: CustomTextStyles.p3.copyWith(fontWeight: FontWeight.w400)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
