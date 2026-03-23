import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/finger_direction.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/finger_widget.dart';
import 'package:romrom_fe/widgets/coach_mark/animations/ripple_widget.dart';
import 'package:romrom_fe/widgets/home_feed_ai_sort_button.dart';

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
              bottom: h * 432 / 852,
              left: 40,
              right: 40,
              child: FadeTransition(
                opacity: _fadeAnims[0],
                child: Column(
                  children: [
                    const Stack(
                      alignment: Alignment.bottomCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(bottom: 30.0),
                          child: RippleWidget(size: 72, color: AppColors.textColorWhite),
                        ),

                        Positioned(
                          right: -30, // 손가락을 화살표 오른쪽에 배치
                          child: FingerWidget(size: 64, travelDistance: 20, direction: FingerDirection.none),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        style: CustomTextStyles.h2.copyWith(height: 1.3),
                        children: [
                          const TextSpan(text: '이미지를 누르면\n'),
                          const TextSpan(
                            text: '물건의 상세 정보',
                            style: TextStyle(color: AppColors.primaryYellow),
                          ),
                          const TextSpan(text: '를 확인할 수 있어요'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 중단: 좋아요 설명
            Positioned(
              bottom: h * 318 / 853,
              right: 33,
              child: FadeTransition(
                opacity: _fadeAnims[1],
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      textAlign: TextAlign.end,
                      TextSpan(
                        style: CustomTextStyles.h3.copyWith(height: 1.3),
                        children: [
                          const TextSpan(text: '좋아요를 눌러\n'),
                          const TextSpan(
                            text: '물건을 저장',
                            style: TextStyle(color: AppColors.primaryYellow),
                          ),
                          const TextSpan(text: '하세요'),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),
                    Column(
                      children: [
                        SvgPicture.asset('assets/images/dislike-heart-icon.svg'),
                        Text('4', style: CustomTextStyles.p2),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 하단: AI 분석 설명
            Positioned(
              bottom: h * 151 / 852,
              right: 24,
              child: FadeTransition(
                opacity: _fadeAnims[2],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const HomeFeedAiSortButton(isActive: true),
                    const SizedBox(height: 14),

                    Text.rich(
                      textAlign: TextAlign.end,
                      TextSpan(
                        style: CustomTextStyles.h3.copyWith(height: 1.3),
                        children: [
                          const TextSpan(text: 'AI 분석으로 '),
                          const TextSpan(
                            text: '교환 가능성이\n높은 물건을 확인',
                            style: TextStyle(color: AppColors.primaryYellow),
                          ),
                          const TextSpan(text: '하세요'),
                        ],
                      ),
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
