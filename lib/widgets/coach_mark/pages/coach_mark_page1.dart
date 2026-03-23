import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/finger_direction.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/finger_widget.dart';

class CoachMarkPage1 extends StatefulWidget {
  const CoachMarkPage1({super.key});

  @override
  State<CoachMarkPage1> createState() => _CoachMarkPage1State();
}

class _CoachMarkPage1State extends State<CoachMarkPage1> with TickerProviderStateMixin {
  late final AnimationController _arrowController;
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _arrowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnims = List.generate(2, (i) {
      final start = i * 0.35;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start, end, curve: Curves.easeOut),
        ),
      );
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _arrowController.dispose();
    _fadeController.dispose();
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
              bottom: h * 0.30,
              child: FadeTransition(
                opacity: _fadeAnims[0],
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset('assets/images/coachmark-scroll-arrow-vertical.svg'),
                      const Positioned(
                        right: -80,
                        child: FingerWidget(direction: FingerDirection.upDown, size: 64, travelDistance: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: h * 334 / 852,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _fadeAnims[1],
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: CustomTextStyles.h2.copyWith(height: 1.3),
                    children: [
                      const TextSpan(text: '상 ・ 하 스크롤로\n'),
                      const TextSpan(
                        text: '다음 물건과 이전 물건',
                        style: TextStyle(color: AppColors.primaryYellow),
                      ),
                      const TextSpan(text: '을\n확인하세요'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
