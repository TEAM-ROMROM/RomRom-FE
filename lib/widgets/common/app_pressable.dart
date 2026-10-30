import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 앱 전역 공통 터치 위젯 — 물리 기반 Spring 인터랙션
///
/// 토스 스타일 인터랙션:
/// - 누르는 순간: 80ms 감속 축소 (즉각 반응, 끊김 없음)
/// - 손 떼는 순간: SpringSimulation(AppMotion.pressSpring)으로 복귀 (거의 튀지 않음)
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

  // 눌림 축소 시간 (80ms — 즉시 점프 대신 짧게 감속해 뚝 끊기는 느낌 제거)
  static const Duration pressDownDuration = Duration(milliseconds: 80);

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> with SingleTickerProviderStateMixin {
  // 눌림 정도 (0 = 원래 크기, 1 = scaleDown)
  late final AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // unbounded: spring 복귀 중 살짝 넘는 값 허용
    _controller = AnimationController.unbounded(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (!widget.enabled || widget.onTap == null) return;
    _isPressed = true;
    // 눌림: 80ms 감속 축소
    _controller.animateTo(1.0, duration: AppPressable.pressDownDuration, curve: AppMotion.decelerate);
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

  /// 손 뗌: 현재 눌림 정도에서 spring으로 원래 크기 복귀
  void _springBack() {
    _controller.animateWith(SpringSimulation(AppMotion.pressSpring, _controller.value, 0.0, 0.0));
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(8);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      // enableRipple=true 시 InkWell이 onTap/onLongPress를 처리하므로 GestureDetector에는 등록하지 않음
      onTap: widget.enableRipple ? null : (widget.enabled ? widget.onTap : null),
      onLongPress: widget.enableRipple ? null : (widget.enabled ? widget.onLongPress : null),
      behavior: HitTestBehavior.opaque,
      // 크기만 매 프레임 갱신 (자식 위젯 재빌드 없음)
      child: ScaleTransition(
        scale: _controller.drive(Tween<double>(begin: 1.0, end: widget.scaleDown)),
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
