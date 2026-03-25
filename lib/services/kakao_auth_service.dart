import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide UserInfo, User;
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:flutter/services.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:url_launcher/url_launcher.dart';

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
      await UserInfo().saveUserInfo(user.kakaoAccount?.profile?.nickname ?? '', user.kakaoAccount?.email ?? '');
      // 로그인 플랫폼 저장
      LoginPlatformManager().saveLoginPlatform(LoginPlatforms.kakao.platformName);
    } catch (error) {
      debugPrint('사용자 정보 요청 실패: $error');
    }
  }

  /// 카카오톡 미설치 시 스토어 이동 유도 다이얼로그
  Future<void> _showKakaoTalkInstallDialog(BuildContext context) async {
    await CommonModal.confirm(
      context: context,
      message: '카카오 로그인을 사용하려면\n카카오톡 앱이 필요합니다.',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () async {
        Navigator.of(context).pop();
        // 플랫폼에 따라 앱스토어 또는 플레이스토어로 이동
        final Uri storeUri = Uri.parse(
          Platform.isIOS
              ? 'https://apps.apple.com/kr/app/id362057947' // 앱스토어
              : 'https://play.google.com/store/apps/details?id=com.kakao.talk', // 플레이스토어
        );
        if (await canLaunchUrl(storeUri)) {
          await launchUrl(storeUri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }

  /// Firebase OIDC provider로 카카오 credential 생성 후 FirebaseAuth에 저장
  ///
  /// 카카오톡 앱 로그인만 사용하므로 idToken의 aud는 항상 네이티브 앱 키로 고정됨
  /// Firebase 콘솔 OIDC Client ID = 카카오 네이티브 앱 키로 설정 필요
  Future<void> _signInWithFirebase(OAuthToken token) async {
    try {
      // Firebase 콘솔에서 등록한 OIDC provider ID
      final OAuthProvider provider = OAuthProvider('oidc.kakao');

      // OIDC idToken + accessToken으로 credential 생성
      final OAuthCredential credential = provider.credential(
        idToken: token.idToken, // 카카오톡 앱 로그인 시 aud = 네이티브 앱 키
        accessToken: token.accessToken,
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
      rethrow;
    }
  }

  /// 로그인 성공 후 후처리 함수
  Future<void> _handleLoginSuccess(OAuthToken token) async {
    debugPrint('카카오 로그인 성공: ${token.accessToken}');

    // Firebase OIDC credential 저장
    await _signInWithFirebase(token);

    // Firebase ID 토큰 취득
    final String firebaseIdToken = await FirebaseAuth.instance.currentUser?.getIdToken() ?? '';

    await getKakaoUserInfo();
    await romAuthApi.signInWithSocial(firebaseIdToken: firebaseIdToken, providerId: 'oidc.kakao');
  }

  /// 카카오 로그인 (카카오톡 앱만 사용)
  ///
  /// 카카오톡 미설치 시 설치 유도 다이얼로그 표시 후 스토어로 이동
  /// aud가 네이티브 앱 키로 고정되어 Firebase OIDC audience 불일치 문제 없음
  Future<bool> loginWithKakao(BuildContext context) async {
    if (!await isKakaoTalkInstalled()) {
      // 카카오톡 미설치 시 설치 유도 다이얼로그 표시
      await _showKakaoTalkInstallDialog(context);
      return false;
    }
    return await loginWithKakaoTalk();
  }

  /// 카카오톡 앱을 통한 로그인
  Future<bool> loginWithKakaoTalk() async {
    try {
      OAuthToken token = await UserApi.instance.loginWithKakaoTalk();
      await _handleLoginSuccess(token);
      return true; // 성공 시 true 반환
    } on AccountSuspendedException {
      rethrow;
    } catch (error) {
      debugPrint('카카오톡으로 로그인 실패: $error');

      if (error is PlatformException && error.code == 'CANCELED') {
        return false; // 사용자가 로그인 취소 시 false 반환
      }
      return false; // 카카오 계정 로그인 폴백 제거 (aud 불일치 방지)
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
