import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/home_screen.dart';
import 'package:romrom_fe/screens/onboarding/location_verification_screen.dart';
import 'package:romrom_fe/services/google_auth_manager.dart';
import 'package:romrom_fe/services/kakao_auth_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

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
        await UserInfo().getUserInfo(); // 사용자 정보 불러오기

        // 처음 로그인 하면 위치 인증 화면으로 이동
        // ignore: use_build_context_synchronously
        context.navigateTo(
            screen: userInfo.isFirstLogin!
                ? const LocationVerificationScreen()
                : const HomeScreen(),
            type: NavigationTypes.pushReplacement);
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await handleLogin(context);
      },
      child: Container(
        width: 300,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 10), // 버튼 세로 간격
        decoration: BoxDecoration(
          color: platform.backgroundColor, // 배경색
          borderRadius: BorderRadius.circular(25), // 둥근 모서리
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘  //FIXME: 아이콘 전환 필요
            SvgPicture.asset(
              platform.iconPath,
              width: 25,
              height: 24,
              placeholderBuilder: (context) => const Icon(
                Icons.error,
                size: 24,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 10), // 아이콘 - 텍스트 간격
            // 로그인 플랫폼 변 텍스트 //FIXME: TextStyle 공통인것 사용 필요
            Text(
              platform.displayText,
              // style: const TextStyle(
              //   color: Colors.black,
              //   fontSize: 16,
              //   fontFamily: 'Pretendard',
              //   fontWeight: FontWeight.w500
              // ),
              // style: AppTheme.textStyles.customBody,
            )
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
