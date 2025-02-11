import 'package:flutter/material.dart';
import '../services/kakao_auth_service.dart';

class LoginButton extends StatelessWidget {
  LoginButton({
    super.key,
    required this.platform,
  });

  String platform;

  // 버튼 눌렀을 때 로그인 처리 함수
  void handleLogin() {
    if (platform == 'kakao') {
      final KakaoAuthService kakaoAuthService = KakaoAuthService();
      kakaoAuthService.signInWithKakao();
    } else {
      // 구글 로그인 로직 처리
    }
  }

  Map<String, Color> platformColors = {
    'kakao': const Color(0xFFFFE812), // 카카오 노란색 (정확한 코드 사용)
    'google': const Color(0xFF4285F4), // 구글 파란색
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleLogin,
      child: Container(
        width: 150,
        height: 30,
        color: platformColors[platform],
        alignment: Alignment.center,
        child: Text(platform),
      ),
    );
  }
}

// 테스트용 로그아웃 버튼
class LogoutButton extends StatelessWidget {
  LogoutButton({
    super.key,
    required this.platform,
  });

  String platform;

  // 버튼 눌렀을 때 로그아웃 처리 함수
  void handleLogout() {
    if (platform == 'kakao') {
      final KakaoAuthService kakaoAuthService = KakaoAuthService();
      kakaoAuthService.logoutWithKakaoAccount();
    } else {
      // 구글 로그인 로직 처리
    }
  }

  Map<String, Color> platformColors = {
    'kakao': const Color.fromARGB(255, 111, 110, 71), // 카카오 노란색 (정확한 코드 사용)
    'google': const Color.fromARGB(255, 63, 75, 95), // 구글 파란색
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: handleLogout,
      child: Container(
        width: 150,
        height: 30,
        color: platformColors[platform],
        alignment: Alignment.center,
        child: Text(platform),
      ),
    );
  }
}
