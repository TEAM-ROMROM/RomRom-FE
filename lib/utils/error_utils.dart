import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:romrom_fe/enums/error_code.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/exceptions/ugc_violation_exception.dart';

class ErrorUtils {
  // 연결 끊김·시간 초과 공통 문구
  static const String networkErrorMessage = '인터넷 연결을 확인해 주세요';

  // 문자열로 감싼 예외 안 네트워크 오류 흔적 (Exception('...: $e') 형태 호환)
  static final RegExp _wrappedNetworkErrorPattern = RegExp(
    r'SocketException|TimeoutException|ClientException|HandshakeException|Failed host lookup|Connection (refused|reset|closed)|Network is unreachable',
  );

  /// 예외 객체 > 사용자 메시지 (네트워크 오류 > 연결 확인 문구, 그 외 errorCode 매핑)
  /// 백엔드 오류 포맷 예시: {"errorCode":"DUPLICATE_REPORT", "errorMessage":"..."}
  static String getErrorMessage(Object error) {
    // 네트워크 오류 > 연결 확인 문구 (서버 응답 없음)
    if (isNetworkError(error)) return networkErrorMessage;
    return getErrorCode(error).koMessage;
  }

  /// 예외 객체 > 서버가 준 사용자 문구 우선 메시지 (앱에 없는 신규 errorCode 대응)
  /// 순서: 네트워크 > 금칙어 문구 > 4xx 응답 errorMessage > errorCode 매핑
  static String getServerProvidedErrorMessage(Object error) {
    if (isNetworkError(error)) return networkErrorMessage;
    if (error is UgcViolationException) return error.errorMessage;
    if (error is ApiException && error.statusCode >= 400 && error.statusCode < 500) {
      final serverMessage = error.responseJson?['errorMessage'];
      if (serverMessage is String && serverMessage.trim().isNotEmpty) return serverMessage.trim();
    }
    return getErrorMessage(error);
  }

  /// 예외 객체 > 오류 코드 (화면이 코드별로 분기할 때, 모르는 형식 > unknown)
  static ErrorCode getErrorCode(Object error) {
    // ApiException > 파싱된 errorCode
    if (error is ApiException) return ErrorCode.fromCode(error.errorCode);

    // 그 외 > toString 안 JSON 정규식 추출 (문자열로 감싼 기존 예외 호환)
    try {
      final String errorStr = error.toString();
      final match = RegExp(r'\{.*\}').firstMatch(errorStr);
      if (match != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(match.group(0)!));
        final code = json['errorCode'] as String?;
        return ErrorCode.fromCode(code);
      }
    } catch (_) {
      // JSON 아님·형식 불일치 > unknown으로 폴백
    }
    return ErrorCode.unknown;
  }

  /// 서버 응답을 받지 못한 오류인지 (연결 실패, 시간 초과, TLS 실패)
  static bool isNetworkError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is http.ClientException ||
        error is HandshakeException) {
      return true;
    }
    if (error is ApiException) return false;
    return _wrappedNetworkErrorPattern.hasMatch(error.toString());
  }
}
