import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 앱 전역 공통 터치 위젯 — 물리 기반 Spring 인터랙션
///
/// 토스 스타일 인터랙션:
/// - 누르는 순간: 즉각 scale down (애니메이션 없음 → 즉각 반응 느낌)
/// - 손 떼는 순간: SpringSimulation으로 탄성 있게 복귀 (살짝 bounce)
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
/// // 아이콘 버튼 (작은 터치 영역)
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

  /// 커스텀 ripple 색상
  final Color? rippleColor;

  final VoidCallback? onLongPress;

  /// false 시 터치 반응 없음 (disabled 상태)
  final bool enabled;

  // ─────────────────────────────────────────────
  // 표준 scaleDown 상수
  // ─────────────────────────────────────────────

  /// 기본 버튼
  static const double scaleButton = 0.97;

  /// 카드 / 리스트 아이템
  static const double scaleCard = 0.985;

  /// 아이콘 버튼 (닫기, 뒤로가기 등 소형 터치 영역)
  static const double scaleIcon = 0.93;

  // ─────────────────────────────────────────────
  // Spring 파라미터 (토스 스타일)
  // ─────────────────────────────────────────────

  /// 버튼/카드용 spring — 빠르고 살짝 bounce (damping ratio ≈ 0.65)
  static const _springButton = SpringDescription(mass: 1.0, stiffness: 300.0, damping: 20.0);

  /// 아이콘 버튼용 spring — 더 강하고 안정적 (damping ratio ≈ 0.87)
  static const _springIcon = SpringDescription(mass: 1.0, stiffness: 300.0, damping: 30.0);

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentScale = 1.0;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // duration/upperBound은 SpringSimulation이 직접 제어하므로 여기선 의미 없음
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _currentScale = 1.0 - ((1.0 - widget.scaleDown) * _controller.value);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    _isPressed = true;
    // 즉각 scale down — 애니메이션 없이 바로 적용 (토스 스타일: 누름 순간 즉각 반응)
    _controller.stop();
    _controller.value = 1.0;
    setState(() => _currentScale = widget.scaleDown);
  }

  void _onTapUp(TapUpDetails _) {
    if (!_isPressed) return;
    _isPressed = false;
    _springBack();
  }

  void _onTapCancel() {
    if (!_isPressed) return;
    _isPressed = false;
    _springBack();
  }

  void _springBack() {
    _controller.stop();
    // 현재 scale에서 1.0으로 복귀 — spring 물리 적용
    final startValue = (1.0 - _currentScale) / (1.0 - widget.scaleDown);
    _controller.value = startValue.clamp(0.0, 1.0);

    final spring = widget.scaleDown <= AppPressable.scaleIcon ? AppPressable._springIcon : AppPressable._springButton;

    _controller.animateWith(SpringSimulation(spring, _controller.value, 0.0, 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(8);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.enabled ? widget.onTap : null,
      onLongPress: widget.enabled ? widget.onLongPress : null,
      behavior: HitTestBehavior.opaque,
      child: Transform.scale(
        scale: _currentScale,
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
            : widget.child,
      ),
    );
  }
}
