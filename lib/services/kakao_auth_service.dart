import 'package:firebase_auth/firebase_auth.dart' hide UserInfo, User;
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';

import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/email_already_registered_exception.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';

/// 카카오 인증 관련 서비스
class KakaoAuthService {
  // 싱글톤 구현
  static final KakaoAuthService _instance = KakaoAuthService._internal();
  factory KakaoAuthService() => _instance;
  KakaoAuthService._internal();
  final romAuthApi = RomAuthApi();

  // us**@exam***.com 형식으로 마스킹
  static String _maskEmail(String? email) {
    if (email == null) return 'null';
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return '***@***';
    final local = email.substring(0, atIndex);
    final domain = email.substring(atIndex + 1);
    final maskedLocal = local.length > 2 ? '${local.substring(0, 2)}**' : '**';
    final dotIndex = domain.lastIndexOf('.');
    final maskedDomain = dotIndex > 0 ? '${domain[0]}***${domain.substring(dotIndex)}' : '***';
    return '$maskedLocal@$maskedDomain';
  }

  // kakao:123456789 → kakao:123*** 형식으로 마스킹
  static String _maskUid(String? uid) {
    if (uid == null) return 'null';
    final colonIndex = uid.indexOf(':');
    if (colonIndex >= 0 && uid.length > colonIndex + 4) {
      return '${uid.substring(0, colonIndex + 4)}***';
    }
    return uid.length > 4 ? '${uid.substring(0, 4)}***' : '****';
  }

  /// 사용자 정보 가져오기
  Future<void> getKakaoUserInfo() async {
    try {
      User user = await UserApi.instance.me();

      debugPrint(
        '사용자 정보 요청 성공: 이메일: ${_maskEmail(user.kakaoAccount?.email)}, 닉네임: ${user.kakaoAccount?.profile?.nickname}, 프로필 이미지: (hidden)',
      );

      // 사용자 정보 저장
      await UserInfo().saveUserInfo(user.kakaoAccount?.profile?.nickname ?? '', user.kakaoAccount?.email ?? '');
      // 로그인 플랫폼 저장
      LoginPlatformManager().saveLoginPlatform(LoginPlatforms.kakao.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 백엔드 발급 Custom Token으로 Firebase 로그인
  ///
  /// [kakaoEmail]은 기존 카카오 회원 매칭을 위한 fallback 식별자 (nullable)
  Future<void> _signInWithFirebaseCustomToken({required String kakaoAccessToken, String? kakaoEmail}) async {
    try {
      debugPrint('[KakaoAuth] /kakao/firebase-token 요청: email=${_maskEmail(kakaoEmail)}');
      final String customToken = await romAuthApi.getKakaoFirebaseToken(
        kakaoAccessToken: kakaoAccessToken,
        email: kakaoEmail,
      );

      // Custom Token으로 Firebase 로그인 (UID = kakao:{카카오회원번호} 고정)
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCustomToken(customToken);
      debugPrint('[KakaoAuth] Firebase 로그인 성공: uid=${_maskUid(userCredential.user?.uid)}');
    } catch (error) {
      debugPrint('Firebase Custom Token 로그인 실패: $error');
      rethrow;
    }
  }

  /// 로그인 성공 후 후처리 함수
  Future<void> _handleLoginSuccess({required OAuthToken token, String? kakaoEmail}) async {
    debugPrint('카카오 로그인 성공');

    await _signInWithFirebaseCustomToken(kakaoAccessToken: token.accessToken, kakaoEmail: kakaoEmail);

    // Firebase ID 토큰 취득
    final String firebaseIdToken = await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';

    await getKakaoUserInfo();
    await romAuthApi.signInWithSocial(firebaseIdToken: firebaseIdToken, providerId: 'kakao');
  }

  /// 카카오 로그인
  ///
  /// 카카오톡 설치 시 앱 로그인, 미설치 시 인앱 웹 로그인으로 자동 전환
  Future<bool> loginWithKakao(BuildContext context) async {
    if (await isKakaoTalkInstalled()) {
      return await loginWithKakaoTalk();
    } else {
      return await loginWithKakaoAccount();
    }
  }

  /// 카카오톡 앱을 통한 로그인
  Future<bool> loginWithKakaoTalk() async {
    try {
      final OAuthToken token = await UserApi.instance.loginWithKakaoTalk();

      String? kakaoEmail;
      try {
        final User kakaoUser = await UserApi.instance.me();
        kakaoEmail = kakaoUser.kakaoAccount?.email;
      } catch (e) {
        debugPrint('[KakaoAuth] 앱 로그인 email 조회 실패 (null로 계속): $e');
      }
      debugPrint('[KakaoAuth] 앱 로그인 email: ${_maskEmail(kakaoEmail)}');

      await _handleLoginSuccess(token: token, kakaoEmail: kakaoEmail);
      return true;
    } on AccountSuspendedException {
      rethrow;
    } on EmailAlreadyRegisteredException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' && e.email != null) {
        debugPrint('Firebase 이메일 중복 감지: ${_maskEmail(e.email)}');
        throw EmailAlreadyRegisteredException(registeredSocialPlatform: '');
      }
      debugPrint('카카오톡으로 로그인 실패: $e');
      rethrow;
    } catch (error) {
      debugPrint('카카오톡으로 로그인 실패: $error');
      if (error is PlatformException && error.code == 'CANCELED') {
        return false;
      }
      rethrow;
    }
  }

  /// 카카오 계정 웹 로그인 (카카오톡 미설치 환경 폴백)
  Future<bool> loginWithKakaoAccount() async {
    try {
      final OAuthToken token = await UserApi.instance.loginWithKakaoAccount();

      String? kakaoEmail;
      try {
        final User kakaoUser = await UserApi.instance.me();
        kakaoEmail = kakaoUser.kakaoAccount?.email;
      } catch (e) {
        debugPrint('[KakaoAuth] 웹 로그인 email 조회 실패 (null로 계속): $e');
      }
      debugPrint('[KakaoAuth] 웹 로그인 email: ${_maskEmail(kakaoEmail)}');

      await _handleLoginSuccess(token: token, kakaoEmail: kakaoEmail);
      return true;
    } on AccountSuspendedException {
      rethrow;
    } on EmailAlreadyRegisteredException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential' && e.email != null) {
        debugPrint('Firebase 이메일 중복 감지: ${_maskEmail(e.email)}');
        throw EmailAlreadyRegisteredException(registeredSocialPlatform: '');
      }
      debugPrint('카카오 웹으로 로그인 실패: $e');
      rethrow;
    } catch (error) {
      debugPrint('카카오 웹으로 로그인 실패: $error');
      if (error is PlatformException && error.code == 'CANCELED') {
        return false;
      }
      rethrow;
    }
  }

  /// 카카오 로그아웃 (토큰 만료, 연결 유지)
  Future<void> logoutWithKakao() async {
    try {
      await UserApi.instance.logout();
      await FirebaseAuth.instance.signOut();
      debugPrint('카카오 로그아웃 성공');
      await LoginPlatformManager().deleteLoginPlatform();
    } catch (error) {
      debugPrint('카카오 로그아웃 실패: $error');
    }
  }

  /// 카카오 연결 해제 (회원 탈퇴 시 사용)
  Future<void> unlinkKakao() async {
    try {
      await UserApi.instance.unlink();
      await FirebaseAuth.instance.signOut();
      debugPrint('카카오 연결 해제 성공');
      await LoginPlatformManager().deleteLoginPlatform();
    } catch (error) {
      debugPrint('카카오 연결 해제 실패: $error');
    }
  }
}
