import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/services/token_manage_service.dart';

/// 소셜 로그인 후 토큰 요청
Future<void> signInWithSocial({
  required String socialPlatform,
  required String socialAuthToken,
}) async {
  const String url = '$baseUrl/api/auth/signin';

  try {
    // multipart 형식 요청
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // 요청 파라미터 추가
    request.fields['socialPlatform'] = socialPlatform;
    request.fields['socialAuthToken'] = socialAuthToken;

    // 요청 보내기
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 응답 데이터 출력
      debugPrint('Access Token: ${responseData['accessToken']}');
      debugPrint('Refresh Token: ${responseData['refreshToken']}');
      debugPrint('Is First Login: ${responseData['isFirstLogin']}');

      final tokens = {
        'accessToken': responseData['accessToken'],
        'refreshToken': responseData['refreshToken'],
      };

      // 로컬 저장소에 저장
      saveTokens(tokens.entries.first.value, tokens.entries.last.value);
    } else {
      throw Exception('Failed to sign in: ${response.body}');
    }
  } catch (error) {
    throw Exception('Error during sign-in: $error');
  }
}
