import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/onboarding_steps.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/category_selection_step.dart';
import 'package:romrom_fe/screens/onboarding/term_agreement_step.dart';
import 'package:romrom_fe/services/auth_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/onboarding_progress_header.dart';
import 'package:romrom_fe/widgets/onboarding_title_header.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final int initialStep;

  const OnboardingFlowScreen({super.key, this.initialStep = 1});

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  late final PageController _pageController;
  late int _currentStep;
  final int _totalSteps = OnboardingSteps.values.length;
  // 이탈 확인 모달 표시 중 (뒤로 가기 연타 중복 모달 방지)
  bool _isLeaveConfirmShowing = false;

  // 현재 단계 정보
  OnboardingSteps get currentStepInfo => OnboardingSteps.fromStep(_currentStep);

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _pageController = PageController(initialPage: _currentStep - 1);
  }

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
      _pageController.animateToPage(_currentStep - 1, duration: AppMotion.normal, curve: AppMotion.standard);
    }
  }

  // 이전 페이지로 이동 (첫 단계면 이탈 확인)
  void _goToPrevPage() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep -= 1;
      });
      _pageController.animateToPage(_currentStep - 1, duration: AppMotion.normal, curve: AppMotion.standard);
    } else {
      _confirmLeaveOnboarding();
    }
  }

  /// 첫 단계 뒤로 가기: 확인 모달 > 로그아웃 후 로그인 화면 (모달 열림 중 중복 표시 방지)
  Future<void> _confirmLeaveOnboarding() async {
    if (_isLeaveConfirmShowing) return;
    _isLeaveConfirmShowing = true;
    try {
      await CommonModal.confirm(
        context: context,
        message: '가입을 그만두고\n로그인 화면으로 돌아갈까요?\n입력한 내용은 저장되지 않아요.',
        cancelText: '계속하기',
        confirmText: '그만두기',
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: () => AuthService().logout(context),
      );
    } finally {
      _isLeaveConfirmShowing = false;
    }
  }

  // 온보딩 완료: 메인 화면 이동 > 보관된 딥링크 열기
  void _completeOnboarding() {
    context.navigateTo(screen: const MainScreen(), type: NavigationTypes.pushAndRemoveUntil);
    // 로그인·온보딩 중 받은 링크 > 메인 진입 후 열기
    RomRomDeepLinkRouter.onMainScreenEntered();
  }

  @override
  Widget build(BuildContext context) {
    // 시스템 뒤로 가기도 같은 경로 (첫 단계 이탈 확인)
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goToPrevPage();
      },
      child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태표시줄 여백
            SizedBox(height: MediaQuery.of(context).padding.top),

            // 프로그레스 헤더 (고정)
            OnboardingProgressHeader(currentStep: _currentStep, totalSteps: _totalSteps, onBackPressed: _goToPrevPage),

            // 타이틀 헤더 (고정)
            OnboardingTitleHeader(title: currentStepInfo.title, subtitle: currentStepInfo.subtitle),

            // PageView 본문 전환
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // 사용자 스와이프 비활성화
                children: [
                  TermAgreementStep(onNext: _goToNextPage),
                  CategorySelectionStep(onComplete: _completeOnboarding),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
