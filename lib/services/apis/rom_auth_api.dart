import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:romrom_fe/enums/account_status.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/exceptions/email_already_registered_exception.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/apis/responses/auth_response.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/apis/member_api.dart';
import 'package:romrom_fe/utils/installed_app_version.dart';
import 'package:romrom_fe/utils/log_masking.dart';

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

    final appVersion = await fetchInstalledAppVersion(fallbackVersion: 'unknown');

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
    } catch (_) {
      // 기기 모델 조회 실패는 로그인 요청에 영향 없음 (기본값 유지)
    }

    return {'platform': platform, 'appVersion': appVersion, 'deviceModel': deviceModel, 'locale': locale};
  }

  /// POST : `/api/auth/login` 소셜 로그인
  /// 정지 계정인 경우 AccountSuspendedException throw
  /// 정상 계정인 경우 토큰 저장 후 정상 반환
  Future<void> signInWithSocial({required String firebaseIdToken, required String providerId}) async {
    final String url = '${AppUrls.baseUrl}/api/auth/login';

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

        // 정상 계정: 제재 플래그 + 세션 만료 플래그 리셋 후 토큰 저장
        ApiClient.resetSuspendedFlag();
        ApiClient.resetSessionExpiredFlag();
        String accessToken = responseData[TokenKeys.accessToken.name];
        String refreshToken = responseData[TokenKeys.refreshToken.name];

        await _tokenManager.saveTokens(accessToken, refreshToken);
        debugPrint('토큰 저장 성공');

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
    } on EmailAlreadyRegisteredException {
      rethrow; // 이메일 중복 예외는 LoginButton에서 처리
    } on ApiException catch (e) {
      // 409: 동일 이메일이 다른 소셜 플랫폼으로 이미 가입됨 / 그 외는 기존 래핑 유지
      if (e.statusCode == 409) throw toEmailAlreadyRegisteredException(e);
      throw Exception('Error during sign-in: $e');
    } catch (error) {
      throw Exception('Error during sign-in: $error');
    }
  }

  /// ### POST : `/api/auth/reissue` (accessToken 재발급)
  /// ApiClient.reissueTokens 위임 > 성공 시 로그인 상태·회원 정보 갱신 / 실패 시 false (토큰 유지, 화면 이동은 호출부)
  Future<bool> refreshAccessToken() async {
    try {
      final reissueResult = await ApiClient.reissueTokens();
      final responseData = reissueResult.responseData;

      // 실패·만료 > 토큰 유지 후 false (스플래시: 로그인 화면 이동, 웹소켓: 다음 API 401에서 세션 만료 처리)
      if (responseData == null) {
        if (reissueResult.isRefreshTokenExpired) debugPrint('refresh 만료');
        return false;
      }

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

      debugPrint('access token 재발급 성공');
      return true;
    } catch (e) {
      debugPrint('Token refresh failed: ${LogMasking.describeErrorForLog(e)}');
      return false;
    }
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

  /// POST : `/api/auth/kakao/firebase-token` 카카오 accessToken으로 Firebase Custom Token 발급
  ///
  /// [email]은 기존 카카오 회원 마이그레이션 fallback 식별자로 nullable
  Future<String> getKakaoFirebaseToken({required String kakaoAccessToken, String? email}) async {
    final String url = '${AppUrls.baseUrl}/api/auth/kakao/firebase-token';

    try {
      http.Response response = await ApiClient.sendHttpRequest(
        url: url,
        method: 'POST',
        body: {'accessToken': kakaoAccessToken, 'email': email},
        isAuthRequired: false,
        onSuccess: (_) {},
      );

      // ApiClient가 non-2xx를 ApiException으로 던지므로 여기는 2xx만 도달
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final String customToken = responseData['customToken'] as String;
      debugPrint('Firebase Custom Token 발급 성공');
      return customToken;
    } on ApiException catch (e) {
      debugPrint('getKakaoFirebaseToken 실패: ${LogMasking.describeErrorForLog(e)}');
      throw toKakaoFirebaseTokenException(e) ?? e;
    } catch (e) {
      debugPrint('getKakaoFirebaseToken 실패: ${LogMasking.describeErrorForLog(e)}');
      rethrow;
    }
  }

  /// ApiException(409) > EmailAlreadyRegisteredException (registeredSocialPlatform 누락 시 빈 문자열)
  @visibleForTesting
  static EmailAlreadyRegisteredException toEmailAlreadyRegisteredException(ApiException exception) {
    final registeredSocialPlatform = exception.responseJson?['registeredSocialPlatform'];
    return EmailAlreadyRegisteredException(
      registeredSocialPlatform: registeredSocialPlatform is String ? registeredSocialPlatform : '',
    );
  }

  /// 카카오 Firebase 토큰 발급 실패 > 도메인 예외 (이메일 중복, 정지 계정) / 해당 없으면 null
  /// 에러 코드 키 2개: errorCode(현행), code(구버전 응답)
  @visibleForTesting
  static Exception? toKakaoFirebaseTokenException(ApiException exception) {
    final responseJson = exception.responseJson;
    final legacyCode = responseJson?['code'];
    final errorCode = exception.errorCode ?? (legacyCode is String ? legacyCode : null);

    if (exception.statusCode == 409 || errorCode == 'EMAIL_ALREADY_REGISTERED') {
      return toEmailAlreadyRegisteredException(exception);
    }

    if (errorCode == 'SUSPENDED_MEMBER') {
      final suspendReason = responseJson?['suspendReason'];
      final suspendedUntil = responseJson?['suspendedUntil'];
      return AccountSuspendedException(
        suspendReason: suspendReason is String ? suspendReason : '',
        suspendedUntil: suspendedUntil is String ? suspendedUntil : '',
      );
    }

    return null;
  }

  /// POST : `/api/auth/logout` 서버 로그아웃 API 호출
  Future<void> logout() async {
    await MemberManager.clearMemberInfo();
    final String url = '${AppUrls.baseUrl}/api/auth/logout';
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
