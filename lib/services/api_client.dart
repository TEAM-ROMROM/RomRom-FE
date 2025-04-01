// lib/services/apis/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/log_utils.dart';

/// 모든 HTTP 요청을 처리
class ApiClient {
  static final TokenManager _tokenManager = TokenManager();

  /// API 요청 전송
  static Future<void> sendRequest({
    required String url,
    String method = 'POST', // 기본 POST
    Map<String, dynamic>? fields, // 일반적인 필드
    Map<String, List<File>>? files, // 파일 필드
    bool isAuthRequired = true,
    required Function(Map<String, dynamic>) onSuccess,
  }) async {
    try {
      // 인증이 필요한 경우 토큰 불러옴
      String? accessToken;
      String? refreshToken;

      if (isAuthRequired) {
        accessToken = await _tokenManager.getAccessToken();
        refreshToken = await _tokenManager.getRefreshToken();

        if (accessToken == null || refreshToken == null) {
          throw Exception('토큰이 없습니다.');
        }
      }

      // 요청 보내기
      http.Response response = await _sendMultipartRequest(
        url: url,
        method: method,
        accessToken: accessToken, // null -> 인증 헤더 추가 안함
        fields: fields,
        files: files,
      );

      // 성공 응답 처리 (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _handleResponse(response: response, url: url, onSuccess: onSuccess);
        return;
      }

      // 인증 실패 시 토큰 갱신 시도 (401)
      else if (isAuthRequired && response.statusCode == 401) {
        bool isRefreshed = await _refreshToken();

        // 토큰 재발급 성공 시 요청 재시도
        if (isRefreshed) {
          accessToken = await _tokenManager.getAccessToken();

          response = await _sendMultipartRequest(
            url: url,
            method: method,
            accessToken: accessToken,
            fields: fields,
            files: files,
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            await _handleResponse(response: response, url: url, onSuccess: onSuccess);
            return;
          } else {
            throw Exception('API 요청 실패 (토큰 갱신 후): ${response.statusCode}, ${response.body}');
          }
        } else {
          throw Exception('토큰 갱신 실패: 재로그인 필요');
        }
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}, ${response.body}');
      }
    } catch (error) {
      debugPrint('API 요청 중 오류 발생: $error');
      rethrow;
    }
  }

  /// API 요청 전송 처리
  static Future<http.Response> _sendMultipartRequest({
    required String url,
    required String method,
    String? accessToken,
    Map<String, dynamic>? fields,
    Map<String, List<File>>? files,
  }) async {
    var request = http.MultipartRequest(method, Uri.parse(url));

    // 인증 헤더 추가 (토큰이 있는 경우에만)
    if (accessToken != null) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }

    // 일반 필드 추가
    if (fields != null) {
      fields.forEach((key, value) {
        request.fields[key] = value.toString();
      });
    }

    // 파일 추가
    if (files != null) {
      for (var entry in files.entries) {
        for (var file in entry.value) {
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();
          var multipartFile = http.MultipartFile(
            entry.key,
            stream,
            length,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }
    }

    var streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }

  /// 응답 처리
  static Future<void> _handleResponse({
    required http.Response response,
    required String url,
    required Function(Map<String, dynamic>) onSuccess,
  }) async {
    if (response.body.isNotEmpty) {
      final responseData = jsonDecode(response.body);
      responsePrinter(url, responseData);
      onSuccess(responseData);
    } else {
      responsePrinter(url, null);
      debugPrint('서버 응답이 비어 있음. 빈 객체로 처리합니다.');
      onSuccess({});
    }
  }

  /// 토큰 갱신
  static Future<bool> _refreshToken() async {
    // refreshAccessToken() 함수 호출 (auth_api.dart에서 가져옴)
    // 여기서는 외부 함수를 호출하는 대신 직접 구현해도 됩니다
    try {
      // 외부 auth_api.dart의 함수를 import 하여 사용
      // return await refreshAccessToken();

      // 또는 직접 구현
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      const url = 'https://api.romrom.xyz/api/auth/reissue';
      var request = http.MultipartRequest('POST', Uri.parse(url));
      request.fields['refreshToken'] = refreshToken;

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String newAccessToken = responseData['accessToken'];
        await _tokenManager.saveTokens(newAccessToken, refreshToken);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('토큰 갱신 중 오류 발생: $e');
      return false;
    }
  }
}