import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/enums/login_platforms.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/api_client.dart';
import 'package:romrom_fe/services/apis/social_logout_service.dart';
import 'package:romrom_fe/services/google_auth_service.dart';
import 'package:romrom_fe/services/kakao_auth_service.dart';
import 'package:romrom_fe/services/login_platform_manager.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/log_utils.dart';

// AuthApi -> RomAuthApi 이름 변경 : kakao SDK ApiAuth 와 충돌
class RomAuthApi {
  // 싱글톤 구현
  static final RomAuthApi _instance = RomAuthApi._internal();
  factory RomAuthApi() => _instance;
  RomAuthApi._internal();

  final TokenManager _tokenManager = TokenManager();
  final LoginPlatformManager _loginPlatformManager = LoginPlatformManager();

  /// POST : `/api/auth/sign-in` 소셜 로그인
  Future<void> signInWithSocial({
    required String socialPlatform,
  }) async {
    const String url = '$baseUrl/api/auth/sign-in';

    try {
      // multipart 형식 요청
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 사용자 정보 불러옴
      var userInfo = UserInfo();
      await userInfo.getUserInfo();

      // 요청 파라미터 추가 (플랫폼, 유저 정보)
      request.fields['socialPlatform'] = socialPlatform;
      // 사용자 정보 추가
      userInfo.toMap().forEach((key, value) {
        if (value != null) {
          request.fields[key] = value;
        }
      });
      // test 용 요청
      // request.fields['nickname'] = 'test';
      // request.fields['email'] = 'test@test123.com';
      // request.fields['profileUrl'] = '';

      // 요청 보내기
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // 응답 데이터 출력
        responsePrinter(url, responseData);

        // 로컬 저장소에 토큰 저장
        String accessToken = responseData[TokenKeys.accessToken.name];
        String refreshToken = responseData[TokenKeys.refreshToken.name];

        _tokenManager.saveTokens(accessToken, refreshToken);

        // 첫 번째 로그인인지 저장
        await UserInfo().saveIsFirstLogin(responseData['isFirstLogin']);
      } else {
        throw Exception('Failed to sign in: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error during sign-in: $error');
    }
  }

  /// ### POST : `/api/auth/reissue` (accessToken 재발급)
  Future<bool> refreshAccessToken() async {
    //토큰 재발급 api 요청 주소
    String url = '$baseUrl/api/auth/reissue';
    try {
      String? refreshToken = await _tokenManager.getRefreshToken();

      if (refreshToken == null) {
        debugPrint('No refresh token found for user.');
        return false;
      }

      // multipart 형식 요청
      var request = http.MultipartRequest('POST', Uri.parse(url));

      // 요청 파라미터 추가
      request.fields[TokenKeys.refreshToken.name] = refreshToken;

      // 요청 보내기
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 응답 데이터 출력
      responsePrinter(url, responseData);

      if (response.statusCode == 200) {
        // 로컬 저장소에 토큰 저장
        String accessToken = responseData[TokenKeys.accessToken.name];

        _tokenManager.saveTokens(accessToken, refreshToken);
        debugPrint('access token 이 성공적으로 재발급됨');
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

  /// POST : `/api/auth/logout` 로그아웃
  Future<void> logoutWithSocial(BuildContext context) async {
    await SocialLogoutService().logout(context);
  }

}
