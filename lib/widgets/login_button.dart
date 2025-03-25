import 'package:flutter/material.dart';

import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/home_screen.dart';
import 'package:romrom_fe/screens/map_screen.dart';
import 'package:romrom_fe/services/google_auth_manager.dart';
import 'package:romrom_fe/services/kakao_auth_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

/// 로그인 버튼
class LoginButton extends StatelessWidget {
  LoginButton({
    super.key,
    required this.platform,
  });

  final loginPlatforms platform;
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  /// 버튼 눌렀을 때 로그인 처리 함수
  Future<void> handleLogin(BuildContext context) async {
    try {
      bool isSuccess = false;

      switch (platform) {
        // 카카오 로그인
        case loginPlatforms.kakao:
          isSuccess = await kakaoAuthService.loginWithKakao();
          break;
        // 구글 로그인
        case loginPlatforms.google:
          isSuccess = await googleAuthService.logInWithGoogle();
          break;
      }

      if (isSuccess) {
        var userInfo = UserInfo();
        await UserInfo().getUserInfo(); // 사용자 정보 불러오기

        // 처음 로그인 하면 위치 인증 화면으로 이동
        // ignore: use_build_context_synchronously
        context.navigateTo(
            screen:
                userInfo.isFirstLogin! ? const MapScreen() : const HomeScreen(),
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
        width: 150,
        height: 30,
        color: platform.color,
        alignment: Alignment.center,
        child: Text(platform.name),
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

  final loginPlatforms platform;
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  /// 버튼 눌렀을 때 로그아웃 처리 함수
  void handleLogout() async {
    switch (platform) {
      case loginPlatforms.kakao:
        // 카카오 로그아웃 처리
        kakaoAuthService.logoutWithKakaoAccount();

        break;
      case loginPlatforms.google:
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
        color: platform.color.withValues(alpha: 0.5),
        alignment: Alignment.center,
        child: Text(platform.name),
      ),
    );
  }
}
