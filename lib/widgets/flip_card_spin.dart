import 'dart:math' as math;
import 'package:flutter/material.dart';

class FlipCardSpin extends StatefulWidget {
  final Widget front;
  final Widget back;

  /// 총 회전 바퀴 수 (정수로 두면 앞면에서 멈춤)
  final int turns;

  /// 전체 애니메이션 시간
  final Duration duration;

  /// 구간 비율 (필요시 조절)
  final double fastPortion; // 빠른 구간 비율
  final double slowPortion; // 감속 구간 비율
  final double settlePortion; // 마지막 착-정지 구간 비율

  const FlipCardSpin({
    super.key,
    required this.front,
    required this.back,
    this.turns = 3,
    this.duration = const Duration(seconds: 3),
    this.fastPortion = 0.80,
    this.slowPortion = 0.15,
    this.settlePortion = 0.05,
  });

  @override
  State<FlipCardSpin> createState() => _FlipCardSpinState();
}

class _FlipCardSpinState extends State<FlipCardSpin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _spin; // 0.0 ~ turns

  @override
  void initState() {
    super.initState();
    assert(
      (widget.fastPortion + widget.slowPortion + widget.settlePortion)
              .toStringAsFixed(3) ==
          1.000.toStringAsFixed(3),
      'Portions must sum to 1.0',
    );

    _c = AnimationController(vsync: this, duration: widget.duration);

    // 각 구간의 '값' 목표 설정
    const double t0 = 0.0;
    final double t1 = widget.turns * widget.fastPortion; // 빠른 회전 목표값

    _spin = TweenSequence<double>([
      // 1) 빠르게 쭉
      TweenSequenceItem(
        tween: Tween(begin: t0, end: t1)
            .chain(CurveTween(curve: Curves.fastOutSlowIn)), // 빠른 구간은 선형
        weight: (widget.fastPortion * 1000),
      ),
    ]).animate(_c);

    // 다이얼로그가 붙은 직후 자동 재생
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _c.forward();
      // 앞면 고정 (0으로 리셋)
      if (mounted) _c.value = 0.0;
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _spin,
      builder: (context, _) {
        // 값(바퀴 수) -> 각도
        final angle = _spin.value * 2 * math.pi; // n turns
        final showingBack = (angle % (2 * math.pi)) > math.pi;

        final m = Matrix4.identity()
          ..setEntry(3, 2, 0.0015) // 원근감
          ..rotateY(angle);

        return Transform(
          alignment: Alignment.center,
          transform: m,
          child: showingBack
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: widget.back,
                )
              : widget.front,
        );
      },
    );
  }
}
