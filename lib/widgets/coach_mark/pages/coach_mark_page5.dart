import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/ripple_widget.dart';

class CoachMarkPage5 extends StatefulWidget {
  const CoachMarkPage5({super.key});

  @override
  State<CoachMarkPage5> createState() => _CoachMarkPage5State();
}

class _CoachMarkPage5State extends State<CoachMarkPage5> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade1, _fade2;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();
    _fade1 = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _fade2 = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
    );
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
        return Stack(
          children: [
            Positioned(
              top: h * 0.58,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _fade1,
                child: Column(
                  children: [
                    const RippleWidget(size: 64, color: AppColors.primaryYellow),
                    const SizedBox(height: 12),
                    Text('요청 옵션을 선택하세요', style: CustomTextStyles.h3.copyWith(height: 1.6), textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 80,
              left: 24,
              right: 24,
              child: FadeTransition(
                opacity: _fade2,
                child: Text(
                  '버튼을 눌러 교환을 요청하세요',
                  style: CustomTextStyles.h3.copyWith(height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
