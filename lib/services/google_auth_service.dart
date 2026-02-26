import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';

/// 구글 로그인 서비스 class
class GoogleAuthService {
  // 싱글톤 구현
  static final GoogleAuthService _instance = GoogleAuthService._internal();
  factory GoogleAuthService() => _instance;
  GoogleAuthService._internal();
  final romAuthApi = RomAuthApi();

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  Future<void> getGoogleUserInfo(GoogleSignInAccount googleUser) async {
    try {
      debugPrint(
        '사용자 정보 요청 성공: 닉네임: ${googleUser.displayName}, 이메일: ${googleUser.email}, 프로필 이미지: ${googleUser.photoUrl}',
      );

      // 사용자 정보 저장
      await UserInfo().saveUserInfo('${googleUser.displayName}', googleUser.email, googleUser.photoUrl);
      // 로그인 플랫폼(Google) 저장
      LoginPlatformManager().saveLoginPlatform(LoginPlatforms.google.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 구글 로그인
  Future<bool> logInWithGoogle() async {
    try {
      // 구글로 로그인 진행
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleSignInAuthentication = googleUser.authentication;
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

      // 구글 OAuth2 토큰 받음
      final String googleAccessToken = googleSignInAuthentication.idToken!;
      debugPrint('구글로 로그인 성공: $googleAccessToken');

      // OAuthCredential 생성
      OAuthCredential googleCredential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleAccessToken,
      );

      // firebase Auth에 객체 저장
      UserCredential credential = await firebaseAuth.signInWithCredential(googleCredential);
      if (credential.user != null) {
        final user = credential.user;
        debugPrint('$user');
      }

      await getGoogleUserInfo(googleUser);

      // 구글 로그인 성공 후 토큰 발급
      await romAuthApi.signInWithSocial(socialPlatform: LoginPlatforms.google.platformName);
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
