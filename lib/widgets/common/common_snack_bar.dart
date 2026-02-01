import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/snack_bar_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CommonSnackBar {
  // 다중 토스트 관리 상수
  static const int _maxToasts = 3;
  static const double _baseBottom = 120;
  static const double _toastSpacing = 12;
  static const double _estimatedToastHeight = 58;

  // 활성 토스트 목록
  static final List<_ToastEntry> _activeToasts = [];

  /// 타입별 SVG 아이콘 경로 반환
  static String _getIconAssetPath(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return 'assets/images/toast_success.svg';
      case SnackBarType.info:
        return 'assets/images/toast_info.svg';
      case SnackBarType.error:
        return 'assets/images/toast_error.svg';
    }
  }

  /// 아이콘 위젯 빌드 (SVG 사용)
  /// - 모든 타입: 20x20 SVG 아이콘
  static Widget _buildIcon(SnackBarType type) {
    return SvgPicture.asset(_getIconAssetPath(type), width: 20, height: 20);
  }

  /// 모든 활성 토스트의 위치 업데이트
  static void _updateAllPositions() {
    double currentBottom = _baseBottom;

    for (int i = 0; i < _activeToasts.length; i++) {
      final toast = _activeToasts[i];
      toast.bottomPosition.value = currentBottom;
      currentBottom += _estimatedToastHeight + _toastSpacing;
    }
  }

  /// 토스트 리소스 정리 (비동기 - 애니메이션 포함)
  static Future<void> _removeToastWithAnimation(_ToastEntry toast) async {
    try {
      await toast.animationController.reverse();
      toast.overlayEntry.remove();
      _activeToasts.remove(toast);
      toast.dispose();
      _updateAllPositions();
    } catch (e) {
      _activeToasts.remove(toast);
      try {
        toast.dispose();
      } catch (_) {}
      _updateAllPositions();
    }
  }

  /// 토스트 즉시 제거 (동기 - 레이스 컨디션 방지)
  static void _removeToastImmediately(_ToastEntry toast) {
    _activeToasts.remove(toast);
    try {
      toast.overlayEntry.remove();
      toast.dispose();
    } catch (_) {}
    _updateAllPositions();
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

    // 최대 개수 초과 시 가장 오래된 토스트 즉시 제거 (동기적으로 처리하여 레이스 컨디션 방지)
    if (_activeToasts.length >= _maxToasts) {
      final oldestToast = _activeToasts.first;
      _removeToastImmediately(oldestToast);
    }

    // AnimationController를 위한 TickerProvider 생성
    final tickerProvider = _OverlayTickerProvider();

    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 200),
      vsync: tickerProvider,
    );

    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: animationController, curve: Curves.easeInOut));

    // 위치를 위한 ValueNotifier
    final bottomPosition = ValueNotifier<double>(_baseBottom);

    // 고유 ID 생성
    final toastId = DateTime.now().millisecondsSinceEpoch.toString();

    overlayEntry = OverlayEntry(
      builder: (context) => ValueListenableBuilder<double>(
        valueListenable: bottomPosition,
        builder: (context, bottom, child) => AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          bottom: bottom.h,
          left: 24.w,
          right: 24.w,
          child: AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) => Opacity(
              opacity: fadeAnimation.value,
              child: Material(
                color: AppColors.transparent,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      constraints: BoxConstraints(minHeight: 58.h),
                      decoration: BoxDecoration(
                        color: AppColors.toastBackground,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 19.h),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 16.w),
                              child: _buildIcon(type),
                            ),
                            Expanded(
                              child: Text(
                                message.trim(),
                                style: CustomTextStyles.p2.copyWith(height: 1.4),
                                maxLines: 2,
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
      ),
    );

    // 토스트 엔트리 생성 및 목록에 추가
    final toastEntry = _ToastEntry(
      id: toastId,
      overlayEntry: overlayEntry,
      animationController: animationController,
      tickerProvider: tickerProvider,
      bottomPosition: bottomPosition,
    );

    _activeToasts.add(toastEntry);

    // 모든 토스트 위치 업데이트
    _updateAllPositions();

    overlay.insert(overlayEntry);

    // Fade in 애니메이션 시작
    animationController.forward();

    // duration 후에 fade out 후 제거
    Future.delayed(duration, () async {
      if (_activeToasts.contains(toastEntry)) {
        await _removeToastWithAnimation(toastEntry);
      }
    });
  }
}

/// 활성 토스트 엔트리 관리 클래스
class _ToastEntry {
  final String id;
  final OverlayEntry overlayEntry;
  final AnimationController animationController;
  final _OverlayTickerProvider tickerProvider;
  final ValueNotifier<double> bottomPosition;

  _ToastEntry({
    required this.id,
    required this.overlayEntry,
    required this.animationController,
    required this.tickerProvider,
    required this.bottomPosition,
  });

  void dispose() {
    animationController.dispose();
    tickerProvider.dispose();
    bottomPosition.dispose();
  }
}

/// TickerProvider를 위한 헬퍼 클래스
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
