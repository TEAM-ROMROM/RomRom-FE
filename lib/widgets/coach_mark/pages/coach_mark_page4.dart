import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/ripple_widget.dart';

class CoachMarkPage4 extends StatefulWidget {
  const CoachMarkPage4({super.key});

  @override
  State<CoachMarkPage4> createState() => _CoachMarkPage4State();
}

class _CoachMarkPage4State extends State<CoachMarkPage4> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _dragAnim;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat();
    _dragAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.75, curve: Curves.easeInOut),
      ),
    );
    _pressAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.1, curve: Curves.easeOut),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        const startRatio = 0.65;
        const endRatio = 0.35;
        final travelPx = (startRatio - endRatio) * h;

        return Stack(
          children: [
            // 꾹 누름 ripple
            Positioned(
              top: startRatio * h - 36,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final rippleOpacity = _controller.value < 0.12
                        ? 1.0
                        : (1 - ((_controller.value - 0.12) * 5)).clamp(0.0, 1.0);
                    return Opacity(
                      opacity: rippleOpacity,
                      child: const RippleWidget(size: 56, color: AppColors.textColorWhite),
                    );
                  },
                ),
              ),
            ),
            // 드래그 손가락
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _dragAnim.value;
                final opacity = _controller.value > 0.75 ? (1 - ((_controller.value - 0.75) * 4)).clamp(0.0, 1.0) : 1.0;
                return Positioned(
                  top: startRatio * h - 28 - (progress * travelPx),
                  left: 0,
                  right: 0,
                  child: Opacity(
                    opacity: opacity,
                    child: Center(
                      child: Transform.scale(
                        scale: _pressAnim.value,
                        child: const Icon(
                          Icons.touch_app_rounded,
                          size: 56,
                          color: AppColors.textColorWhite,
                          shadows: [Shadow(color: AppColors.opacity20Black, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // 설명 텍스트
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: Text(
                '내 물건을 꾹 누른 다음\n위로 드래그하여 요청하세요',
                style: CustomTextStyles.h2.copyWith(height: 1.6),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}
