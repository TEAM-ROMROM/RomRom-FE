import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:romrom_fe/main.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/utils/response_printer.dart';

class TokenManager {
  static const storage = FlutterSecureStorage();

  /// 토큰 저장
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await storage.write(key: TokenKeys.accessToken.name, value: accessToken);
    await storage.write(key: TokenKeys.refreshToken.name, value: refreshToken);
  }

  /// 액세스 토큰 불러오기
  Future<String?> getAccessToken() async {
    return await storage.read(key: TokenKeys.accessToken.name);
  }

  /// 리프레시 토큰 불러오기
  Future<String?> getRefreshToken() async {
    return await storage.read(key: TokenKeys.refreshToken.name);
  }

  /// 토큰 삭제
  Future<void> deleteTokens() async {
    await storage.delete(key: TokenKeys.accessToken.name);
    await storage.delete(key: TokenKeys.refreshToken.name);
  }
}

/// ### POST : `/api/auth/reissue` (accessToken 재발급)
Future<bool> refreshAccessToken() async {
  //토큰 재발급 api 요청 주소
  String url = '$baseUrl/api/auth/reissue';
  try {
    String? refreshToken = await TokenManager().getRefreshToken();

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

      TokenManager().saveTokens(accessToken, refreshToken);
      debugPrint('access token 이 성공적으로 재발급됨');
      return true;
    }

    // refresh 만료 -> 강제 로그아웃시키기
    else if (response.statusCode == 401) {
      debugPrint('refresh 만료');
      // 토큰 삭제
      TokenManager().deleteTokens();

      return false;
    }
  } catch (e) {
    debugPrint('Token refresh failed: $e');
  }
  return false;
}
