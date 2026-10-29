import 'dart:convert';

/// API 비정상 응답(2xx 외) 예외: 상태 코드, 응답 본문, 백엔드 errorCode
/// toString은 기존 Exception 문구 그대로 (문자열 기반 호출부 호환)
class ApiException implements Exception {
  final int statusCode;
  final String responseBody;

  /// 응답 body JSON의 errorCode (비JSON·누락·비문자열이면 null)
  final String? errorCode;

  /// 401 > 토큰 재발급 > 재시도 응답에서 실패한 경우 true
  final bool isAfterTokenRefresh;

  ApiException({required this.statusCode, required this.responseBody, this.isAfterTokenRefresh = false})
    : errorCode = _parseErrorCode(responseBody);

  /// 응답 body > JSON 객체 (비JSON·객체 아님이면 null)
  Map<String, dynamic>? get responseJson => _decodeJsonObject(responseBody);

  static String? _parseErrorCode(String responseBody) {
    final errorCode = _decodeJsonObject(responseBody)?['errorCode'];
    return errorCode is String ? errorCode : null;
  }

  static Map<String, dynamic>? _decodeJsonObject(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() =>
      isAfterTokenRefresh ? 'API 요청 실패 (토큰 갱신 후): $statusCode, $responseBody' : 'API 요청 실패: $statusCode, $responseBody';
}
