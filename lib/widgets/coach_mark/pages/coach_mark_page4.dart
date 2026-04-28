import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/ripple_widget.dart';
import 'package:romrom_fe/widgets/coach_mark/coach_mark_coords.dart';

class CoachMarkPage4 extends StatefulWidget {
  const CoachMarkPage4({super.key});

  @override
  State<CoachMarkPage4> createState() => _CoachMarkPage4State();
}

class _CoachMarkPage4State extends State<CoachMarkPage4> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rippleOpacity;
  late final Animation<double> _barOpacity;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat();

    // 0~7%: fadein, 7~33%: 표시, 33~43%: fadeout
    // 43~100%: 0.001 유지 (완전히 0으로 두면 ticker가 멈춰 재개 시 부자연스러움)
    _rippleOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 7),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 26),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.001), weight: 57),
    ]).animate(_controller);

    // 0~7%: fadein, 7~33%: 표시, 33~43%: fadeout, 43~100%: invisible
    _barOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 7),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 26),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 57),
    ]).animate(_controller);

    // 0~33%: 정지, 33~82%: 위로 슬라이드, 82~100%: 정지
    _cardSlide = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 49),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 18),
    ]).animate(_controller);

    // 0~82%: 항상 표시, 82~87%: 슬라이드 후 fadeout, 87~100%: invisible (13% 휴지)
    _cardOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 82),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 13),
    ]).animate(_controller);

    // 0~33%: scale 1.0, 33~82%: 드래그하며 점점 커짐, 82~100%: 유지
    _pressAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 33),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeInOut)), weight: 49),
      TweenSequenceItem(tween: ConstantTween(1.3), weight: 18),
    ]).animate(_controller);
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
        final c = CoachMarkCoords(constraints.maxWidth, constraints.maxHeight);
        final startBottom = c.bottom(176);
        final endBottom = c.bottom(485);
        final cardW = c.px(92);
        final cardH = c.px(137);

        return Stack(
          children: [
            // 목표 슬롯 컨테이너 (항상 표시)
            Positioned(
              top: c.top(211),
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: c.px(121),
                  height: c.px(175),
                  decoration: BoxDecoration(
                    color: AppColors.cardDragContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.textColorWhite, width: 2),
                    boxShadow: const [
                      BoxShadow(color: AppColors.textColorWhite, offset: Offset(0, 0), blurRadius: 30, spreadRadius: 4),
                    ],
                  ),
                ),
              ),
            ),

            // 드래그 중인 카드
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Positioned(
                bottom: startBottom + _cardSlide.value * (endBottom - startBottom),
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: _cardOpacity.value,
                  child: Center(
                    child: Transform.scale(
                      scale: _pressAnim.value,
                      child: Image.asset('assets/images/coach-drag-card.png', width: cardW, height: cardH),
                    ),
                  ),
                ),
              ),
            ),

            // 꾹 누름 ripple (opacity를 RippleWidget 내부에서 처리해 ticker 중단 방지)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Positioned(
                bottom: c.bottom(265),
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      RippleWidget(size: 35, color: AppColors.textColorWhite, opacity: _rippleOpacity.value),
                      const SizedBox(height: 150),
                      RippleWidget(size: 52, color: AppColors.textColorWhite, opacity: _rippleOpacity.value),
                    ],
                  ),
                ),
              ),
            ),

            // 수직 막대 (ripple과 함께 fadeout)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Positioned(
                bottom: c.bottom(302),
                left: constraints.maxWidth / 2 - 1,
                right: constraints.maxWidth / 2 - 1,
                child: Opacity(
                  opacity: _barOpacity.value,
                  child: Container(height: 176, width: 2, color: AppColors.textColorWhite),
                ),
              ),
            ),

            // 설명 텍스트
            Positioned(
              bottom: c.bottom(110),
              left: 24,
              right: 24,
              child: Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: CustomTextStyles.h2.copyWith(height: 1.3),
                  children: [
                    const TextSpan(
                      text: '내 물건을 꾹 누른 다음\n위로 드래그',
                      style: TextStyle(color: AppColors.primaryYellow),
                    ),
                    const TextSpan(text: '하여 요청하세요'),
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
