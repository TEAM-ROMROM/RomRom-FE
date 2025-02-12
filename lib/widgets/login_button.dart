import 'package:flutter/material.dart';
import 'package:romrom_fe/models/platforms.dart';
import '../services/kakao_auth_service.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({
    super.key,
    required this.platform,
  });

  final Platforms platform;

  // 버튼 눌렀을 때 로그인 처리 함수
  void handleLogin() {
    switch (platform) {
      case Platforms.KAKAO:
        final KakaoAuthService kakaoAuthService = KakaoAuthService();
        kakaoAuthService.signInWithKakao();
        break;
      case Platforms.GOOGLE:
      // 구글 로그인 로직 처리
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

// 테스트용 로그아웃 버튼
class LogoutButton extends StatelessWidget {
  const LogoutButton({
    super.key,
    required this.platform,
  });

  final Platforms platform;

  // 버튼 눌렀을 때 로그아웃 처리 함수
  void handleLogout() {
    switch (platform) {
      case Platforms.KAKAO:
        final KakaoAuthService kakaoAuthService = KakaoAuthService();
        kakaoAuthService.logoutWithKakaoAccount();
        break;
      case Platforms.GOOGLE:
      // 구글 로그아웃 로직 처리
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
