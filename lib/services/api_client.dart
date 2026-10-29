// lib/services/apis/api_client.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:romrom_fe/enums/navigation_types.dart';
import 'package:romrom_fe/enums/token_keys.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/exceptions/ugc_violation_exception.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/token_reissue_result.dart';
import 'package:romrom_fe/screens/account_suspended_screen.dart';
import 'package:romrom_fe/screens/login_screen.dart';
import 'package:romrom_fe/services/heart_beat_manager.dart';
import 'package:romrom_fe/services/member_manager_service.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/log_http_client_interceptor.dart';
import 'package:romrom_fe/utils/log_masking.dart';
import 'package:romrom_fe/utils/single_flight.dart';

/// 모든 HTTP 요청을 처리
class ApiClient {
  static final TokenManager _tokenManager = TokenManager();
  static final LoggingHttpClient _client = LoggingHttpClient(http.Client());

  /// 동시 401 시 reissue 1회만 실행 (refresh 토큰 rotation 상호 무효화 방지)
  static final SingleFlight<TokenReissueResult> _reissueFlight = SingleFlight<TokenReissueResult>();

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

  /// MultipartRequest 요청 전송 (form-data 형식, 파일 업로드 지원): 공통 파이프라인 > 2xx 응답 onSuccess 전달
  static Future<http.Response> sendMultipartRequest({
    required String url,
    String method = 'POST',
    Map<String, dynamic>? fields,
    Map<String, List<File>>? files,
    bool isAuthRequired = true,
    required Function(dynamic) onSuccess,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final response = await _sendWithAuthRetry(
      isAuthRequired: isAuthRequired,
      execute: (accessToken) => _executeMultipartRequest(
        url: url,
        method: method,
        accessToken: accessToken, // null -> 인증 헤더 추가 안함
        fields: fields,
        files: files,
        timeout: timeout,
      ),
    );
    _notifyMultipartSuccess(response, onSuccess);
    return response;
  }

  /// HTTP 요청 전송 (JSON 형식, 다양한 메소드 지원): 공통 파이프라인 (onSuccess 미호출, 호출부가 응답 직접 처리)
  static Future<http.Response> sendHttpRequest({
    required String url,
    required String method,
    Map<String, dynamic>? body,
    bool isAuthRequired = true,
    required Function(Map<String, dynamic>) onSuccess,
    Duration timeout = const Duration(seconds: 15),
  }) {
    return _sendWithAuthRetry(
      isAuthRequired: isAuthRequired,
      execute: (accessToken) =>
          _executeHttpRequest(url: url, method: method, accessToken: accessToken, body: body, timeout: timeout),
    );
  }

  /// 인증 요청 공통: 토큰 확인 > 실행 > 제재·UGC 검사 > 2xx 반환 / 401 재발급 후 1회 재시도 / 그 외 ApiException
  static Future<http.Response> _sendWithAuthRetry({
    required bool isAuthRequired,
    required Future<http.Response> Function(String? accessToken) execute,
  }) async {
    try {
      final String? sentAccessToken = isAuthRequired ? await _loadAccessTokenOrThrow() : null;
      final response = await execute(sentAccessToken);
      _throwIfSuspendedOrUgcViolation(response);
      if (_isSuccessResponse(response)) return response;

      if (!isAuthRequired || response.statusCode != 401) {
        throw ApiException(statusCode: response.statusCode, responseBody: response.body);
      }

      // 401 > 토큰 확보 > 1회 재시도 (재시도 응답도 제재·UGC 검사)
      final String? retryAccessToken = await _resolveRetryAccessToken(sentAccessToken);
      final retryResponse = await execute(retryAccessToken);
      _throwIfSuspendedOrUgcViolation(retryResponse);
      if (_isSuccessResponse(retryResponse)) return retryResponse;
      throw ApiException(
        statusCode: retryResponse.statusCode,
        responseBody: retryResponse.body,
        isAfterTokenRefresh: true,
      );
    } catch (error) {
      debugPrint('API 요청 중 오류 발생: ${LogMasking.describeErrorForLog(error)}');
      rethrow;
    }
  }

  /// 저장된 accessToken (access·refresh 둘 중 하나라도 없으면 예외)
  static Future<String> _loadAccessTokenOrThrow() async {
    final accessToken = await _tokenManager.getAccessToken();
    final refreshToken = await _tokenManager.getRefreshToken();
    if (accessToken == null || refreshToken == null) {
      throw Exception('토큰이 없습니다.');
    }
    return accessToken;
  }

  /// 401 재시도 토큰: 다른 요청이 이미 재발급했으면 저장 토큰 / 아니면 재발급 후 새 토큰 (실패 시 예외)
  static Future<String?> _resolveRetryAccessToken(String? sentAccessToken) async {
    final storedAccessToken = await _tokenManager.getAccessToken();
    if (!shouldReissueToken(sentAccessToken: sentAccessToken, storedAccessToken: storedAccessToken)) {
      return storedAccessToken;
    }
    final isReissued = await _reissueTokensForRetry();
    if (!isReissued) throw Exception('토큰 갱신 실패: 재로그인 필요');
    return _tokenManager.getAccessToken();
  }

  /// 401 재발급 판정: 보낸 토큰 == 저장 토큰이면 재발급 (늦게 도착한 401의 중복 재발급 방지, 저장 토큰 없음도 재발급 경로)
  @visibleForTesting
  static bool shouldReissueToken({required String? sentAccessToken, required String? storedAccessToken}) {
    return storedAccessToken == null || storedAccessToken == sentAccessToken;
  }

  /// 제재(403 SUSPENDED_MEMBER)·UGC 위반(400 PROHIBITED_CONTENT) 응답이면 해당 예외 throw
  static void _throwIfSuspendedOrUgcViolation(http.Response response) {
    final suspendedException = _handleSuspendedResponse(response);
    if (suspendedException != null) throw suspendedException;

    final ugcViolation = _handleUgcViolationResponse(response);
    if (ugcViolation != null) throw ugcViolation;
  }

  static bool _isSuccessResponse(http.Response response) => response.statusCode >= 200 && response.statusCode < 300;

  /// multipart 2xx 응답 > onSuccess 전달 (빈 body > {}, 디코딩·콜백 오류는 로그만)
  static void _notifyMultipartSuccess(http.Response response, Function(dynamic) onSuccess) {
    if (response.body.isEmpty) {
      onSuccess({});
      return;
    }
    try {
      onSuccess(jsonDecode(response.body));
    } catch (e) {
      debugPrint('응답 데이터 처리 중 오류: $e');
    }
  }

  /// Multipart Request 실행 (form-data)
  static Future<http.Response> _executeMultipartRequest({
    required String url,
    required String method,
    String? accessToken,
    Map<String, dynamic>? fields,
    Map<String, List<File>>? files,
    Duration timeout = const Duration(seconds: 15),
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
    var streamedResponse = await _client.sendWithTimeout(request, timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  /// HTTP Request 실행 (JSON)
  static Future<http.Response> _executeHttpRequest({
    required String url,
    required String method,
    String? accessToken,
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    Uri uri = Uri.parse(url);
    Map<String, String> headers = {'Content-Type': 'application/json'};

    if (accessToken != null) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final request = http.Request(method.toUpperCase(), uri);
    request.headers.addAll(headers);
    if (body != null) {
      request.body = jsonEncode(body);
    }

    final streamedResponse = await _client.sendWithTimeout(request, timeout);
    return await http.Response.fromStream(streamedResponse);
  }

  /// 토큰 재발급 단일 실행: 진행 중이면 같은 Future 공유 (예외 없음, 실패 결과 반환)
  static Future<TokenReissueResult> reissueTokens() => _reissueFlight.run(_requestTokenReissue);

  /// reissue 요청 > 제재 확인 > 200 토큰 저장 (rotation) / 401 refresh 만료 판정 (화면 이동은 제재만)
  static Future<TokenReissueResult> _requestTokenReissue() async {
    try {
      final refreshToken = await _tokenManager.getRefreshToken();
      if (refreshToken == null) return const TokenReissueResult.failed();

      final String url = '${AppUrls.baseUrl}/api/auth/reissue';
      final response = await _executeMultipartRequest(
        url: url,
        method: 'POST',
        fields: {TokenKeys.refreshToken.name: refreshToken},
      );

      // 제재 회원 (403 SUSPENDED_MEMBER > 제재 화면 이동)
      if (_handleSuspendedResponse(response) != null) return const TokenReissueResult.failed();

      // 재발급 성공 (rotation: 새 refreshToken 없으면 기존 유지)
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final String newAccessToken = responseData[TokenKeys.accessToken.name];
        final String? newRefreshToken = responseData[TokenKeys.refreshToken.name] as String?;
        await _tokenManager.saveTokens(newAccessToken, newRefreshToken ?? refreshToken);
        return TokenReissueResult(responseData: responseData);
      }

      // refresh 토큰 만료 (401 EXPIRED_REFRESH_TOKEN)
      return TokenReissueResult.failed(isRefreshTokenExpired: _isExpiredRefreshTokenResponse(response));
    } catch (e) {
      debugPrint('토큰 갱신 중 오류 발생: $e');
      return const TokenReissueResult.failed();
    }
  }

  /// 401 + errorCode EXPIRED_REFRESH_TOKEN 여부
  static bool _isExpiredRefreshTokenResponse(http.Response response) {
    if (response.statusCode != 401) return false;
    try {
      final data = jsonDecode(response.body);
      return data is Map && data['errorCode'] == 'EXPIRED_REFRESH_TOKEN';
    } catch (e) {
      debugPrint('세션 만료 응답 파싱 실패: $e');
      return false;
    }
  }

  /// 401 재시도용 재발급: 만료면 세션 만료 처리 > 성공 여부
  static Future<bool> _reissueTokensForRetry() async {
    final reissueResult = await reissueTokens();
    if (reissueResult.isRefreshTokenExpired) await _handleSessionExpired();
    return reissueResult.isSuccess;
  }

  /// 세션 만료 처리: 토큰 삭제 > 하트비트 중단 > 회원 캐시 삭제 > 로그인 화면 (중복 방지)
  static Future<void> _handleSessionExpired() async {
    if (_isSessionExpiredHandling) return;
    _isSessionExpiredHandling = true;
    debugPrint('세션 만료 감지 (EXPIRED_REFRESH_TOKEN): 자동 로그아웃 처리');
    try {
      await _tokenManager.deleteTokens();
      HeartbeatManager.instance.stop();
      await MemberManager.clearMemberInfo();
      final context = navigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.navigateTo(screen: const LoginScreen(), type: NavigationTypes.fadeTransition);
      }
    } catch (e) {
      debugPrint('세션 만료 처리 실패: $e');
    }
  }
}
