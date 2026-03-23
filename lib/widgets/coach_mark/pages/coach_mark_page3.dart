import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
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
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fadeAnims = List.generate(2, (i) {
      final start = i * 0.35;
      final end = (start + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fadeController,
          curve: Interval(start.clamp(0.0, 1.0), end, curve: Curves.easeOut),
        ),
      );
    });
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxHeight;

        return Stack(
          children: [
            Positioned(
              bottom: h * 0.31,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _fadeAnims[0],
                child: Text.rich(
                  textAlign: TextAlign.center,
                  TextSpan(
                    style: CustomTextStyles.h2.copyWith(height: 1.3),
                    children: [
                      const TextSpan(text: '좌·우로 넘기며\n'),
                      const TextSpan(
                        text: '교환하고 싶은 물건',
                        style: TextStyle(color: AppColors.primaryYellow),
                      ),
                      const TextSpan(text: '을 선택하세요'),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: h * 86 / 852,
              child: FadeTransition(opacity: _fadeAnims[1], child: Image.asset('assets/images/coach-clip-cards.png')),
            ),

            Positioned(
              bottom: h * 180 / 852,
              left: 18,
              right: 30,
              child: FadeTransition(
                opacity: _fadeAnims[1],
                child: SvgPicture.asset('assets/images/coachMark-scroll-arrow-horizontal.svg'),
              ),
            ),

            Positioned(
              bottom: h * 144 / 852,
              left: w * 88 / 393,
              child: FadeTransition(
                opacity: _fadeAnims[1],
                child: const FingerWidget(direction: FingerDirection.arcLeftRightUp, size: 56, travelDistance: 100),
              ),
            ),
          ],
        );
      },
    );
  }
}
