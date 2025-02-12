import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';

import 'package:romrom_fe/models/platforms.dart';
import 'package:romrom_fe/services/social_auth_sign_in_service.dart';

/// 카카오 인증 관련 서비스
class KakaoAuthService {
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
        await loginWithKakaoAccount();
      }
    } else {
      debugPrint('발급된 토큰 없음');
      await loginWithKakaoAccount();
    }
  }

  /// 카카오톡 앱을 통한 로그인 시도
  Future<void> loginWithKakaoAccount() async {
    // 카톡 앱 설치 되어있으면 우선 로그인
    if (await isKakaoTalkInstalled()) {
      try {
        OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
        debugPrint('카카오톡으로 로그인 성공: ${token.accessToken}');
        await signInWithSocial(
            socialPlatform: Platforms.KAKAO.name,
            socialAuthToken: token.accessToken);
      } catch (error) {
        debugPrint('카카오톡으로 로그인 실패: $error');

        if (error is PlatformException && error.code == 'CANCELED') {
          return;
        }
        await loginWithKakaoAccountFallback();
      }
    } else {
      await loginWithKakaoAccountFallback();
    }
  }

  /// 카카오 계정으로 로그인 (백업 방법)
  Future<void> loginWithKakaoAccountFallback() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoAccount();
      debugPrint('카카오계정으로 로그인 성공: ${token.accessToken}');
      await signInWithSocial(
          socialPlatform: Platforms.KAKAO.name,
          socialAuthToken: token.accessToken);
    } catch (error) {
      debugPrint('카카오계정으로 로그인 실패: $error');
    }
  }

  /// 카카오 로그아웃
  Future<void> logoutWithKakaoAccount() async {
    try {
      await UserApi.instance.logout();
      debugPrint('로그아웃 성공, SDK에서 토큰 삭제');
    } catch (error) {
      debugPrint('로그아웃 실패, SDK에서 토큰 삭제 $error');
    }
  }
}
