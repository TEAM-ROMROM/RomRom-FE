import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// 앱 전역 공통 스켈레톤 로딩 래퍼
///
/// - 로딩 중: skeleton 위젯을 Skeletonizer shimmer로 표시
/// - 로딩 완료: fade 전환으로 실제 child 표시
/// - shimmer 색상 통일 (opacity10White → opacity30White)
///
/// 사용 예:
/// ```dart
/// AppSkeleton(
///   isLoading: _isLoading,
///   skeleton: MyScreenSkeleton(),
///   child: MyActualContent(),
/// )
/// ```
///
/// SliverList 화면에서는 skeleton/child 모두 Sliver 위젯으로 전달.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    required this.isLoading,
    required this.skeleton,
    required this.child,
    this.fadeDuration = AppMotion.fast,
  });

  final bool isLoading;

  /// 로딩 중 표시할 스켈레톤 위젯
  final Widget skeleton;

  /// 로딩 완료 후 표시할 실제 콘텐츠
  final Widget child;

  /// skeleton ↔ child 전환 fade 시간 (기본: 200ms)
  final Duration fadeDuration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: fadeDuration,
      switchInCurve: AppMotion.entry,
      switchOutCurve: AppMotion.entry,
      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
      child: isLoading
          ? Skeletonizer(
              key: const ValueKey('skeleton'),
              enabled: true,
              effect: const ShimmerEffect(
                baseColor: AppColors.opacity10White,
                highlightColor: AppColors.opacity30White,
              ),
              textBoneBorderRadius: const TextBoneBorderRadius.fromHeightFactor(.3),
              ignoreContainers: true,
              child: skeleton,
            )
          : KeyedSubtree(key: const ValueKey('content'), child: child),
    );
  }
}
