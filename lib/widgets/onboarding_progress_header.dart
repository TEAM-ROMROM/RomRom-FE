import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 온보딩 프로그레스 헤더 위젯
///
/// 뒤로가기 버튼과 애니메이션 단계 표시 프로그레스를 포함
class OnboardingProgressHeader extends StatefulWidget {
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
  State<OnboardingProgressHeader> createState() =>
      _OnboardingProgressHeaderState();
}

class _OnboardingProgressHeaderState extends State<OnboardingProgressHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  // 이전 단계 추적
  late int _previousStep;

  @override
  void initState() {
    super.initState();
    _previousStep = widget.currentStep - 1;
    if (_previousStep < 1) _previousStep = 1;

    // 애니메이션 컨트롤러 설정 (0.5초 지속)
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 프로그레스 애니메이션 설정
    _progressAnimation = Tween<double>(
      begin: _previousStep / widget.totalSteps,
      end: widget.currentStep / widget.totalSteps,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 위젯 생성 시 자동으로 애니메이션 시작
    _animationController.forward();
  }

  @override
  void didUpdateWidget(OnboardingProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 단계가 변경되었을 때 애니메이션 재설정
    if (oldWidget.currentStep != widget.currentStep) {
      _previousStep = oldWidget.currentStep;

      // 애니메이션 새로 설정
      _progressAnimation = Tween<double>(
        begin: _previousStep / widget.totalSteps,
        end: widget.currentStep / widget.totalSteps,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      // 애니메이션 재시작
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 16.h),
      child: Row(
        children: [
          SizedBox(width: 24.w),
          // 뒤로가기 버튼
          GestureDetector(
            onTap: widget.onBackPressed ?? () => Navigator.of(context).pop(),
            child: Icon(
              AppIcons.navigateBefore,
              size: 24.h,
              color: AppColors.textColorWhite,
            ),
          ),
          SizedBox(width: 81.w),
          // 애니메이션 프로그레스 표시기
          Expanded(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Row(
                  children: _buildProgressIndicators(
                      _progressAnimation.value * widget.totalSteps),
                );
              },
            ),
          ),
          SizedBox(width: 128.w),
        ],
      ),
    );
  }

  /// 프로그레스 인디케이터 아이템 생성 (애니메이션 적용)
  List<Widget> _buildProgressIndicators(double animatedStep) {
    List<Widget> indicators = [];

    for (int i = 1; i <= widget.totalSteps; i++) {
      // 각 단계 원형 인디케이터 추가 (애니메이션 적용)
      indicators.add(
        _buildStepIndicator(i, animatedStep),
      );

      // 마지막 단계가 아니면 연결선 추가
      if (i < widget.totalSteps) {
        // 선 애니메이션 계산
        double lineProgress = 0.0;
        if (animatedStep >= i + 1) {
          // 선이 완전히 채워짐
          lineProgress = 1.0;
        } else if (animatedStep > i) {
          // 선이 부분적으로 채워짐
          lineProgress = animatedStep - i;
        }

        indicators.add(
          Expanded(
            child: Stack(
              children: [
                // 비활성화 선 (배경)
                Container(
                  height: 1.h,
                  color: AppColors.onboardingProgressInactiveLine,
                ),
                // 활성화 선 (애니메이션)
                Container(
                  height: 1.h,
                  width: MediaQuery.of(context).size.width * lineProgress * 0.2,
                  color: AppColors.primaryYellow,
                ),
              ],
            ),
          ),
        );
      }
    }

    return indicators;
  }

  /// 각 단계별 인디케이터 생성
  Widget _buildStepIndicator(int step, double animatedStep) {
    // 완료된 단계: 체크 아이콘과 노란색 배경
    if (step < widget.currentStep) {
      return Container(
        width: 24.w,
        height: 24.h,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryYellow,
        ),
        child: Padding(
          padding: EdgeInsets.all(6.w),
          child: Icon(
            AppIcons.onboardingProgressCheck,
            size: 9.sp,
            color: AppColors.textColorBlack,
          ),
        ),
      );
    }

    // 현재 단계: 숫자와 검정 배경, 노란색 테두리
    if (step == widget.currentStep) {
      return Container(
        width: 24.w,
        height: 24.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primaryBlack,
          border: Border.all(
            color: AppColors.primaryYellow,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            '$step',
            style: CustomTextStyles.p3.copyWith(
              color: AppColors.textColorWhite,
            ),
          ),
        ),
      );
    }

    // 대기 단계: 숫자와 검정 배경, 희미한 테두리
    return Container(
      width: 24.w,
      height: 24.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.onboardingProgressStepPendingBg,
        border: Border.all(
          color: AppColors.onboardingProgressStepPendingBorder,
          width: 1.0,
        ),
      ),
      child: Center(
        child: Text(
          '$step',
          style: CustomTextStyles.p3.copyWith(
            color: AppColors.onboardingProgressStepPendingText,
          ),
        ),
      ),
    );
  }
}
