import 'package:flutter/widgets.dart';
import 'package:romrom_fe/models/app_motion.dart';

/// 페이지 넘김 물리: 기본 PageScrollPhysics + 스냅 spring(AppMotion.snapSpring)
/// 짧은 플릭에도 다음 페이지로 넘어가고, 넘침 없이 빠르게 자리 잡음
class SmoothPageScrollPhysics extends PageScrollPhysics {
  // 다음 페이지로 넘기는 최소 플릭 속도 (기본 50 > 20, 가볍게 튕겨도 넘어감)
  static const double minimumFlingVelocityPixelsPerSecond = 20.0;

  const SmoothPageScrollPhysics({super.parent});

  @override
  SmoothPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => AppMotion.snapSpring;

  @override
  double get minFlingVelocity => minimumFlingVelocityPixelsPerSecond;
}
