import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/onboarding_flow_screen.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/firebase_service.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    unawaited(_initAndNavigate());
  }

  Future<void> _initAndNavigate() async {
    try {
      final screenFuture = _determineInitialScreen();
      await Future.wait([screenFuture, Future.delayed(const Duration(seconds: 2))]);
      final nextScreen = await screenFuture;

      if (!mounted) return;

      context.navigateTo(screen: nextScreen, type: NavigationTypes.pushAndRemoveUntil);
    } catch (e) {
      debugPrint('[SplashScreen] 초기화 실패: $e');
      if (!mounted) return;
      context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.pushAndRemoveUntil);
    }
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Align(
            // 로고 중심: 화면 중앙에서 32px 위
            alignment: const Alignment(0, -0.075),
            child: SvgPicture.asset('assets/images/romrom-logo.svg', width: 108.w, height: 112.h),
          ),
        ),
      ),
    );
  }
}
