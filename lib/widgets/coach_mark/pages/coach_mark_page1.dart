import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/finger_direction.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/finger_widget.dart';

class CoachMarkPage1 extends StatefulWidget {
  const CoachMarkPage1({super.key});

  @override
  State<CoachMarkPage1> createState() => _CoachMarkPage1State();
}

class _CoachMarkPage1State extends State<CoachMarkPage1> with SingleTickerProviderStateMixin {
  late final AnimationController _arrowController;
  late final Animation<double> _arrowAnim;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _arrowAnim = CurvedAnimation(parent: _arrowController, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _arrowController.dispose();
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
              top: 0,
              left: 0,
              right: 0,
              bottom: h * 0.20,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _arrowAnim,
                      builder: (context, child) => Opacity(
                        opacity: (1 - _arrowAnim.value).clamp(0.2, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, -8 * _arrowAnim.value),
                          child: const Icon(Icons.keyboard_arrow_up_rounded, color: AppColors.opacity80White, size: 32),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const FingerWidget(direction: FingerDirection.upDown, size: 64, travelDistance: 20),
                    const SizedBox(height: 4),
                    AnimatedBuilder(
                      animation: _arrowAnim,
                      builder: (context, child) => Opacity(
                        opacity: _arrowAnim.value.clamp(0.2, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 8 * _arrowAnim.value),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: AppColors.opacity80White,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: h * 0.10,
              left: 24,
              right: 24,
              child: Text(
                '상·하 스크롤로\n다음 물건과 이전 물건을\n확인하세요',
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
