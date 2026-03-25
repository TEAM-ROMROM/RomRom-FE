import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';

/// 애플 인증 관련 서비스
class AppleAuthService {
  static final AppleAuthService _instance = AppleAuthService._internal();
  factory AppleAuthService() => _instance;
  AppleAuthService._internal();

  final romAuthApi = RomAuthApi();

  static const String _appleTokenUrl = 'https://appleid.apple.com/auth/token';
  static const String _appleRevokeUrl = 'https://appleid.apple.com/auth/revoke';

  /// .env의 APPLE_PRIVATE_KEY를 ECPrivateKey가 파싱 가능한 PEM 형식으로 변환
  ///
  /// .env에서 개행이 리터럴 `\n`으로 저장되거나 단일 행으로 저장된 경우를 모두 처리
  String _formatPemKey(String rawKey) {
    // 리터럴 \n → 실제 개행 변환
    String key = rawKey.replaceAll(r'\n', '\n').trim();

    // 이미 개행이 포함된 올바른 PEM 형식이면 그대로 반환
    if (key.contains('\n-----')) return key;

    // 헤더·푸터 제거 후 base64 본문만 추출
    final body = key
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .trim();

    // PEM 표준(64자 줄바꿈)으로 재조립
    final buffer = StringBuffer('-----BEGIN PRIVATE KEY-----\n');
    for (int i = 0; i < body.length; i += 64) {
      buffer.writeln(body.substring(i, (i + 64).clamp(0, body.length)));
    }
    buffer.write('-----END PRIVATE KEY-----');
    return buffer.toString();
  }

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

  /// Apple Client Secret JWT 생성 (ES256)
  ///
  /// .env의 APPLE_TEAM_ID, APPLE_CLIENT_ID, APPLE_KEY_ID, APPLE_PRIVATE_KEY 필요
  String createClientSecret() {
    final String teamId = dotenv.get('APPLE_TEAM_ID');
    final String clientId = dotenv.get('APPLE_CLIENT_ID');
    final String keyId = dotenv.get('APPLE_KEY_ID');
    final String privateKey = _formatPemKey(dotenv.get('APPLE_PRIVATE_KEY'));

    final JWT jwt = JWT(
      {
        'iss': teamId,
        'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'exp': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600,
        'aud': 'https://appleid.apple.com',
        'sub': clientId,
      },
      header: {'kid': keyId},
    );

    return jwt.sign(ECPrivateKey(privateKey), algorithm: JWTAlgorithm.ES256);
  }

  /// authorization code → refresh token 교환
  Future<String?> _exchangeCodeForRefreshToken(String authorizationCode) async {
    final String clientId = dotenv.get('APPLE_CLIENT_ID');
    final String clientSecret = createClientSecret();

    final http.Response response = await http.post(
      Uri.parse(_appleTokenUrl),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'code': authorizationCode,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['refresh_token'] as String?;
    }

    debugPrint('Apple token exchange 실패: ${response.statusCode} ${response.body}');
    return null;
  }

  /// Apple refresh token 취소
  Future<void> revokeToken(String refreshToken) async {
    try {
      final String clientId = dotenv.get('APPLE_CLIENT_ID');
      final String clientSecret = createClientSecret();

      final http.Response response = await http.post(
        Uri.parse(_appleRevokeUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': clientId,
          'client_secret': clientSecret,
          'token': refreshToken,
          'token_type_hint': 'refresh_token',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('Apple 토큰 취소 성공');
      } else {
        debugPrint('Apple 토큰 취소 실패: ${response.statusCode} ${response.body}');
      }
    } catch (error) {
      debugPrint('Apple 토큰 취소 오류: $error');
    }
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
      await UserInfo().saveUserInfo(displayName, appleCredential.email ?? credential.user?.email);

      LoginPlatformManager().saveLoginPlatform(LoginPlatforms.apple.platformName);

      await romAuthApi.signInWithSocial(firebaseIdToken: firebaseIdToken, providerId: 'apple.com');

      debugPrint('애플 로그인 성공: ${credential.user?.uid}');
      return true;
    } on AccountSuspendedException {
      rethrow;
    } catch (error) {
      debugPrint('애플 로그인 실패: $error');
      return false;
    }
  }

  /// Apple 토큰 취소 (계정 탈퇴 시 필수)
  ///
  /// Apple 정책상 계정 삭제 시 반드시 Sign in with Apple 토큰을 취소해야 합니다.
  /// 재인증 → authorization code 발급 → refresh token 교환 → 직접 취소 순으로 처리합니다.
  Future<void> revokeAppleToken() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    // 재인증으로 새 authorizationCode 발급
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      nonce: nonce,
    );

    // authorization code → refresh token 교환 후 취소
    final String? refreshToken = await _exchangeCodeForRefreshToken(appleCredential.authorizationCode);
    if (refreshToken != null) {
      await revokeToken(refreshToken);
    } else {
      debugPrint('Apple refresh token 획득 실패 — 토큰 취소 건너뜀');
    }
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
