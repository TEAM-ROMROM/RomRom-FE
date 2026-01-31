import 'dart:convert';

import 'package:romrom_fe/enums/error_code.dart';

class ErrorUtils {
  /// 예외 객체에서 errorCode를 추출해 사용자 메시지 반환
  /// 백엔드 오류 포맷 예시: {"errorCode":"DUPLICATE_REPORT", "errorMessage":"..."}
  static String getErrorMessage(Object error) {
    try {
      // 문자열로 변환 후 JSON 부분 추출
      final String errorStr = error.toString();
      final match = RegExp(r'\{.*\}').firstMatch(errorStr);
      if (match != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(jsonDecode(match.group(0)!));
        final code = json['errorCode'] as String?;
        final mapped = ErrorCode.fromCode(code);
        return mapped.koMessage;
      }
    } catch (_) {}
    return ErrorCode.unknown.koMessage;
  }
}
