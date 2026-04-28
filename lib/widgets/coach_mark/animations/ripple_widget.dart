import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 동심원 3개가 바깥으로 퍼지는 ripple 애니메이션 위젯
class RippleWidget extends StatefulWidget {
  final double size;
  final Color color;

  /// 외부에서 전체 투명도를 제어할 때 사용. 내부 opacity와 곱해짐.
  final double opacity;

  const RippleWidget({super.key, this.size = 70, this.color = AppColors.primaryYellow, this.opacity = 1.0});

  @override
  State<RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<RippleWidget> with TickerProviderStateMixin {
  static const int _animDurationMs = 9000;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      4,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _animDurationMs),
      ),
    );
    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _opacityAnims = _controllers.map((c) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 15),
        TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.0).chain(CurveTween(curve: Curves.ease)), weight: 85),
      ]).animate(c);
    }).toList();

    // 1/3씩 오프셋을 줘서 3개가 항상 동시에 보이도록
    for (int i = 0; i < 4; i++) {
      _controllers[i].value = i / 4;
      _controllers[i].repeat();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double w = widget.size / 70;
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(
          4,
          (i) => AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, child) => Transform.scale(
              scale: _scaleAnims[i].value,
              child: Opacity(
                opacity: (_opacityAnims[i].value * widget.opacity).clamp(0.0, 1.0),
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color, width: w * 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
