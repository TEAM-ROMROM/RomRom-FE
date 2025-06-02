import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 온보딩 프로그레스 헤더 위젯
///
/// 뒤로가기 버튼과 단계 표시 프로그레스를 포함
class OnboardingProgressHeader extends StatelessWidget {
  /// 현재 온보딩 단계 (1부터 시작)
  final int currentStep;

  /// 총 온보딩 단계 수
  final int totalSteps;

  /// 뒤로가기 버튼 클릭 시 실행될 콜백
  final VoidCallback? onBackPressed;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
      child: Row(
        children: [
          SizedBox(width: 24.w),
          // 뒤로가기 버튼
          GestureDetector(
            onTap: onBackPressed ?? () => Navigator.of(context).pop(),
            child: Icon(
              AppIcons.navigateBefore,
              size: 24.h,
              color: AppColors.textColorWhite,
            ),
          ),
          SizedBox(width: 81.w),
          // 프로그레스 표시기
          Expanded(
            child: Row(
              children: _buildProgressIndicators(),
            ),
          ),
          SizedBox(width: 128.w),
        ],
      ),
    );
  }

  /// 프로그레스 인디케이터 아이템 생성
  List<Widget> _buildProgressIndicators() {
    List<Widget> indicators = [];

    for (int i = 1; i <= totalSteps; i++) {
      // 각 단계 원형 인디케이터 추가
      indicators.add(
        _buildStepIndicator(i),
      );

      // 마지막 단계가 아니면 연결선 추가
      if (i < totalSteps) {
        indicators.add(
          Expanded(
            child: Container(
              height: 1.h,
              color: i < currentStep
                  ? AppColors.primaryYellow
                  : AppColors.onboardingProgressInactiveLine, // 비활성화 선 색상
            ),
          ),
        );
      }
    }

    return indicators;
  }

  /// 개별 단계 인디케이터 생성
  Widget _buildStepIndicator(int step) {
    // 단계 상태 결정
    bool isCompleted = step < currentStep;
    bool isCurrent = step == currentStep;
    bool isPending = step > currentStep;

    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted
            ? AppColors.primaryYellow // 완료 단계
            : AppColors.onboardingProgressStepPendingBg, // 현재 또는 대기 단계 배경
        border: Border.all(
          color: isPending
              ? AppColors.onboardingProgressStepPendingBorder // 대기 단계 테두리
              : AppColors.primaryYellow, // 현재 또는 완료 단계 테두리
          width: 1.w,
        ),
      ),
      child: Center(
        child: isCompleted
            // 완료 단계 - 체크 아이콘
            ? SvgPicture.asset(
                'assets/images/onBoardingProgressCheck.svg',
                height: 9.h,
                width: 12.w,
              )
            // 현재 또는 대기 단계 - 숫자 표시
            : Text(
                '$step',
                style: CustomTextStyles.p2.copyWith(
                  color: isCurrent
                      ? AppColors.textColorWhite // 현재 단계 텍스트 색상
                      : AppColors
                          .onboardingProgressStepPendingText, // 대기 단계 텍스트 색상
                ),
              ),
      ),
    );
  }
}
