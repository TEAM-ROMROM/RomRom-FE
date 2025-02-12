import 'package:flutter/material.dart';

import 'package:romrom_fe/models/platforms.dart';
import 'package:romrom_fe/services/google_auth_manager.dart';
import 'package:romrom_fe/services/kakao_auth_manager.dart';

/// 로그인 버튼
class LoginButton extends StatelessWidget {
  LoginButton({
    super.key,
    required this.platform,
  });

  final Platforms platform;
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  /// 버튼 눌렀을 때 로그인 처리 함수
  void handleLogin() {
    switch (platform) {
      // 카카오 로그인
      case Platforms.KAKAO:
        kakaoAuthService.signInWithKakao();
        break;
      // 구글 로그인
      case Platforms.GOOGLE:
        googleAuthService.checkAndSignInWithGoogle();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleLogin,
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

  final Platforms platform;
  final KakaoAuthService kakaoAuthService = KakaoAuthService();
  final GoogleAuthService googleAuthService = GoogleAuthService();

  /// 버튼 눌렀을 때 로그아웃 처리 함수
  void handleLogout() {
    switch (platform) {
      case Platforms.KAKAO:
        // 카카오 로그아웃 처리
        kakaoAuthService.logoutWithKakaoAccount();
        break;
      case Platforms.GOOGLE:
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
