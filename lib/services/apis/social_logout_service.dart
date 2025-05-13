// lib/services/social_logout_service.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

// 순환참조 오류 -> 로그아웃 서비스
class SocialLogoutService {
  static final SocialLogoutService _instance = SocialLogoutService._internal();
  factory SocialLogoutService() => _instance;
  SocialLogoutService._internal();

  final TokenManager _tokenManager = TokenManager();
  final LoginPlatformManager _loginPlatformManager = LoginPlatformManager();

  static const String baseUrl = "https://api.romrom.xyz";

  /// 로그아웃 처리 (서버 API 호출 + 소셜 로그아웃)
  Future<void> logout(BuildContext context) async {
    const String url = '$baseUrl/api/auth/logout';
    try {
      await ApiClient.sendMultipartRequest(
        url: url,
        fields: {
          TokenKeys.accessToken.name: await _tokenManager.getAccessToken(),
          TokenKeys.refreshToken.name: await _tokenManager.getRefreshToken(),
        },
        isAuthRequired: true,
        onSuccess: (responseData) async {
          // 토큰 삭제
          await _tokenManager.deleteTokens();

          // 소셜 플랫폼별 로그아웃 처리
          await performSocialLogout();

          // 로그인화면으로 이동
          // ignore: use_build_context_synchronously
          context.navigateTo(screen: const LoginScreen());
        },
      );
    } catch (error) {
      debugPrint("로그아웃 실패: $error");
      throw Exception('Error during log-out: $error');
    }
  }

  /// 소셜 로그아웃 처리 함수 (소셜 서비스에서 호출)
  Future<void> performSocialLogout() async {
    String? platform = await _loginPlatformManager.getLoginPlatform();
    if (platform != null) {
      await _loginPlatformManager.deleteLoginPlatform();
    }
  }
}