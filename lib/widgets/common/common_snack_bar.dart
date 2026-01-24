import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CommonSnackBar {
  static IconData _getIconData(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppIcons.onboardingProgressCheck;
      case SnackBarType.info:
        return AppIcons.information;
      case SnackBarType.error:
        return AppIcons.warning;
    }
  }

  static Color _getIconBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppColors.toastSuccessBackground;
      case SnackBarType.info:
        return AppColors.toastInfoBackground;
      case SnackBarType.error:
        return AppColors.toastErrorBackground;
    }
  }

  static void show({
    required BuildContext context,
    required String message,
    SnackBarType type = SnackBarType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    late AnimationController animationController;

    // AnimationController를 위한 TickerProvider 생성
    final tickerProvider = _OverlayTickerProvider();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: tickerProvider,
    );

    final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120.h,
        left: 24.w,
        right: 24.w,
        child: AnimatedBuilder(
          animation: fadeAnimation,
          builder: (context, child) => Opacity(
            opacity: fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // 블러 강도
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.opacity30White,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 16.w),
                            decoration:  BoxDecoration(
                              color:_getIconBackgroundColor(type),
                              shape: BoxShape.circle
                            ),
                            child: Icon(_getIconData(type), color: AppColors.textColorWhite,size: 16,),
                          ),
                          Expanded(
                            child: Text(
                              message.trim(),
                              style: CustomTextStyles.p2.copyWith(height: 1.4),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Fade in 애니메이션 시작
    animationController.forward();

    // duration 후에 fade out 후 제거
    Future.delayed(duration, () async {
      try {
        await animationController.reverse();
        overlayEntry.remove();
        animationController.dispose();
        tickerProvider.dispose();
      } catch (e) {
        // overlayEntry가 이미 제거된 경우 무시
        try {
          animationController.dispose();
          tickerProvider.dispose();
        } catch (_) {}
      }
    });
  }
}

// TickerProvider를 위한 헬퍼 클래스
class _OverlayTickerProvider implements TickerProvider {
  Ticker? _ticker;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _ticker = Ticker(onTick);
    return _ticker!;
  }

  void dispose() {
    _ticker?.dispose();
  }
}
