// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/apis/social_logout_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class AuthService {
  final TokenManager _tokenManager = TokenManager();
  final RomAuthApi _romAuthApi = RomAuthApi();
  final SocialLogoutService _socialLogoutService = SocialLogoutService();

  // 로그아웃 처리 메소드
  Future<void> logout(BuildContext context) async {
    try {
      // 서버에 로그아웃 요청
      await _romAuthApi.logoutWithSocial(context);
    } catch (e) {
      debugPrint('로그아웃 중 오류 발생: $e');
    } finally {
      // 소셜 플랫폼 로그아웃 처리
      await _socialLogoutService.performSocialLogout();

      // 토큰 삭제
      await _tokenManager.deleteTokens();

      // 로그인 화면으로 이동
      if (context.mounted) {
        context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.pushAndRemoveUntil);
      }
    }
  }
}
