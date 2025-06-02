import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/onboarding_steps.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/category_selection_step.dart';
import 'package:romrom_fe/screens/onboarding/location_verification_step.dart';
import 'package:romrom_fe/screens/onboarding/user_info_step.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/widgets/onboarding_progress_header.dart';
import 'package:romrom_fe/widgets/onboarding_title_header.dart';

class OnboardingFlowScreen extends StatefulWidget {
  const OnboardingFlowScreen({super.key});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 1;
  final int _totalSteps = OnboardingSteps.values.length;

  // 현재 단계 정보
  OnboardingSteps get currentStepInfo => OnboardingSteps.fromStep(_currentStep);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 다음 페이지로 이동
  void _goToNextPage() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep += 1;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // 이전 페이지로 이동
  void _goToPrevPage() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep -= 1;
      });
      _pageController.animateToPage(
        _currentStep - 1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // 첫 페이지에서 뒤로가기 시 로그아웃 처리 후 로그인 화면으로 이동
      final AuthService authService = AuthService();
      authService.logout(context);
    }
  }

  // 온보딩 완료 후 메인 화면으로 이동
  void _completeOnboarding() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태표시줄 여백
          SizedBox(height: MediaQuery.of(context).padding.top),

          // 프로그레스 헤더 (고정)
          OnboardingProgressHeader(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            onBackPressed: _goToPrevPage,
          ),

          // 타이틀 헤더 (고정)
          OnboardingTitleHeader(
            title: currentStepInfo.title,
            subtitle: currentStepInfo.subtitle,
          ),

          // PageView 본문 전환
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // 사용자 스와이프 비활성화
              children: [
                UserInfoStep(onNext: _goToNextPage),
                LocationVerificationStep(onNext: _goToNextPage),
                CategorySelectionStep(onComplete: _completeOnboarding),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
