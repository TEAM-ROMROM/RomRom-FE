import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 동심원 3개가 바깥으로 퍼지는 ripple 애니메이션 위젯
class RippleWidget extends StatefulWidget {
  final double size;
  final Color color;
  const RippleWidget({super.key, this.size = 60, this.color = AppColors.primaryYellow});

  @override
  State<RippleWidget> createState() => _RippleWidgetState();
}

class _RippleWidgetState extends State<RippleWidget> with TickerProviderStateMixin {
  static const int _animDurationMs = 1600;
  static const int _staggerDelayMs = 400;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _scaleAnims;
  late final List<Animation<double>> _opacityAnims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: _animDurationMs),
      ),
    );
    _scaleAnims = _controllers
        .map((c) => Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();
    _opacityAnims = _controllers
        .map((c) => Tween<double>(begin: 0.8, end: 0.0).animate(CurvedAnimation(parent: c, curve: Curves.easeOut)))
        .toList();

    _controllers[0].repeat();
    Future.delayed(const Duration(milliseconds: _staggerDelayMs), () {
      if (mounted) _controllers[1].repeat();
    });
    Future.delayed(const Duration(milliseconds: _staggerDelayMs * 2), () {
      if (mounted) _controllers[2].repeat();
    });
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: List.generate(
          3,
          (i) => AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, child) => Transform.scale(
              scale: _scaleAnims[i].value,
              child: Opacity(
                opacity: _opacityAnims[i].value,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.color, width: 1.5),
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
