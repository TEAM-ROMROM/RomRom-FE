import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CoachMarkPage5 extends StatefulWidget {
  const CoachMarkPage5({super.key});

  @override
  State<CoachMarkPage5> createState() => _CoachMarkPage5State();
}

class _CoachMarkPage5State extends State<CoachMarkPage5> with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _fadeController;
  late final List<Animation<double>> _fadeAnims;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);

    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
    _fadeAnims = List.generate(3, (i) {
      final start = 0.3 + i * 0.25;
      final end = (start + 0.35).clamp(0.0, 1.0);
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
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        return Stack(
          children: [
            // 요청 옵션 텍스트 + 칩
            Positioned(
              bottom: h * 193 / 852,
              left: w * 86 / 393,
              right: w * 142 / 393,
              child: FadeTransition(
                opacity: _fadeAnims[0],
                child: Column(
                  children: [
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        style: CustomTextStyles.h3.copyWith(height: 1.3),
                        children: [
                          const TextSpan(
                            text: '요청 옵션',
                            style: TextStyle(color: AppColors.primaryYellow),
                          ),
                          const TextSpan(text: '을 선택하세요'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Container(
                      width: 80.w,
                      height: 34.h,
                      decoration: BoxDecoration(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 1.h),
                          child: Text(
                            ItemTradeOption.directTradeOnly.label,
                            style: const TextStyle(color: AppColors.primaryBlack),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 요청하기 버튼
            Positioned(
              bottom: h * 64 / 852,
              right: w * 24 / 393,
              child: FadeTransition(
                opacity: _fadeAnims[1],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: 56,
                      width: 169,
                      child: Material(
                        color: AppColors.primaryYellow,
                        borderRadius: BorderRadius.circular(10.r),
                        child: Center(
                          child: Text('요청하기', style: CustomTextStyles.p1.copyWith(color: AppColors.textColorBlack)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // 버튼 설명 텍스트
                    Text.rich(
                      textAlign: TextAlign.center,
                      TextSpan(
                        style: CustomTextStyles.h3.copyWith(height: 1.3),
                        children: [
                          const TextSpan(text: '버튼을 눌러 '),
                          const TextSpan(
                            text: '교환을 요청',
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
