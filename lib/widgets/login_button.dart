import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/main_screen.dart';
import 'package:romrom_fe/screens/onboarding/onboarding_flow_screen.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/google_auth_service.dart';
import 'package:romrom_fe/services/kakao_auth_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 버튼
class LoginButton extends StatefulWidget {
  const LoginButton({
    super.key,
    required this.platform,
  });

  final LoginPlatforms platform;

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();
  bool _isLoading = false;

  Future<void> handleLogin(BuildContext context) async {
    if (_isLoading) return; // 이미 로그인 중이면 무시
    setState(() => _isLoading = true);

    try {
      bool isSuccess = false;

      switch (widget.platform) {
        case LoginPlatforms.kakao:
          isSuccess = await kakaoAuthService.loginWithKakao();
          break;
        case LoginPlatforms.google:
          isSuccess = await googleAuthService.logInWithGoogle();
          break;
      }

      if (!mounted) return; // 로그인 완료 후 context가 유효한지 체크

      if (isSuccess) {
        var userInfo = UserInfo();
        await userInfo.getUserInfo();

        final prefs = await SharedPreferences.getInstance();

        if (userInfo.isFirstLogin == true) {
          await prefs.setBool('isFirstMainScreen', true);
          await prefs.setBool('dontShowCoachMark', false);
          
        } else {
          if (!prefs.containsKey('isFirstMainScreen')) {
            await prefs.setBool('isFirstMainScreen', false);
          }
        }

        Widget nextScreen;
        if (userInfo.needsOnboarding) {
          nextScreen = OnboardingFlowScreen(
            initialStep: userInfo.nextOnboardingStep,
          );
        } else {
          await RomAuthApi().fetchAndSaveMemberInfo();
          nextScreen = MainScreen(key: MainScreen.globalKey);
        }

        if (context.mounted) {
          context.navigateTo(
            screen: nextScreen,
            type: NavigationTypes.pushReplacement,
          );
        }
      }
    } catch (e) {
      debugPrint("로그인 처리 중 오류: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLoading
          ? null
          : () async {
              await handleLogin(context);
            },
      child: Container(
        width: double.infinity,
        height: 56.h,
        margin: EdgeInsets.only(bottom: 12.h),
        decoration: BoxDecoration(
          color: widget.platform.backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 70.w,
              child: SvgPicture.asset(
                widget.platform.iconPath,
                width: 22.h,
                height: 22.h,
                placeholderBuilder: (context) => Icon(
                  Icons.error,
                  size: 24.sp,
                  color: Colors.red,
                ),
              ),
            ),
            Center(
              child: Text(
                widget.platform.displayText,
                style: CustomTextStyles.p2.copyWith(
                    color: AppColors.textColorBlack,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 테스트용 로그아웃 버튼
class LogoutButton extends StatelessWidget {
  LogoutButton({
    super.key,
    required this.platform,
  });

  final LoginPlatforms platform;
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  /// 버튼 눌렀을 때 로그아웃 처리 함수
  void handleLogout() async {
    switch (platform) {
      case LoginPlatforms.kakao:
        // 카카오 로그아웃 처리
        kakaoAuthService.logoutWithKakaoAccount();
        break;
      case LoginPlatforms.google:
        // 구글 로그아웃 로직 처리
        googleAuthService.logOutWithGoogle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleLogout,
      child: Container(
        width: 150,
        height: 30,
        color: platform.backgroundColor.withValues(alpha: 0.5),
        alignment: Alignment.center,
        child: Text(platform.name),
      ),
    );
  }
}
