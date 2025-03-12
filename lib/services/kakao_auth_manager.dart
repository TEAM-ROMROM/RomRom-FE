import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';

import 'package:romrom_fe/enums/platforms.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';
import 'package:romrom_fe/services/api/social_auth_sign_in_service.dart';

/// 카카오 인증 관련 서비스
class KakaoAuthService {
  /// 사용자 정보 가져오기
  Future<void> getKakaoUserInfo() async {
    try {
      User user = await UserApi.instance.me();

      debugPrint(
          '사용자 정보 요청 성공: 이메일: ${user.kakaoAccount?.email}, 닉네임: ${user.kakaoAccount?.profile?.nickname}, 프로필 이미지: ${user.kakaoAccount?.profile?.profileImageUrl}');

      // 사용자 정보 저장
      UserInfo().saveUserInfo(
          '${user.kakaoAccount?.profile?.nickname}',
          '${user.kakaoAccount?.email}',
          '${user.kakaoAccount?.profile?.profileImageUrl}');
      // 로그인 플랫폼 저장
      LoginPlatformManager().saveLoginPlatform(Platforms.kakao.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 로그인 성공 후 후처리 함수
  Future<void> _handleLoginSuccess(OAuthToken token) async {
    debugPrint('카카오 로그인 성공: ${token.accessToken}');
    await getKakaoUserInfo();
    await signInWithSocial(socialPlatform: Platforms.kakao.platformName);
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
