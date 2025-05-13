// lib/services/apis/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/log_http_client_interceptor.dart';
import 'package:romrom_fe/utils/log_utils.dart';

/// 모든 HTTP 요청을 처리
class ApiClient {
  static final TokenManager _tokenManager = TokenManager();
  static final LoggingHttpClient _client = LoggingHttpClient(http.Client());

  /// MultipartRequest 요청 전송 (form-data 형식, 파일 업로드 지원)
  static Future<http.Response> sendMultipartRequest({
    required String url,
    String method = 'POST',
    Map<String, dynamic>? fields,
    Map<String, List<File>>? files,
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
      http.Response response = await _executeMultipartRequest(
        url: url,
        method: method,
        accessToken: accessToken, // null -> 인증 헤더 추가 안함
        fields: fields,
        files: files,
      );

      // 성공 응답 처리 (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          try {
            final responseData = jsonDecode(response.body);
            // 응답이 성공적이면 onSuccess 콜백 실행
            onSuccess(responseData);
          } catch (e) {
            debugPrint('응답 데이터 처리 중 오류: $e');
          }
        } else {
          onSuccess({});
        }
        return response;
      }
      // 인증 실패 시 토큰 갱신 시도 (401)
      else if (isAuthRequired && response.statusCode == 401) {
        bool isRefreshed = await _refreshToken();

        // 토큰 재발급 성공 시 요청 재시도
        if (isRefreshed) {
          accessToken = await _tokenManager.getAccessToken();

          response = await _executeMultipartRequest(
            url: url,
            method: method,
            accessToken: accessToken,
            fields: fields,
            files: files,
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            if (response.body.isNotEmpty) {
              try {
                final responseData = jsonDecode(response.body);
                onSuccess(responseData);
              } catch (e) {
                debugPrint('응답 데이터 처리 중 오류: $e');
              }
            } else {
              onSuccess({});
            }
            return response;
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

  /// HTTP 요청 전송 (JSON 형식, 다양한 메소드 지원)
  static Future<http.Response> sendHttpRequest({
    required String url,
    required String method,
    Map<String, dynamic>? body,
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
      http.Response response = await _executeHttpRequest(
        url: url,
        method: method,
        accessToken: accessToken,
        body: body,
      );

      // 성공 응답 처리 (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // await _handleResponse(response: response, url: url, onSuccess: onSuccess);
        return response;
      }
      // 인증 실패 시 토큰 갱신 시도 (401)
      else if (isAuthRequired && response.statusCode == 401) {
        bool isRefreshed = await _refreshToken();

        // 토큰 재발급 성공 시 요청 재시도
        if (isRefreshed) {
          accessToken = await _tokenManager.getAccessToken();

          response = await _executeHttpRequest(
            url: url,
            method: method,
            accessToken: accessToken,
            body: body,
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            return response;
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

  /// Multipart Request 실행 (form-data)
  static Future<http.Response> _executeMultipartRequest({
    required String url,
    required String method,
    String? accessToken,
    Map<String, dynamic>? fields,
    Map<String, List<File>>? files,
  }) async {
    // MultipartRequest 생성
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

    // 로깅 클라이언트로 요청 전송
    var streamedResponse = await _client.send(request);
    return await http.Response.fromStream(streamedResponse);
  }

  /// HTTP Request 실행 (JSON)
  static Future<http.Response> _executeHttpRequest({
    required String url,
    required String method,
    String? accessToken,
    Map<String, dynamic>? body,
  }) async {
    // Request 준비
    Uri uri = Uri.parse(url);
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    
    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    
    String? jsonBody;
    if (body != null) {
      jsonBody = jsonEncode(body);
    }
    
    http.Response response;
    
    // HTTP 메소드에 따라 요청 실행
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: jsonBody);
        break;
      case 'PUT':
        response = await _client.put(uri, headers: headers, body: jsonBody);
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers, body: jsonBody);
        break;
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: jsonBody);
        break;
      default:
        throw Exception('지원하지 않는 HTTP 메소드: $method');
    }
    
    return response;
  }

  /// 응답 처리
  /// ignore: unused_element
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
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) return false;

      const String url = '${AppUrls.baseUrl}/api/auth/reissue';

      // 토큰 갱신
      var response = await _executeMultipartRequest(
        url: url,
        method: 'POST',
        fields: {'refreshToken': refreshToken},
      );

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
