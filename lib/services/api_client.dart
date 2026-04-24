// lib/services/apis/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/ugc_violation_exception.dart';
import 'package:romrom_fe/main.dart' show navigatorKey;
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/screens/account_suspended_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/log_http_client_interceptor.dart';
import 'package:romrom_fe/utils/log_utils.dart';

/// 모든 HTTP 요청을 처리
class ApiClient {
  static final TokenManager _tokenManager = TokenManager();
  static final LoggingHttpClient _client = LoggingHttpClient(http.Client());

  /// 동시 다발적 403 응답 시 중복 네비게이션 방지 플래그
  static bool _isSuspendedHandling = false;

  /// 동시 다발적 세션 만료(EXPIRED_REFRESH_TOKEN) 시 중복 로그아웃 방지 플래그
  static bool _isSessionExpiredHandling = false;

  /// 제재 처리 플래그 리셋 (로그아웃/재로그인 시 호출)
  static void resetSuspendedFlag() {
    _isSuspendedHandling = false;
  }

  /// 세션 만료 처리 플래그 리셋 (재로그인 성공 시 호출)
  static void resetSessionExpiredFlag() {
    _isSessionExpiredHandling = false;
  }

  /// 403 SUSPENDED_MEMBER 응답 글로벌 처리
  /// 제재된 회원이 API 호출 시 서버에서 403 + SUSPENDED_MEMBER를 반환하면
  /// 토큰 삭제 후 제재 안내 화면으로 이동
  /// 반환값: AccountSuspendedException(실제 제재 데이터) 또는 null(제재 아님)
  static AccountSuspendedException? _handleSuspendedResponse(http.Response response) {
    if (_isSuspendedHandling) return AccountSuspendedException(suspendReason: '', suspendedUntil: '');
    if (response.statusCode == 403 && response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        if (data['errorCode'] == 'SUSPENDED_MEMBER') {
          _isSuspendedHandling = true;
          final suspendReason = data['suspendReason'] as String? ?? '';
          // suspendedUntil: 문자열("2026-03-26T16:32:00") 또는 배열([2026,3,26,16,32]) 모두 처리
          final rawUntil = data['suspendedUntil'];
          final suspendedUntil = rawUntil is List
              ? DateTime(
                  rawUntil[0],
                  rawUntil[1],
                  rawUntil[2],
                  rawUntil.length > 3 ? rawUntil[3] : 0,
                  rawUntil.length > 4 ? rawUntil[4] : 0,
                ).toIso8601String()
              : (rawUntil as String? ?? '');
          debugPrint('제재된 회원 감지 (403 SUSPENDED_MEMBER)');
          _tokenManager.deleteTokens();

          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            context.navigateTo(
              screen: AccountSuspendedScreen(suspendReason: suspendReason, suspendedUntil: suspendedUntil),
              type: NavigationTypes.clearStackImmediate,
            );
          }
          return AccountSuspendedException(suspendReason: suspendReason, suspendedUntil: suspendedUntil);
        }
      } catch (e) {
        debugPrint('403 응답 body 파싱 실패: $e');
      }
    }
    return null; // 제재 아님
  }

  /// 400 PROHIBITED_CONTENT 응답 처리 (UGC 필터링 위반)
  /// UgcViolationException 반환 또는 null(UGC 위반 아님)
  static UgcViolationException? _handleUgcViolationResponse(http.Response response) {
    if (response.statusCode == 400 && response.body.isNotEmpty) {
      try {
        final data = jsonDecode(response.body);
        if (data['errorCode'] == 'PROHIBITED_CONTENT') {
          return UgcViolationException(
            errorCode: data['errorCode'] as String? ?? '',
            errorMessage: data['errorMessage'] as String? ?? '부적절한 표현이 포함되어 있습니다.',
            violatingText: data['violatingText'] as String? ?? '',
            fieldName: data['fieldName'] as String? ?? '',
          );
        }
      } catch (e) {
        debugPrint('400 응답 body 파싱 실패: $e');
      }
    }
    return null;
  }

  /// MultipartRequest 요청 전송 (form-data 형식, 파일 업로드 지원)
  static Future<http.Response> sendMultipartRequest({
    required String url,
    String method = 'POST',
    Map<String, dynamic>? fields,
    Map<String, List<File>>? files,
    bool isAuthRequired = true,
    required Function(dynamic) onSuccess,
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

      // 제재된 회원 체크 (403 SUSPENDED_MEMBER)
      final suspendedException = _handleSuspendedResponse(response);
      if (suspendedException != null) throw suspendedException;

      // UGC 필터링 위반 체크 (400 PROHIBITED_CONTENT)
      final ugcViolation = _handleUgcViolationResponse(response);
      if (ugcViolation != null) throw ugcViolation;

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

          // 토큰 갱신 후 재시도에서도 UGC 위반 체크
          final ugcViolationRetry = _handleUgcViolationResponse(response);
          if (ugcViolationRetry != null) throw ugcViolationRetry;

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

      // 제재된 회원 체크 (403 SUSPENDED_MEMBER)
      final suspendedExceptionHttp = _handleSuspendedResponse(response);
      if (suspendedExceptionHttp != null) throw suspendedExceptionHttp;

      // UGC 필터링 위반 체크 (400 PROHIBITED_CONTENT)
      final ugcViolationHttp = _handleUgcViolationResponse(response);
      if (ugcViolationHttp != null) throw ugcViolationHttp;

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

          response = await _executeHttpRequest(url: url, method: method, accessToken: accessToken, body: body);

          // 토큰 갱신 후 재시도에서도 UGC 위반 체크
          final ugcViolationHttpRetry = _handleUgcViolationResponse(response);
          if (ugcViolationHttpRetry != null) throw ugcViolationHttpRetry;

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

    // 파일 추가 (MIME type 명시)
    if (files != null) {
      for (var entry in files.entries) {
        for (var file in entry.value) {
          var stream = http.ByteStream(file.openRead());
          var length = await file.length();

          // 파일 확장자로 MIME 타입 추정
          String path = file.path.toLowerCase();
          String mimeType = 'application/octet-stream';
          if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
            mimeType = 'image/jpeg';
          } else if (path.endsWith('.png')) {
            mimeType = 'image/png';
          } else if (path.endsWith('.gif')) {
            mimeType = 'image/gif';
          }

          var multipartFile = http.MultipartFile(
            entry.key,
            stream,
            length,
            filename: file.path.split('/').last,
            contentType: MediaType.parse(mimeType), // MIME 타입 명시
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
    Map<String, String> headers = {'Content-Type': 'application/json'};

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

      final String url = '${AppUrls.baseUrl}/api/auth/reissue';

      var response = await _executeMultipartRequest(url: url, method: 'POST', fields: {'refreshToken': refreshToken});

      // 토큰 갱신(reissue) 시에도 제재된 회원 체크 (403 SUSPENDED_MEMBER)
      if (_handleSuspendedResponse(response) != null) {
        return false;
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String newAccessToken = responseData['accessToken'];
        // Refresh Token Rotation: 응답에 새 refreshToken이 있으면 갱신, 없으면 기존 유지
        final String? newRefreshToken = responseData['refreshToken'] as String?;
        await _tokenManager.saveTokens(newAccessToken, newRefreshToken ?? refreshToken);
        return true;
      }

      // EXPIRED_REFRESH_TOKEN: 토큰 삭제 + 하트비트 중단 + 로그인 화면 이동
      if (!_isSessionExpiredHandling && response.statusCode == 401) {
        try {
          final data = jsonDecode(response.body);
          if (data['errorCode'] == 'EXPIRED_REFRESH_TOKEN') {
            _isSessionExpiredHandling = true;
            debugPrint('세션 만료 감지 (EXPIRED_REFRESH_TOKEN): 자동 로그아웃 처리');
            await _tokenManager.deleteTokens();
            HeartbeatManager.instance.stop();
            // 회원 캐시 삭제
            await MemberManager.clearMemberInfo();
            final context = navigatorKey.currentContext;
            if (context != null && context.mounted) {
              context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.fadeTransition);
            }
          }
        } catch (e) {
          debugPrint('세션 만료 응답 파싱 실패: $e');
        }
      }

      return false;
    } catch (e) {
      debugPrint('토큰 갱신 중 오류 발생: $e');
      return false;
    }
  }
}
