import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/models/tokens.dart';
import 'package:romrom_fe/models/user.dart';
import 'package:romrom_fe/services/secure_storage_manage.dart';

/// 소셜 로그인 후 토큰 요청
Future<void> signInWithSocial({
  required String socialPlatform,
  required String socialAuthToken,
}) async {
  const String url = '$baseUrl/api/auth/signin';

  try {
    // multipart 형식 요청
    var request = http.MultipartRequest('POST', Uri.parse(url));

    var userInfo = UserInfo().getUserInfo();

    // 요청 파라미터 추가

    // 기존 파라미터 (플랫폼, 토큰)
    request.fields['socialPlatform'] = socialPlatform;
    request.fields['socialAuthToken'] = socialAuthToken;

    // 수정 파라미터 (유저 정보)
    // userInfo.forEach((key, value) {
    //   request.fields[key] = value ?? '';
    // });

    // 요청 보내기
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 응답 데이터 출력
      debugPrint('Access Token: ${responseData['accessToken']}');
      debugPrint('Refresh Token: ${responseData['refreshToken']}');
      debugPrint('Is First Login: ${responseData['isFirstLogin']}');

      // 토큰 매핑
      final tokens = {
        Tokens.accessToken.name: responseData['accessToken'],
        Tokens.refreshToken.name: responseData['refreshToken'],
      };

      // 로컬 저장소에 저장
      saveSecureData(tokens);
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  } catch (error) {
    throw Exception('Error during sign-in: $error');
  }
}
