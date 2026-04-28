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
  late AnimationController _loginTransitionController;
  late Animation<Alignment> _logoAlignmentAnim;
  late Animation<double> _loginUIFadeAnim;
  bool _showLoginUI = false;
  bool _loginTransitionStarted = false;

  @override
  void initState() {
    super.initState();

    _loginTransitionController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));

    // 로고 이동: 화면 중앙(-0.075) → 로그인 화면 로고 위치
    // end 값은 postFrameCallback에서 실제 레이아웃 측정값으로 교체됨
    _logoAlignmentAnim = AlignmentTween(
      begin: const Alignment(0, -0.075),
      end: const Alignment(0, -0.52),
    ).animate(CurvedAnimation(parent: _loginTransitionController, curve: Curves.easeInOut));

    // 로그인 UI fade in: 30~100% 구간
    _loginUIFadeAnim = CurvedAnimation(
      parent: _loginTransitionController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    unawaited(_initAndNavigate());
  }

  Future<void> _initAndNavigate() async {
    try {
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
      await _playLoginTransitionAnimation();
    }
  }

  /// 로고 이동 + 로그인 UI fade in.
  /// LoginScreen으로 교체하지 않음 — 스플래시 자체가 로그인 화면 역할을 함.
  /// clearStackImmediate 교체가 없으므로 순간이동 현상이 원천 차단됨.
  Future<void> _playLoginTransitionAnimation() async {
    if (!mounted || _loginTransitionStarted) return;
    _loginTransitionStarted = true;

    setState(() => _showLoginUI = true);

    // 로그인 UI가 렌더링된 후 실제 로고 위치를 측정하여 애니메이션 end값 교체
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        completer.complete();
        return;
      }
      final endY = _calculateLoginLogoAlignmentY(context);
      _logoAlignmentAnim = AlignmentTween(
        begin: const Alignment(0, -0.075),
        end: Alignment(0, endY),
      ).animate(CurvedAnimation(parent: _loginTransitionController, curve: Curves.easeInOut));
      completer.complete();
    });
    await completer.future;
    if (!mounted) return;

    await _loginTransitionController.forward();
  }

  /// Scaffold.body(Stack) 기준으로 로고의 최종 Alignment Y를 계산한다.
  /// Align의 좌표계는 부모(Stack = Scaffold.body)의 크기 기준이므로
  /// screenHeight 대신 MediaQuery에서 padding을 뺀 실제 body 높이를 사용한다.
  double _calculateLoginLogoAlignmentY(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Scaffold.body의 실제 높이 = 전체 화면 - 상단 padding(status bar)
    // (Scaffold는 기본적으로 body를 status bar 아래부터 배치)
    final bodyHeight = mq.size.height - mq.padding.top;
    final logoSize = 108.w;

    // 로그인 화면(LoginScreen)과 동일한 레이아웃 수치
    final fixedBelowLogo = 45.h + 16.sp + 17.h + 17.h;
    final buttonCount = Platform.isIOS ? 3 : 2;
    final buttonGroupHeight = buttonCount * 56.h + (buttonCount - 1) * 12.h;
    final totalFixed = logoSize + fixedBelowLogo + buttonGroupHeight + 48.h;

    // SafeArea가 제거하는 top/bottom padding
    final safeTop = mq.padding.top;
    final safeBottom = mq.padding.bottom;
    final safeAreaHeight = mq.size.height - safeTop - safeBottom;

    final spacerTotal = safeAreaHeight - totalFixed;
    final topSpacerHeight = spacerTotal * 2 / 5;

    // 로고 중심 Y — body(Scaffold.body = status bar 아래) 기준
    final logoCenterY = safeTop + topSpacerHeight + logoSize / 2;

    // Align Y: Scaffold.body(=bodyHeight) 기준
    // Align Y = (logoCenterY_in_body / (bodyHeight / 2)) - 1
    final logoCenterInBody = logoCenterY - mq.padding.top; // body 안에서의 상대 Y
    return (logoCenterInBody / (bodyHeight / 2)) - 1;
  }

  Future<Widget> _determineInitialScreen() async {
    final romAuthApi = RomAuthApi();
    final tokenManager = TokenManager();
    final String? refreshToken = await tokenManager.getRefreshToken();

    if (refreshToken == null) return const LoginScreen();

    final isLoggedIn = await romAuthApi.refreshAccessToken();
    if (!isLoggedIn) return const LoginScreen();

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
                      SizedBox(height: 108.w), // 로고 자리 확보
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

            // 로고: 항상 Align으로 표시, 애니메이션 중 이동
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
