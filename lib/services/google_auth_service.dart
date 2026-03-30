import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/email_already_registered_exception.dart';
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
      await UserInfo().saveUserInfo('${googleUser.displayName}', googleUser.email);
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

      final String? idToken = googleUser.authentication.idToken;

      // accessToken은 authorizationClient를 통해 별도로 가져옴
      final authorization =
          await googleUser.authorizationClient.authorizationForScopes(['email', 'profile']) ??
          await googleUser.authorizationClient.authorizeScopes(['email', 'profile']);
      final String accessToken = authorization.accessToken;

      debugPrint('구글로 로그인 성공: idToken=$idToken');

      // OAuthCredential 생성
      final OAuthCredential googleCredential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      // firebase Auth에 객체 저장
      final UserCredential credential = await FirebaseAuth.instance.signInWithCredential(googleCredential);
      if (credential.user != null) {
        debugPrint('Firebase 로그인 성공: ${credential.user}');
      }

      // Firebase ID 토큰 취득
      final String firebaseIdToken = await credential.user?.getIdToken() ?? '';

      await getGoogleUserInfo(googleUser);

      // 구글 로그인 성공 후 토큰 발급
      await romAuthApi.signInWithSocial(firebaseIdToken: firebaseIdToken, providerId: 'google.com');
      return true;
    } on AccountSuspendedException {
      rethrow;
    } on EmailAlreadyRegisteredException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' && e.email != null) {
        debugPrint('Firebase 이메일 중복 감지: ${e.email}');
        String? platform;
        try {
          final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(e.email!);
          debugPrint('기존 가입 provider: $methods');
          platform = LoginPlatforms.platformNameFromFirebaseProvider(methods.isNotEmpty ? methods.first : '');
        } catch (_) {
          debugPrint('fetchSignInMethodsForEmail 실패');
        }
        throw EmailAlreadyRegisteredException(registeredSocialPlatform: platform ?? '');
      }
      debugPrint('구글로 로그인 실패: $e');
      return false;
    } catch (error) {
      debugPrint('구글로 로그인 실패: $error');
      return false;
    }
  }

  /// 구글 로그아웃
  Future<void> logOutWithGoogle() async {
    try {
      await _googleSignIn.disconnect();
      await FirebaseAuth.instance.signOut();
      debugPrint('구글 로그아웃 성공');
      // 로그인 플랫폼 정보 삭제
      await LoginPlatformManager().deleteLoginPlatform();
    } catch (error) {
      debugPrint('구글 로그아웃 실패: $error');
    }
  }
}
