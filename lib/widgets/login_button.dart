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
import 'package:romrom_fe/services/google_auth_service.dart';
import 'package:romrom_fe/services/kakao_auth_service.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 버튼
class LoginButton extends StatelessWidget {
  LoginButton({
    super.key,
    required this.platform,
  });

  final LoginPlatforms platform;
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  /// 버튼 눌렀을 때 로그인 처리 함수
  Future<void> handleLogin(BuildContext context) async {
    try {
      bool isSuccess = false;

      switch (platform) {
        // 카카오 로그인
        case LoginPlatforms.kakao:
          isSuccess = await kakaoAuthService.loginWithKakao();
          break;
        // 구글 로그인
        case LoginPlatforms.google:
          isSuccess = await googleAuthService.logInWithGoogle();
          break;
      }

      if (isSuccess) {
        var userInfo = UserInfo();
        await userInfo.getUserInfo(); // 사용자 정보 불러오기

        final prefs = await SharedPreferences.getInstance();
        
        // 첫 로그인인 경우에만 코치마크 설정 초기화
        if (userInfo.isFirstLogin == true) {
          // 첫 로그인 시 코치마크 표시를 위한 설정
          await prefs.setBool('isFirstMainScreen', true);
          // 다음부터 보지 않기 설정 초기화 (첫 사용자는 무조건 봐야 함)
          await prefs.setBool('dontShowCoachMark', false);
          debugPrint('첫 로그인: 코치마크 설정 초기화');
        } else {
          // 기존 사용자의 경우 설정 유지 (필요시에만 설정)
          if (!prefs.containsKey('isFirstMainScreen')) {
            await prefs.setBool('isFirstMainScreen', false);
          }
          debugPrint('기존 사용자: 코치마크 설정 유지');
        }
        
        // 다음 화면 결정
        Widget nextScreen;
        if (userInfo.needsOnboarding) {
          // 온보딩이 필요한 경우
          nextScreen = OnboardingFlowScreen(
            initialStep: userInfo.nextOnboardingStep,
          );
        } else {
          // 온보딩이 완료된 경우
          nextScreen = const MainScreen();
        }
        
        // 모든 비동기 작업 완료 후 context 확인
        if (context.mounted) {
          context.navigateTo(
            screen: nextScreen,
            type: NavigationTypes.pushReplacement,
          );
        }
      }
    } catch (e) {
      debugPrint("로그인 처리 중 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await handleLogin(context);
      },
      child: Container(
        width: 316.w,
        height: 56.h,
        margin: EdgeInsets.only(bottom: 12.h), // 버튼 세로 간격
        decoration: BoxDecoration(
          color: platform.backgroundColor, // 배경색
          borderRadius: BorderRadius.circular(100.r), // 둥근 모서리
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              left: 70.w,
              child: SvgPicture.asset(
                platform.iconPath,
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
                platform.displayText,
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
