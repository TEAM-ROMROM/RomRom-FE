import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/finger_direction.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/finger_widget.dart';

class CoachMarkPage3 extends StatefulWidget {
  const CoachMarkPage3({super.key});

  @override
  State<CoachMarkPage3> createState() => _CoachMarkPage3State();
}

class _CoachMarkPage3State extends State<CoachMarkPage3> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
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
        return Stack(
          children: [
            Positioned(
              bottom: h * 0.20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) => Opacity(
                      opacity: (1 - _anim.value).clamp(0.2, 1.0),
                      child: Transform.translate(
                        offset: Offset(-10 * _anim.value, 0),
                        child: const Icon(Icons.chevron_left_rounded, color: AppColors.opacity80White, size: 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const FingerWidget(direction: FingerDirection.leftRight, size: 56, travelDistance: 18),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _anim,
                    builder: (context, child) => Opacity(
                      opacity: _anim.value.clamp(0.2, 1.0),
                      child: Transform.translate(
                        offset: Offset(10 * _anim.value, 0),
                        child: const Icon(Icons.chevron_right_rounded, color: AppColors.opacity80White, size: 40),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: h * 0.10,
              left: 24,
              right: 24,
              child: Text(
                '좌·우로 넘기며\n교환하고 싶은 물건을 선택하세요',
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
