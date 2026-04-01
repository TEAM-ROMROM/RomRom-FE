import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 앱 전역 공통 터치 위젯
///
/// 모든 버튼, 카드, 리스트 아이템의 터치 반응을 통일.
/// - 누르는 순간 scale down (즉각 반응)
/// - 떼는 순간 spring back
/// - InkWell ripple 유지 (선택적)
///
/// 사용 예:
/// ```dart
/// AppPressable(
///   onTap: () => doSomething(),
///   child: MyButton(),
/// )
///
/// // 카드
/// AppPressable(
///   onTap: () {},
///   scaleDown: AppPressable.scaleCard,
///   borderRadius: BorderRadius.circular(12),
///   child: MyCard(),
/// )
///
/// // 아이콘 버튼
/// AppPressable(
///   onTap: () {},
///   scaleDown: AppPressable.scaleIcon,
///   enableRipple: false,
///   child: Icon(Icons.close),
/// )
/// ```
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.onTap,
    required this.child,
    this.scaleDown = scaleButton,
    this.borderRadius,
    this.enableRipple = true,
    this.rippleColor,
    this.onLongPress,
    this.enabled = true,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// 눌렸을 때 축소 비율 (0.0 ~ 1.0)
  final double scaleDown;

  /// Ripple 클리핑에 사용되는 borderRadius
  final BorderRadius? borderRadius;

  /// InkWell ripple 효과 활성화 여부
  final bool enableRipple;

  /// 커스텀 ripple 색상 (미지정 시 darkenBlend 자동 적용)
  final Color? rippleColor;

  final VoidCallback? onLongPress;

  /// false 시 터치 반응 없음 (disabled 상태)
  final bool enabled;

  // ─────────────────────────────────────────────
  // 표준 scaleDown 상수
  // ─────────────────────────────────────────────

  /// 기본 버튼 (CompletionButton, FloatingButton, Modal 버튼)
  static const double scaleButton = 0.97;

  /// 카드 / 리스트 아이템
  static const double scaleCard = 0.985;

  /// 아이콘 버튼 (닫기, 뒤로가기 등 소형 터치 영역)
  static const double scaleIcon = 0.93;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.instant, // 100ms — 눌림 즉각 반응
      reverseDuration: AppMotion.fast, // 200ms — spring back
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: AppMotion.standard, reverseCurve: AppMotion.springOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(8);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.enableRipple
            ? Material(
                color: Colors.transparent,
                borderRadius: effectiveRadius,
                child: InkWell(
                  onTap: widget.enabled ? widget.onTap : null,
                  onLongPress: widget.enabled ? widget.onLongPress : null,
                  borderRadius: effectiveRadius,
                  highlightColor: widget.rippleColor ?? darkenBlend(Theme.of(context).colorScheme.surface),
                  splashColor: (widget.rippleColor ?? darkenBlend(Theme.of(context).colorScheme.surface)).withValues(
                    alpha: 0.3,
                  ),
                  child: widget.child,
                ),
              )
            : GestureDetector(
                onTap: widget.enabled ? widget.onTap : null,
                onLongPress: widget.enabled ? widget.onLongPress : null,
                child: widget.child,
              ),
      ),
    );
  }
}
