import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 3개 탭 토글 스위치 위젯
class TripleToggleSwitch extends StatelessWidget {
  final Animation<double> animation; // 0.0 ~ 2.0
  final int selectedIndex; // 0, 1, 2
  final VoidCallback onFirstTap;
  final VoidCallback onSecondTap;
  final VoidCallback onThirdTap;
  final String firstText;
  final String secondText;
  final String thirdText;

  const TripleToggleSwitch({
    super.key,
    required this.animation,
    required this.selectedIndex,
    required this.onFirstTap,
    required this.onSecondTap,
    required this.onThirdTap,
    required this.firstText,
    required this.secondText,
    required this.thirdText,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 실제 사용 가능한 너비 계산
          final containerWidth = constraints.maxWidth;
          // 여백 제외한 탭 너비: (전체 너비 - 좌우 여백 4.w) / 3
          final tabWidth = (containerWidth - 4.w) / 3;

          return Container(
            width: containerWidth,
            height: 46.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: AppColors.secondaryBlack1,
            ),
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // 선택된 배경 이동
                    Positioned(
                      left: 2.w + (animation.value * tabWidth),
                      top: 2.h,
                      child: Container(
                        width: tabWidth,
                        height: 42.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.r),
                          color: AppColors.primaryBlack,
                        ),
                      ),
                    ),
                    // 3개 탭 영역
                    Row(
                      children: [
                        // 첫 번째 탭
                        Expanded(
                          child: GestureDetector(
                            onTap: onFirstTap,
                            child: Container(
                              height: 46.h,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: CustomTextStyles.p2.copyWith(
                                  color: selectedIndex == 0
                                      ? AppColors.textColorWhite
                                      : AppColors.opacity50White,
                                ),
                                child: Text(firstText),
                              ),
                            ),
                          ),
                        ),
                        // 두 번째 탭
                        Expanded(
                          child: GestureDetector(
                            onTap: onSecondTap,
                            child: Container(
                              height: 46.h,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: CustomTextStyles.p2.copyWith(
                                  color: selectedIndex == 1
                                      ? AppColors.textColorWhite
                                      : AppColors.opacity50White,
                                ),
                                child: Text(secondText),
                              ),
                            ),
                          ),
                        ),
                        // 세 번째 탭
                        Expanded(
                          child: GestureDetector(
                            onTap: onThirdTap,
                            child: Container(
                              height: 46.h,
                              color: Colors.transparent,
                              alignment: Alignment.center,
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 300),
                                style: CustomTextStyles.p2.copyWith(
                                  color: selectedIndex == 2
                                      ? AppColors.textColorWhite
                                      : AppColors.opacity50White,
                                ),
                                child: Text(thirdText),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

