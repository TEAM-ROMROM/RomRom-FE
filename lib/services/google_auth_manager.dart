import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/api/auth_api.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';

/// 구글 로그인 서비스 class
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> getGoogleUserInfo(GoogleSignInAccount googleUser) async {
    try {
      debugPrint(
          '사용자 정보 요청 성공: 닉네임: ${googleUser.displayName}, 이메일: ${googleUser.email}, 프로필 이미지: ${googleUser.photoUrl}');

      // 사용자 정보 저장
      UserInfo().saveUserInfo(
          '${googleUser.displayName}', googleUser.email, googleUser.photoUrl);
      // 로그인 플랫폼(Google) 저장
      LoginPlatformManager().saveLoginPlatform(loginPlatforms.google.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 구글 로그인
  Future<bool> logInWithGoogle() async {
    try {
      // 구글로 로그인 진행
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return false; // 사용자가 로그인 취소 시 false 반환
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleUser.authentication;

      // 구글 OAuth2 토큰 받음
      final String googleAccessToken = googleSignInAuthentication.accessToken!;
      debugPrint('구글로 로그인 성공: $googleAccessToken');

      await getGoogleUserInfo(googleUser);

      // 구글 로그인 성공 후 토큰 발급
      await signInWithSocial(socialPlatform: loginPlatforms.google.platformName);
      return true; // 성공 시 true 반환
    } catch (error) {
      debugPrint('구글로 로그인 실패: $error');
      return false; // 실패 시 false 반환
    }
  }

  /// 구글 로그아웃
  Future<void> logOutWithGoogle() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('구글 로그아웃 성공');
      // 로그인 플랫폼 정보 삭제
      await LoginPlatformManager().deleteLoginPlatform();
    } catch (error) {
      debugPrint('구글 로그아웃 실패: $error');
    }
  }
}
