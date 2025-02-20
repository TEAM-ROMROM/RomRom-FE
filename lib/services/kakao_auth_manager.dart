import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';

import 'package:romrom_fe/models/platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/social_auth_sign_in_service.dart';

/// 카카오 인증 관련 서비스
class KakaoAuthService {
  /// 사용자 정보 가져오기
  Future<void> getKakaoUserInfo() async {
    try {
      User user = await UserApi.instance.me();

      debugPrint(
          '사용자 정보 요청 성공: 이메일: ${user.kakaoAccount?.email}, 닉네임: ${user.kakaoAccount?.profile?.nickname}, 프로필 이미지: ${user.kakaoAccount?.profile?.profileImageUrl}');

      // 사용자 정보 저장
      UserInfo().setUserInfo(
          '${user.kakaoAccount?.profile?.nickname}',
          '${user.kakaoAccount?.email}',
          '${user.kakaoAccount?.profile?.profileImageUrl}',
          Platforms.KAKAO);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 로그인 성공 후 후처리 함수
  Future<void> _handleLoginSuccess(OAuthToken token) async {
    debugPrint('카카오 로그인 성공: ${token.accessToken}');
    await getKakaoUserInfo();
    await signInWithSocial(socialPlatform: Platforms.KAKAO.name);
  }

  /// 카카오 로그인 (토큰 확인 후 로그인 시도)
  Future<void> signInWithKakao() async {
    if (await AuthApi.instance.hasToken()) {
      try {
        AccessTokenInfo tokenInfo = await UserApi.instance.accessTokenInfo();
        debugPrint('토큰 유효성 체크 성공: ${tokenInfo.id} ${tokenInfo.expiresIn}');
      } catch (error) {
        if (error is KakaoException && error.isInvalidTokenError()) {
          debugPrint('토큰 만료: $error');
        } else {
          debugPrint('토큰 정보 조회 실패: $error');
        }
        await loginWithKakao();
      }
    } else {
      debugPrint('발급된 토큰 없음');
      await loginWithKakao();
    }
  }

  /// 카카오 로그인 (카톡앱 -> 카카오 계정 순서로 시도)
  Future<void> loginWithKakao() async {
    if (await isKakaoTalkInstalled()) {
      await loginWithKakaoTalk();
    } else {
      await loginWithKakaoAccount();
    }
  }

  /// 카카오톡 앱을 통한 로그인
  Future<void> loginWithKakaoTalk() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      await _handleLoginSuccess(token);
    } catch (error) {
      debugPrint('카카오톡으로 로그인 실패: $error');

      if (error is PlatformException && error.code == 'CANCELED') {
        return;
      }
      await loginWithKakaoAccount();
    }
  }

  /// 카카오 계정으로 로그인
  Future<void> loginWithKakaoAccount() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      await _handleLoginSuccess(token);
    } catch (error) {
      debugPrint('카카오 계정으로 로그인 실패: $error');
    }
  }

  /// 카카오 로그아웃
  Future<void> logoutWithKakaoAccount() async {
    try {
      await UserApi.instance.logout();
      debugPrint('로그아웃 성공, 카카오 SDK에서 토큰 삭제');
    } catch (error) {
      debugPrint('로그아웃 실패: $error');
    }
  }
}
