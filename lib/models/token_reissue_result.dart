import 'package:romrom_fe/exceptions/api_exception.dart';

/// 토큰 재발급 결과: 성공 시 reissue 응답 데이터, 실패 시 null + refresh 토큰 만료 여부 + 재시도 가능 여부
class TokenReissueResult {
  // 재시도 가능한 4xx: 408 요청 시간 초과, 429 요청 과다 (그 외 4xx는 거절)
  static const Set<int> _retryableClientErrorStatusCodes = {408, 429};

  /// reissue 응답 body (성공 시에만 존재)
  final Map<String, dynamic>? responseData;

  /// 401 EXPIRED_REFRESH_TOKEN 여부 (true면 재로그인 필요)
  final bool isRefreshTokenExpired;

  /// 연결 실패·408·429·5xx (true면 토큰 유지 후 다시 시도)
  final bool isRetryableFailure;

  const TokenReissueResult({this.responseData, this.isRefreshTokenExpired = false, this.isRetryableFailure = false});

  const TokenReissueResult.failed({this.isRefreshTokenExpired = false, this.isRetryableFailure = false})
    : responseData = null;

  /// 연결 실패·시간 초과 (서버 응답 없음 > 재시도 가능)
  const TokenReissueResult.connectionFailed()
    : responseData = null,
      isRefreshTokenExpired = false,
      isRetryableFailure = true;

  /// 실패 응답 분류: 401 EXPIRED_REFRESH_TOKEN > 만료, 408·429·5xx > 재시도 가능, 그 외(403 제재 포함) > 거절
  factory TokenReissueResult.fromFailedResponse({required int statusCode, required String responseBody}) {
    return TokenReissueResult.failed(
      isRefreshTokenExpired: statusCode == 401 && ApiException.parseErrorCode(responseBody) == 'EXPIRED_REFRESH_TOKEN',
      isRetryableFailure: statusCode >= 500 || _retryableClientErrorStatusCodes.contains(statusCode),
    );
  }

  bool get isSuccess => responseData != null;
}
