import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:romrom_fe/models/platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';
import 'package:romrom_fe/services/social_auth_sign_in_service.dart';

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
      LoginPlatformManager().saveLoginPlatform(Platforms.google.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 로그인 유지 여부 확인 및 로그인 진행
  Future<void> checkAndSignInWithGoogle() async {
    try {
      GoogleSignInAccount? currentUser = _googleSignIn.currentUser;

      if (currentUser == null) {
        // 기존 로그인 정보가 없으면 로그인 진행
        await logInWithGoogle();
      } else {
        // 로그인 유지됨
        final GoogleSignInAuthentication auth =
            await currentUser.authentication;
        debugPrint('구글 로그인 유지됨: ${auth.accessToken}');
      }
    } catch (error) {
      debugPrint('로그인 상태 확인 중 오류 발생: $error');
    }
  }

  /// 구글 로그인
  Future<void> logInWithGoogle() async {
    try {
      // 구글로 로그인 진행
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleUser!.authentication;

      // 구글 OAuth2 토큰 받음
      final String googleAccessToken = googleSignInAuthentication.accessToken!;
      debugPrint('구글로 로그인 성공: $googleAccessToken');

      await getGoogleUserInfo(googleUser);

      // 구글 로그인 성공 후 토큰 발급
      await signInWithSocial(socialPlatform: Platforms.google.platformName);
    } catch (error) {
      debugPrint('구글로 로그인 실패: $error');
    }
  }

  /// 구글 로그아웃
  Future<void> logOutWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('구글 로그아웃 성공');
    } catch (error) {
      debugPrint('구글 로그아웃 실패: $error');
    }
  }
}
