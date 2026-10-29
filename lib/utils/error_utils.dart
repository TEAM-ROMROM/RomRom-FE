import 'dart:convert';

import 'package:romrom_fe/enums/error_code.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';

class ErrorUtils {
  /// 예외 객체에서 errorCode를 추출해 사용자 메시지 반환
  /// 백엔드 오류 포맷 예시: {"errorCode":"DUPLICATE_REPORT", "errorMessage":"..."}
  static String getErrorMessage(Object error) {
    // ApiException > 파싱된 errorCode
    if (error is ApiException) return ErrorCode.fromCode(error.errorCode).koMessage;

    // 그 외 > toString 안 JSON 정규식 추출 (문자열로 감싼 기존 예외 호환)
    try {
      final String errorStr = error.toString();
      final match = RegExp(r'\{.*\}').firstMatch(errorStr);
      if (match != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(match.group(0)!));
        final code = json['errorCode'] as String?;
        final mapped = ErrorCode.fromCode(code);
        return mapped.koMessage;
      }
    } catch (_) {
      // JSON 아님·형식 불일치 > unknown 메시지로 폴백
    }
    return ErrorCode.unknown.koMessage;
  }
}
