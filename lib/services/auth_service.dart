// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/apple_auth_service.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/google_auth_service.dart';
import 'package:romrom_fe/services/kakao_auth_service.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';

class AuthService {
  final TokenManager _tokenManager = TokenManager();
  final RomAuthApi _romAuthApi = RomAuthApi();

  /// 로그아웃 처리 메소드
  Future<void> logout(BuildContext context) async {
    try {
      await _romAuthApi.logout();
    } catch (e) {
      debugPrint('로그아웃 중 오류 발생: $e');
    } finally {
      await _performPlatformLogout();
      await _tokenManager.deleteTokens();
      HeartbeatManager.instance.stop();
      ApiClient.resetSuspendedFlag();
      ApiClient.resetSessionExpiredFlag();
      if (context.mounted) {
        context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.pushAndRemoveUntil);
      }
    }
  }

  /// 회원 탈퇴 처리 메소드
  /// 성공 시 true, 실패 시 false 반환 (화면 이동은 호출부에서 처리)
  Future<bool> deleteAccount() async {
    final isSuccess = await MemberApi().deleteMember();
    if (!isSuccess) return false;

    // 탈퇴 성공 즉시 HeartbeatManager 중지 (Apple 재인증 시 앱 복귀로 인한 403 방지)
    HeartbeatManager.instance.stop();

    final String? platform = await LoginPlatformManager().getLoginPlatform();

    // Apple: 탈퇴 전 반드시 Apple 토큰 취소 (Apple 정책 필수)
    // 실패해도 로컬 탈퇴 처리는 계속 진행
    if (platform == LoginPlatforms.apple.platformName) {
      try {
        await AppleAuthService().revokeAppleToken();
      } catch (e) {
        debugPrint('Apple 토큰 취소 실패 (탈퇴 처리는 계속): $e');
      }
    }

    // Firebase 계정 삭제 (signOut 전에 수행해야 함)
    try {
      await FirebaseAuth.instance.currentUser?.delete();
    } catch (e) {
      debugPrint('Firebase 계정 삭제 실패 (탈퇴 처리는 계속): $e');
    }

    // 플랫폼별 소셜 연결 해제 (내부에서 Firebase signOut + 로그인 플랫폼 삭제 처리)
    await _performPlatformWithdraw(platform);

    // 토큰 삭제
    await _tokenManager.deleteTokens();

    // 사용자 정보 클리어 (회원탈퇴는 새 사용자이므로 isCoachMarkShown, isFirstMainScreen 포함 전체 초기화)
    await UserInfo().clearAllUserInfo();

    return true;
  }

  /// 플랫폼별 소셜 연결 해제 (회원 탈퇴 시)
  Future<void> _performPlatformWithdraw(String? platform) async {
    if (platform == LoginPlatforms.apple.platformName) {
      await AppleAuthService().logOutWithApple();
    } else if (platform == LoginPlatforms.google.platformName) {
      await GoogleAuthService().logOutWithGoogle();
    } else if (platform == LoginPlatforms.kakao.platformName) {
      await KakaoAuthService().unlinkKakao();
    }
  }

  /// 플랫폼별 소셜 로그아웃 처리
  Future<void> _performPlatformLogout() async {
    final String? platform = await LoginPlatformManager().getLoginPlatform();
    if (platform == LoginPlatforms.google.platformName) {
      await GoogleAuthService().logOutWithGoogle();
    } else if (platform == LoginPlatforms.kakao.platformName) {
      await KakaoAuthService().logoutWithKakao();
    } else if (platform == LoginPlatforms.apple.platformName) {
      await AppleAuthService().logOutWithApple();
    }
  }
}
