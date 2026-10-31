import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/debug/debug_config.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';

/// HTTP 로그 보안: 민감 헤더·필드 마스킹, 본문 길이 제한, 출력 게이트
/// 마스킹 대상 2종(헤더 3개, 키 이름에 token/password 포함) > 값을 `***` 로 치환
class LogMasking {
  LogMasking._();

  // 로그 본문 최대 길이 (2,000자)
  static const int maxBodyLength = 2000;

  // 마스킹된 값 표시
  static const String maskedValue = '***';

  // 마스킹 대상 헤더 (소문자 비교)
  static const Set<String> _maskedHeaderNames = {'authorization', 'cookie', 'set-cookie'};

  // 마스킹 대상 필드 키 포함 문자열 (소문자 비교)
  static const List<String> _maskedFieldKeywords = ['token', 'password'];

  /// 로그 출력 여부: 디버그 빌드 또는 테스트 빌드(.env TEST_BUILD)
  static bool get isHttpLoggingEnabled => kDebugMode || DebugConfig.isTestBuild;

  /// 에러 로그 문구: 로깅 허용 빌드는 전체, 그 외는 타입(+ApiException 이면 statusCode·errorCode)만 (응답 본문 노출 방지)
  static String describeErrorForLog(Object error) {
    if (isHttpLoggingEnabled) return error.toString();
    if (error is ApiException) {
      return 'ApiException(statusCode=${error.statusCode}, errorCode=${error.errorCode})';
    }
    return error.runtimeType.toString();
  }

  /// 헤더 마스킹: authorization, cookie, set-cookie 값 > `***`
  static Map<String, String> maskHeaders(Map<String, String> headers) {
    return headers.map(
      (headerName, headerValue) =>
          MapEntry(headerName, _maskedHeaderNames.contains(headerName.toLowerCase()) ? maskedValue : headerValue),
    );
  }

  /// JSON 값 마스킹: Map/List 재귀, 민감 키의 값 > `***`
  static dynamic maskJsonValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(key, _isMaskedFieldKey(key) ? maskedValue : maskJsonValue(nestedValue)),
      );
    }
    if (value is List) {
      return value.map(maskJsonValue).toList();
    }
    return value;
  }

  /// 본문 정리: JSON 이면 마스킹 후 pretty, 아니면 원문 > 최대 길이 초과분 잘라냄
  static String formatBody(String rawBody) {
    if (rawBody.isEmpty) return rawBody;
    return _truncate(_maskAndPrettyPrint(rawBody));
  }

  // 키 이름에 민감 문자열 포함 여부
  static bool _isMaskedFieldKey(Object? key) {
    final lowerCaseKey = key.toString().toLowerCase();
    return _maskedFieldKeywords.any(lowerCaseKey.contains);
  }

  // JSON(Map/List) 이면 마스킹 후 들여쓰기, 그 외 원문
  static String _maskAndPrettyPrint(String rawBody) {
    try {
      final decodedBody = jsonDecode(rawBody);
      if (decodedBody is! Map && decodedBody is! List) return rawBody;
      return const JsonEncoder.withIndent('  ').convert(maskJsonValue(decodedBody));
    } catch (_) {
      return rawBody;
    }
  }

  // 최대 길이 초과 시 잘라내고 `… (N자 생략)` 부가
  static String _truncate(String text) {
    if (text.length <= maxBodyLength) return text;
    final omittedLength = text.length - maxBodyLength;
    return '${text.substring(0, maxBodyLength)}… ($omittedLength자 생략)';
  }
}
