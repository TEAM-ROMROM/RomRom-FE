/// 토큰 재발급 결과: 성공 시 reissue 응답 데이터, 실패 시 null + refresh 토큰 만료 여부
class TokenReissueResult {
  /// reissue 응답 body (성공 시에만 존재)
  final Map<String, dynamic>? responseData;

  /// 401 EXPIRED_REFRESH_TOKEN 여부 (true면 재로그인 필요)
  final bool isRefreshTokenExpired;

  const TokenReissueResult({this.responseData, this.isRefreshTokenExpired = false});

  const TokenReissueResult.failed({this.isRefreshTokenExpired = false}) : responseData = null;

  bool get isSuccess => responseData != null;
}
