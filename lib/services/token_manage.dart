import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:romrom_fe/main.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/tokens.dart';
import 'package:romrom_fe/services/response_printer.dart';
import 'package:romrom_fe/services/secure_storage_manage.dart';

/// 토큰 저장
Future<void> saveTokens(String accessToken, String refreshToken) async {
  await storage.write(key: Tokens.accessToken.name, value: accessToken);
  await storage.write(key: Tokens.refreshToken.name, value: refreshToken);
}

/// 액세스 토큰 불러오기
Future<String?> getAccessToken() async {
  return await storage.read(key: Tokens.accessToken.name);
}

/// 리프레시 토큰 불러오기
Future<String?> getRefreshToken() async {
  return await storage.read(key: Tokens.refreshToken.name);
}

/// 토큰 삭제
Future<void> deleteTokens() async {
  await storage.delete(key: Tokens.accessToken.name);
  await storage.delete(key: Tokens.refreshToken.name);
}

/// POST : `/api/auth/reissue` (accessToken 재발급)
Future<bool> refreshAccessToken() async {
  //토큰 재발급 api 요청 주소
  String url = '$baseUrl/api/auth/reissue';
  try {
    String? refreshToken = await getSecureData(Tokens.refreshToken.name);

    if (refreshToken == null) {
      debugPrint('No refresh token found for user.');
      return false;
    }

    // multipart 형식 요청
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // 요청 파라미터 추가
    request.fields[Tokens.refreshToken.name] = refreshToken;

    // 요청 보내기
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      debugPrint('access token 이 성공적으로 재발급됨');
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // 응답 데이터 출력
      responsePrinter(url, responseData);

      // 로컬 저장소에 토큰 저장
      String accessToken = responseData[Tokens.accessToken.name];

      saveTokens(accessToken, refreshToken);

      return true;
    }

    // refresh 만료 -> 강제 로그아웃시키기
    else if (response.statusCode == 401) {
      debugPrint('refresh 만료');
      // 토큰 삭제
      deleteTokens();

      return false;
    }
  } catch (e) {
    debugPrint('Token refresh failed: $e');
  }
  return false;
}
