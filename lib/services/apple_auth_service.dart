import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';

/// 애플 인증 관련 서비스
class AppleAuthService {
  static final AppleAuthService _instance = AppleAuthService._internal();
  factory AppleAuthService() => _instance;
  AppleAuthService._internal();

  final romAuthApi = RomAuthApi();

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 애플 로그인
  Future<bool> logInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final identityToken = appleCredential.identityToken;
      if (identityToken == null) {
        throw Exception('Apple identity token is null');
      }

      final oauthCredential = OAuthProvider(
        'apple.com',
      ).credential(idToken: identityToken, accessToken: appleCredential.authorizationCode, rawNonce: rawNonce);

      final UserCredential credential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Firebase ID 토큰 취득
      final String firebaseIdToken = await credential.user?.getIdToken() ?? '';

      // 사용자 정보 저장 (애플은 최초 로그인 시에만 이름/이메일 제공)
      final displayName = (appleCredential.givenName != null || appleCredential.familyName != null)
          ? '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim()
          : credential.user?.displayName;
      await UserInfo().saveUserInfo(
        displayName,
        appleCredential.email ?? credential.user?.email,
        credential.user?.photoURL,
      );

      LoginPlatformManager().saveLoginPlatform(LoginPlatforms.apple.platformName);

      await romAuthApi.signInWithSocial(firebaseIdToken: firebaseIdToken, providerId: 'apple.com');

      debugPrint('애플 로그인 성공: ${credential.user?.uid}');
      return true;
    } catch (error) {
      debugPrint('애플 로그인 실패: $error');
      return false;
    }
  }

  /// Apple 토큰 취소 (계정 탈퇴 시 필수)
  ///
  /// Apple 정책상 계정 삭제 시 반드시 Sign in with Apple 토큰을 취소해야 합니다.
  /// 재인증으로 받은 authorizationCode를 Firebase를 통해 취소합니다.
  Future<void> revokeAppleToken() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // 재인증으로 새 authorizationCode 발급
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    // Firebase를 통해 Apple 토큰 취소
    await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(appleCredential.authorizationCode);

    debugPrint('Apple 토큰 취소 성공');
  }

  /// 애플 로그아웃
  Future<void> logOutWithApple() async {
    try {
      await FirebaseAuth.instance.signOut();
      await LoginPlatformManager().deleteLoginPlatform();
      debugPrint('애플 로그아웃 성공');
    } catch (error) {
      debugPrint('애플 로그아웃 실패: $error');
    }
  }
}
