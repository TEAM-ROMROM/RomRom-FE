import 'package:firebase_auth/firebase_auth.dart' hide UserInfo, User;
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';

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

  /// 사용자 정보 가져오기
  Future<void> getKakaoUserInfo() async {
    try {
      User user = await UserApi.instance.me();

      debugPrint(
        '사용자 정보 요청 성공: 이메일: ${user.kakaoAccount?.email}, 닉네임: ${user.kakaoAccount?.profile?.nickname}, 프로필 이미지: ${user.kakaoAccount?.profile?.profileImageUrl}',
      );

      // 사용자 정보 저장
      await UserInfo().saveUserInfo(
        '${user.kakaoAccount?.profile?.nickname}',
        '${user.kakaoAccount?.email}',
        '${user.kakaoAccount?.profile?.profileImageUrl}',
      );
      // 로그인 플랫폼 저장
      LoginPlatformManager().saveLoginPlatform(LoginPlatforms.kakao.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// Firebase OIDC provider로 카카오 credential 생성 후 FirebaseAuth에 저장
  /// Firebase 콘솔 → Authentication → Sign-in method → OpenID Connect 에서
  Future<void> _signInWithFirebase(OAuthToken token) async {
    try {
      // Firebase 콘솔에서 등록한 OIDC provider ID (예: 'oidc.kakao')
      final OAuthProvider provider = OAuthProvider('oidc.kakao');

      // OIDC idToken + accessToken으로 credential 생성
      final OAuthCredential credential = provider.credential(
        idToken: token.idToken, // OIDC 활성화 시 발급되는 idToken
        accessToken: token.accessToken, // 카카오 로그인에서 발급된 accessToken
      );

      // FirebaseAuth에 credential 저장 (로그인)
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('Firebase 로그인 성공: ${userCredential.user?.uid}');

      // Firebase 유저 프로필에 카카오 ID + 닉네임 저장
      final User kakaoUser = await UserApi.instance.me();
      await userCredential.user?.updateProfile(
        displayName: '${kakaoUser.id}${kakaoUser.kakaoAccount?.profile?.nickname}',
      );
      debugPrint('Firebase 프로필 업데이트 성공');
    } catch (error) {
      debugPrint('Firebase 로그인 실패: $error');
      rethrow; // 상위에서 로그인 실패 처리할 수 있도록 rethrow
    }
  }

  /// 로그인 성공 후 후처리 함수
  Future<void> _handleLoginSuccess(OAuthToken token) async {
    debugPrint('카카오 로그인 성공: ${token.accessToken}');

    // Firebase OIDC credential 저장
    await _signInWithFirebase(token);

    await getKakaoUserInfo();
    await romAuthApi.signInWithSocial(socialPlatform: LoginPlatforms.kakao.platformName);
  }

  /// 카카오 로그인 (카톡앱 -> 카카오 계정 순서로 시도)
  Future<bool> loginWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      return await loginWithKakaoTalk(); // 로그인 결과 반환
    } else {
      return await loginWithKakaoAccount(); // 로그인 결과 반환
    }
  }

  /// 카카오톡 앱을 통한 로그인
  Future<bool> loginWithKakaoTalk() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      await _handleLoginSuccess(token);
      return true; // 성공 시 true 반환
    } catch (error) {
      debugPrint('카카오톡으로 로그인 실패: $error');

      if (error is PlatformException && error.code == 'CANCELED') {
        return false; // 사용자가 로그인 취소 시 false 반환
      }
      return await loginWithKakaoAccount(); // 카카오 계정으로 로그인 시도 결과 반환
    }
  }

  /// 카카오 계정으로 로그인
  Future<bool> loginWithKakaoAccount() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      await _handleLoginSuccess(token);
      return true; // 성공 시 true 반환
    } catch (error) {
      debugPrint('카카오 계정으로 로그인 실패: $error');
      return false; // 실패 시 false 반환
    }
  }

  /// 카카오 로그아웃
  Future<void> logoutWithKakaoAccount() async {
    try {
      // 카카오 로그아웃
      await UserApi.instance.unlink();
      debugPrint('로그아웃 성공, 카카오 SDK에서 토큰 삭제');
      // 로그인 플랫폼 정보 삭제
      await LoginPlatformManager().deleteLoginPlatform();
    } catch (error) {
      debugPrint('로그아웃 실패: $error');
    }
  }
}
