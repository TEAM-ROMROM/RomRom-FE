import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/onboarding_flow_screen.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/auth_button_group.dart';
import 'package:romrom_fe/widgets/login_button.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // 로그인 전환 애니메이션 (로고 이동 + 로그인 UI 등장)
  late AnimationController _loginTransitionController;
  late Animation<Alignment> _logoAlignmentAnim; // 로고 Y 이동
  late Animation<double> _loginUIFadeAnim; // 로그인 UI fade in
  bool _showLoginUI = false; // true: 로그인 UI 오버레이를 Stack에 삽입
  bool _loginTransitionStarted = false; // true: 애니메이션이 이미 시작됨 (중복 호출 방지)

  @override
  void initState() {
    super.initState();

    _loginTransitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    // 로고: 중앙(-0.075) → 로그인 화면 위치(-0.52)
    _logoAlignmentAnim = AlignmentTween(
      begin: const Alignment(0, -0.075),
      end: const Alignment(0, -0.52),
    ).animate(CurvedAnimation(parent: _loginTransitionController, curve: Curves.easeInOut));

    // 로그인 UI: 0 → 1 (30~100% 구간에서 fade in)
    _loginUIFadeAnim = CurvedAnimation(
      parent: _loginTransitionController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    unawaited(_initAndNavigate());
  }

  Future<void> _initAndNavigate() async {
    try {
      final results = await Future.wait([_determineInitialScreen(), Future.delayed(const Duration(seconds: 2))]);
      final nextScreen = results[0]! as Widget;

      if (!mounted) return;

      if (nextScreen is LoginScreen) {
        await _playLoginTransitionAnimation();
      } else {
        context.navigateTo(screen: nextScreen, type: NavigationTypes.fadeTransition);
      }
    } catch (e, st) {
      debugPrint('[SplashScreen] 초기화 실패: $e\n$st');
      if (!mounted) return;
      // 오류 시에도 로그인 화면이므로 전환 애니메이션 재생
      await _playLoginTransitionAnimation();
    }
  }

  /// 로고 이동 + 로그인 UI 등장 애니메이션 재생 후 실제 LoginScreen으로 교체
  Future<void> _playLoginTransitionAnimation() async {
    if (!mounted || _loginTransitionStarted) return;
    _loginTransitionStarted = true;
    setState(() => _showLoginUI = true);
    await _loginTransitionController.forward();
    if (!mounted) return;
    // 애니메이션 완료 후 즉시(전환 없이) 실제 LoginScreen으로 교체
    context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.clearStackImmediate);
  }

  Future<Widget> _determineInitialScreen() async {
    final romAuthApi = RomAuthApi();
    final tokenManager = TokenManager();
    final String? refreshToken = await tokenManager.getRefreshToken();

    if (refreshToken == null) {
      return const LoginScreen();
    }

    final isLoggedIn = await romAuthApi.refreshAccessToken();
    if (!isLoggedIn) {
      return const LoginScreen();
    }

    final userInfo = UserInfo();
    try {
      await userInfo.getUserInfo();
      await MemberManager.getCurrentMember();

      if (userInfo.needsOnboarding) {
        return OnboardingFlowScreen(initialStep: userInfo.nextOnboardingStep);
      }

      await FirebaseService().handleFcmToken();
      return MainScreen(key: MainScreen.globalKey);
    } catch (e) {
      debugPrint('[SplashScreen] 사용자 정보 로드 실패: $e');
      return const LoginScreen();
    }
  }

  @override
  void dispose() {
    _loginTransitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.transparent,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Stack(
          children: [
            // 로그인 UI (애니메이션 중에만 표시)
            if (_showLoginUI)
              FadeTransition(
                opacity: _loginUIFadeAnim,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 112.h), // 로고 SVG 높이(112h)만큼 공간 확보 — AnimatedBuilder의 로고와 수직 정렬 맞춤
                      SizedBox(height: 45.h),
                      Text(
                        '손쉬운 물건 교환',
                        style: CustomTextStyles.p1.copyWith(
                          color: AppColors.textColorWhite.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 17.h),
                      SvgPicture.asset('assets/images/login-romrom-text.svg', width: 124.w, height: 17.h),
                      SizedBox(height: 174.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: AuthButtonGroup(
                          buttons: LoginPlatforms.values.map((platform) => LoginButton(platform: platform)).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 로고 (항상 표시, 전환 단계엔 이동)
            AnimatedBuilder(
              animation: _loginTransitionController,
              builder: (context, child) {
                return Align(alignment: _logoAlignmentAnim.value, child: child);
              },
              child: SvgPicture.asset('assets/images/romrom-logo.svg', width: 108.w, height: 112.h),
            ),
          ],
        ),
      ),
    );
  }
}
