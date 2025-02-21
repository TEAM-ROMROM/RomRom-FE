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
    // TODO : exception enum 처리
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

    // statusCode 200 일 때
    if (response.statusCode == 200) {
      // 응답 비어있으면 오류나서 따로 처리
      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        onSuccess(responseData);
      } else {
        debugPrint('서버 응답이 비어 있음. 빈 객체로 처리합니다.');
        onSuccess({});
      }
    }
    //  토큰 갱신 후 재시도
    else if (response.statusCode == 401) {
      bool isRefreshed = await refreshAccessToken();

      // 토큰 재발급 된 경우
      if (isRefreshed) {
        accessToken = await getAccessToken();
        refreshToken = await getRefreshToken();

        response = await _sendMultiPartRequest(
          url: url,
          method: method,
          accessToken: accessToken!,
          body: body,
        );

        // statusCode 200인 경우
        if (response.statusCode == 200) {
          // 응답 비어있으면 오류나서 따로 처리
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
  // url에 해당 method 로 요청
  var request = http.MultipartRequest(method, Uri.parse(url));

  // Authorization 헤더에 accessToken 추가
  request.headers['Authorization'] = 'Bearer $accessToken';

  // body에 필요한 필드 추가
  if (body != null) {
    body.forEach((key, value) {
      request.fields[key] = value.toString();
    });
  }

  // 요청 보내고 응답 반환
  var streamedResponse = await request.send();
  return http.Response.fromStream(streamedResponse);
}
