import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/services/token_manage.dart';

/// **재사용 가능한 API 요청 함수**
Future<void> sendAuthenticatedRequest({
  required String url,
  String method = 'POST',
  Map<String, dynamic>? body,
  required Function(Map<String, dynamic>) onSuccess,
}) async {
  try {
    String? accessToken = await getAccessToken();
    String? refreshToken = await getRefreshToken();

    if (accessToken == null || refreshToken == null) {
      throw Exception('토큰이 없습니다.');
    }

    // 요청 보내기
    http.Response response = await _sendMultiPartRequest(
      url: url,
      method: method,
      accessToken: accessToken,
      body: body,
    );

    if (response.statusCode == 200) {
      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        onSuccess(responseData);
      } else {
        debugPrint('서버 응답이 비어 있음. 빈 객체로 처리합니다.');
        onSuccess({});
      }
    } else if (response.statusCode == 401) {
      // 🔄 **토큰 갱신 후 재시도**
      bool isRefreshed = await refreshAccessToken();
      if (isRefreshed) {
        accessToken = await getAccessToken();
        refreshToken = await getRefreshToken();

        response = await _sendMultiPartRequest(
          url: url,
          method: method,
          accessToken: accessToken!,
          body: body,
        );

        if (response.statusCode == 200) {
          if (response.body.isNotEmpty) {
            final responseData = jsonDecode(response.body);
            onSuccess(responseData);
          } else {
            debugPrint('서버 응답이 비어 있음. 빈 객체로 처리합니다.');
            onSuccess({});
          }
        } else {
          throw Exception(
              'API 요청 실패 (토큰 갱신 후에도 실패): ${response.statusCode}, ${response.body}');
        }
      } else {
        debugPrint("토큰 갱신 실패: 다시 로그인 필요");
        throw Exception('Failed due to token refresh failure.');
      }
    } else {
      throw Exception('API 요청 실패: ${response.statusCode}, ${response.body}');
    }
  } catch (error) {
    throw Exception('API 요청 중 오류 발생: $error');
  }
}

/// **실제 요청을 처리하는 함수**
Future<http.Response> _sendMultiPartRequest({
  required String url,
  required String method,
  required String accessToken,
  Map<String, dynamic>? body,
}) async {
  var request = http.MultipartRequest(method, Uri.parse(url));

  // Authorization 헤더 추가
  request.headers['Authorization'] = 'Bearer $accessToken';

  // body 필드 추가
  if (body != null) {
    body.forEach((key, value) {
      request.fields[key] = value.toString();
    });
  }

  var streamedResponse = await request.send();
  return http.Response.fromStream(streamedResponse);
}
