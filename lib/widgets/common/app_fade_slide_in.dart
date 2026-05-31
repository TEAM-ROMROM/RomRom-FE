import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_motion.dart';

/// 앱 전역 공통 등장 애니메이션 위젯
///
/// 모든 카드, 리스트 아이템, 화면 진입 요소의 등장을 통일.
/// - opacity 0 → 1
/// - translateY +slideOffset → 0
///
/// 리스트 stagger 사용 예:
/// ```dart
/// ListView.builder(
///   itemBuilder: (context, index) => AppFadeSlideIn(
///     delay: Duration(milliseconds: index * AppMotion.staggerDelayMs),
///     child: MyListItem(items[index]),
///   ),
/// )
/// ```
///
/// 단일 위젯 등장:
/// ```dart
/// AppFadeSlideIn(
///   child: MyCard(),
/// )
/// ```
class AppFadeSlideIn extends StatefulWidget {
  const AppFadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.normal,
    this.slideOffset = 12.0,
    this.curve = AppMotion.entry,
  });

  final Widget child;

  /// stagger를 위한 지연 시간
  final Duration delay;

  /// 애니메이션 지속 시간 (기본: 300ms)
  final Duration duration;

  /// 시작 y offset (px) — 양수: 아래에서 위로
  final double slideOffset;

  /// 애니메이션 Curve
  final Curve curve;

  @override
  State<AppFadeSlideIn> createState() => _AppFadeSlideInState();
}

class _AppFadeSlideInState extends State<AppFadeSlideIn> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    if (widget.delay == Duration.zero) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.forward();
      });
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
