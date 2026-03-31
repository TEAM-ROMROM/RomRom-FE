import 'dart:async';
import 'dart:io';

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
import 'package:romrom_fe/enums/app_update_type.dart';
import 'package:romrom_fe/screens/app_update_screen.dart';
import 'package:romrom_fe/services/apis/app_version_api.dart';
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

  /// 로그인 화면의 실제 레이아웃(SafeArea + Spacer)을 기반으로
  /// 로고 중심의 Alignment Y값을 계산한다.
  /// 로그인 화면: SafeArea > Column > Spacer(2) + 로고(108w) + 45h + text + 17h + text + Spacer(3) + 버튼그룹 + 48h
  double _calculateLoginLogoAlignmentY(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    final logoSize = 108.w;
    // 로고 아래 고정 콘텐츠 높이:
    //   SizedBox(45.h) + Text('손쉬운 물건 교환', p1=16.sp) + SizedBox(17.h)
    //   + SvgPicture(login-romrom-text, 17.h) + SizedBox(48.h, 하단 여백)
    final fixedContentHeight = 45.h + 16.sp + 17.h + 17.h + 48.h;
    final buttonCount = Platform.isIOS ? 3 : 2;
    // LoginButton 높이 56.h, AuthButtonGroup 간격 12.h (login_button.dart, auth_button_group.dart 기준)
    final buttonGroupHeight = buttonCount * 56.h + (buttonCount - 1) * 12.h;
    final safeAreaHeight = screenHeight - topPadding - bottomPadding;
    final spacerTotalHeight = safeAreaHeight - logoSize - fixedContentHeight - buttonGroupHeight;
    final topSpacerHeight = spacerTotalHeight * 2 / 5; // Spacer(flex:2) / 총 flex(5)

    // 로고 중심 Y (화면 top 기준)
    final logoCenterY = topPadding + topSpacerHeight + logoSize / 2;

    // Alignment Y: -1 = 화면 top, 0 = 화면 center, 1 = 화면 bottom
    return (logoCenterY / (screenHeight / 2)) - 1;
  }

  @override
  void initState() {
    super.initState();

    _loginTransitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    // 로고: 중앙(-0.075) → 임시값(-0.52), postFrameCallback에서 동적 계산값으로 교체됨
    _logoAlignmentAnim = AlignmentTween(
      begin: const Alignment(0, -0.075),
      end: const Alignment(0, -0.52),
    ).animate(CurvedAnimation(parent: _loginTransitionController, curve: Curves.easeInOut));

    // 로그인 UI: 0 → 1 (30~100% 구간에서 fade in)
    _loginUIFadeAnim = CurvedAnimation(
      parent: _loginTransitionController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    // 로그인 화면의 실제 로고 위치를 계산하여 애니메이션 end값 교체
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final endY = _calculateLoginLogoAlignmentY(context);
      _logoAlignmentAnim = AlignmentTween(
        begin: const Alignment(0, -0.075),
        end: Alignment(0, endY),
      ).animate(CurvedAnimation(parent: _loginTransitionController, curve: Curves.easeInOut));
    });

    unawaited(_initAndNavigate());
  }

  Future<void> _initAndNavigate() async {
    try {
      // 버전 체크 (API 실패 시 스킵 — 앱 진입 차단 방지)
      final updateType = await AppVersionApi().checkUpdateType();
      if (updateType == UpdateType.force && mounted) {
        context.navigateTo(screen: const AppUpdateScreen(), type: NavigationTypes.fadeTransition);
        return;
      }

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
            // 로그인 UI (애니메이션 중에만 표시) — 로그인 화면과 동일한 SafeArea + Spacer 구조
            if (_showLoginUI)
              FadeTransition(
                opacity: _loginUIFadeAnim,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Spacer(flex: 2),
                      SizedBox(height: 108.w), // 로고 자리 확보 (AnimatedBuilder의 로고와 동일 크기)
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
                      const Spacer(flex: 3),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: AuthButtonGroup(
                          buttons: [
                            LoginPlatforms.kakao,
                            if (Platform.isIOS) LoginPlatforms.apple,
                            LoginPlatforms.google,
                          ].map((platform) => LoginButton(platform: platform)).toList(),
                        ),
                      ),
                      SizedBox(height: 48.h),
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
              child: SvgPicture.asset('assets/images/romrom-logo.svg', width: 108.w, height: 108.w),
            ),
          ],
        ),
      ),
    );
  }
}
