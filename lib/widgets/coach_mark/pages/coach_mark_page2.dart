import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/ripple_widget.dart';

class CoachMarkPage2 extends StatefulWidget {
  const CoachMarkPage2({super.key});

  @override
  State<CoachMarkPage2> createState() => _CoachMarkPage2State();
}

class _CoachMarkPage2State extends State<CoachMarkPage2> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _fadeAnims = List.generate(3, (i) {
      final start = i * 0.25;
      final end = (start + 0.35).clamp(0.0, 1.0);
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
        return Stack(
          children: [
            // 상단: 이미지 탭 설명
            Positioned(
              top: h * 0.28,
              left: 40,
              right: 40,
              child: FadeTransition(
                opacity: _fadeAnims[0],
                child: Column(
                  children: [
                    const RippleWidget(size: 72, color: AppColors.primaryYellow),
                    const SizedBox(height: 12),
                    Text(
                      '이미지를 누르면\n물건의 상세 정보를 확인할 수 있어요',
                      style: CustomTextStyles.h3.copyWith(height: 1.6),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            // 중단: 좋아요 설명
            Positioned(
              top: h * 0.57,
              right: 32,
              child: FadeTransition(
                opacity: _fadeAnims[1],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '좋아요를 눌러\n물건을 저장하세요',
                      style: CustomTextStyles.h3.copyWith(height: 1.6),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.favorite_border_rounded, color: AppColors.textColorWhite, size: 28),
                  ],
                ),
              ),
            ),
            // 하단: AI 분석 설명
            Positioned(
              top: h * 0.72,
              right: 32,
              child: FadeTransition(
                opacity: _fadeAnims[2],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'AI 분석으로 교환 가능성이\n높은 물건을 확인하세요',
                      style: CustomTextStyles.h3.copyWith(height: 1.6),
                      textAlign: TextAlign.right,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primaryYellow, borderRadius: BorderRadius.circular(4)),
                      child: Text('AI', style: CustomTextStyles.p3.copyWith(color: AppColors.primaryBlack)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
