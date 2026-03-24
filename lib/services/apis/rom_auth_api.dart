import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/apis/responses/auth_response.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/apis/member_api.dart';

// AuthApi -> RomAuthApi 이름 변경 : kakao SDK ApiAuth 와 충돌
class RomAuthApi {
  // 싱글톤 구현
  static final RomAuthApi _instance = RomAuthApi._internal();
  factory RomAuthApi() => _instance;
  RomAuthApi._internal();

  final TokenManager _tokenManager = TokenManager();

  Future<Map<String, dynamic>> _getClientInfo() async {
    final platform = Platform.isIOS ? 'ios' : 'android';
    final locale = Platform.localeName.replaceAll('_', '-');

    String appVersion = 'unknown';
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (_) {}

    String deviceModel = 'unknown';
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        deviceModel = iosInfo.utsname.machine;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        deviceModel = androidInfo.model;
      }
    } catch (_) {}

    return {'platform': platform, 'appVersion': appVersion, 'deviceModel': deviceModel, 'locale': locale};
  }

  /// POST : `/api/auth/login` 소셜 로그인
  /// 정지 계정인 경우 AccountSuspendedException throw
  /// 정상 계정인 경우 토큰 저장 후 정상 반환
  Future<void> signInWithSocial({required String firebaseIdToken, required String providerId}) async {
    const String url = '${AppUrls.baseUrl}/api/auth/login';

    try {
      // 사용자 정보 불러옴
      var userInfo = UserInfo();
      await userInfo.getUserInfo();

      // 클라이언트 정보 수집
      final clientInfo = await _getClientInfo();

      // 요청 body 준비
      final Map<String, dynamic> body = {
        'firebaseIdToken': firebaseIdToken,
        'providerId': providerId,
        'profile': {
          if (userInfo.email?.isNotEmpty == true) 'email': userInfo.email,
          if (userInfo.nickname?.isNotEmpty == true) 'displayName': userInfo.nickname,
          if (userInfo.profileUrl?.isNotEmpty == true) 'photoUrl': userInfo.profileUrl,
        },
        'client': clientInfo,
      };

      // HTTP 요청 (JSON)
      http.Response response = await ApiClient.sendHttpRequest(
        url: url,
        method: 'POST',
        body: body,
        isAuthRequired: false,
        onSuccess: (_) {},
      );

      // 응답을 직접 처리
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);

        // 정지 계정인 경우: 토큰 저장하지 않고 예외 throw
        if (authResponse.accountStatus == AccountStatus.suspendedAccount.serverName) {
          debugPrint('정지된 계정입니다. 제재 사유: ${authResponse.suspendReason}');
          throw AccountSuspendedException(
            suspendReason: authResponse.suspendReason ?? '',
            suspendedUntil: authResponse.suspendedUntil ?? '',
          );
        }

        // 정상 계정: 제재 플래그 리셋 후 토큰 저장
        ApiClient.resetSuspendedFlag();
        String accessToken = responseData[TokenKeys.accessToken.name];
        String refreshToken = responseData[TokenKeys.refreshToken.name];

        await _tokenManager.saveTokens(accessToken, refreshToken);
        debugPrint('토큰 저장 성공: accessToken=${accessToken.substring(0, 15)}...');

        // 로그인 상태 저장
        await UserInfo().saveLoginStatus(
          isFirstLogin: responseData['isFirstLogin'] ?? false,
          isFirstItemPosted: responseData['isFirstItemPosted'] ?? false,
          isItemCategorySaved: responseData['isItemCategorySaved'] ?? false,
          isMemberLocationSaved: responseData['isMemberLocationSaved'] ?? false,
          isMarketingInfoAgreed: responseData['isMarketingInfoAgreed'] ?? false,
          isRequiredTermsAgreed: responseData['isRequiredTermsAgreed'] ?? false,
        );

        return; // 정상 계정
      } else {
        throw Exception('소셜 로그인 실패: ${response.statusCode}, ${response.body}');
      }
    } on AccountSuspendedException {
      rethrow; // 제재 예외는 LoginButton에서 처리
    } catch (error) {
      throw Exception('Error during sign-in: $error');
    }
  }

  /// ### POST : `/api/auth/reissue` (accessToken 재발급)
  Future<bool> refreshAccessToken() async {
    //토큰 재발급 api 요청 주소
    String url = '${AppUrls.baseUrl}/api/auth/reissue';
    try {
      String? refreshToken = await _tokenManager.getRefreshToken();

      if (refreshToken == null) {
        debugPrint('No refresh token found for user.');
        return false;
      }

      // 요청 파라미터 준비
      Map<String, dynamic> fields = {TokenKeys.refreshToken.name: refreshToken};

      // 요청 보냄
      http.Response response = await ApiClient.sendMultipartRequest(
        url: url,
        method: 'POST',
        fields: fields,
        isAuthRequired: false, // 토큰 갱신에는 인증이 필요하지 않음
        onSuccess: (responseData) {
          // onSuccess는 필요하지만 여기서 실제 처리는 하지 않음
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // 로컬 저장소에 토큰 저장
        String accessToken = responseData[TokenKeys.accessToken.name];

        // API 응답에서 refreshToken이 있으면 새 토큰 사용, 아니면 기존 토큰 유지
        String? newRefreshToken = responseData[TokenKeys.refreshToken.name];
        String tokenToSave = newRefreshToken ?? refreshToken;

        await _tokenManager.saveTokens(accessToken, tokenToSave);

        // 회원 상태 정보 업데이트
        await UserInfo().saveLoginStatus(
          isFirstLogin: responseData['isFirstLogin'] ?? false,
          isFirstItemPosted: responseData['isFirstItemPosted'] ?? false,
          isItemCategorySaved: responseData['isItemCategorySaved'] ?? false,
          isMemberLocationSaved: responseData['isMemberLocationSaved'] ?? false,
          isMarketingInfoAgreed: responseData['isMarketingInfoAgreed'] ?? false,
          isRequiredTermsAgreed: responseData['isRequiredTermsAgreed'] ?? false,
        );

        // 토큰 갱신 후에도 회원 정보 업데이트
        await fetchAndSaveMemberInfo();

        debugPrint('====================================');
        debugPrint('access token 이 성공적으로 재발급됨');
        debugPrint('====================================');
        return true;
      }
      // refresh 만료 -> 강제 로그아웃시키기
      else if (response.statusCode == 401) {
        debugPrint('refresh 만료');
        // 토큰 삭제
        _tokenManager.deleteTokens();

        return false;
      }
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    return false;
  }

  /// 회원 정보를 가져와서 CurrentMemberService에 저장
  Future<void> fetchAndSaveMemberInfo() async {
    try {
      final memberApi = MemberApi();
      final response = await memberApi.getMemberInfo();

      if (response.member != null) {
        await MemberManager.saveMemberInfo(response.member!);
        debugPrint('회원 정보 저장 성공: ${response.member!.memberId}');
      }
    } catch (e) {
      debugPrint('회원 정보 저장 실패: $e');
    }
  }

  /// POST : `/api/auth/logout` 서버 로그아웃 API 호출
  Future<void> logout() async {
    await MemberManager.clearMemberInfo();
    const String url = '${AppUrls.baseUrl}/api/auth/logout';
    await ApiClient.sendMultipartRequest(
      url: url,
      fields: {
        TokenKeys.accessToken.name: await _tokenManager.getAccessToken(),
        TokenKeys.refreshToken.name: await _tokenManager.getRefreshToken(),
      },
      isAuthRequired: true,
      onSuccess: (_) {},
    );
  }
}
