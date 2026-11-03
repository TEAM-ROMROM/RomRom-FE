import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/token_reissue_result.dart';

/// reissue 실패 응답 분류: 만료(재로그인) / 재시도 가능(408·429·5xx·연결 실패) / 거절(그 외)
void main() {
  test('401 EXPIRED_REFRESH_TOKEN > 만료, 재시도 불가', () {
    final result = TokenReissueResult.fromFailedResponse(
      statusCode: 401,
      responseBody: '{"errorCode":"EXPIRED_REFRESH_TOKEN"}',
    );
    expect(result.isRefreshTokenExpired, isTrue);
    expect(result.isRetryableFailure, isFalse);
    expect(result.isSuccess, isFalse);
  });

  test('401 다른 코드·403 제재·400 > 거절 (만료 아님, 재시도 불가)', () {
    for (final (statusCode, responseBody) in [
      (401, '{"errorCode":"INVALID_REFRESH_TOKEN"}'),
      (403, '{"errorCode":"SUSPENDED_MEMBER"}'),
      (400, 'bad'),
    ]) {
      final result = TokenReissueResult.fromFailedResponse(statusCode: statusCode, responseBody: responseBody);
      expect(result.isRefreshTokenExpired, isFalse, reason: '$statusCode');
      expect(result.isRetryableFailure, isFalse, reason: '$statusCode');
    }
  });

  test('408·429·5xx > 재시도 가능', () {
    for (final statusCode in [408, 429, 500, 502, 503]) {
      final result = TokenReissueResult.fromFailedResponse(statusCode: statusCode, responseBody: '');
      expect(result.isRetryableFailure, isTrue, reason: '$statusCode');
      expect(result.isRefreshTokenExpired, isFalse);
    }
  });

  test('연결 실패·시간 초과(응답 없음) > 재시도 가능', () {
    const result = TokenReissueResult.connectionFailed();
    expect(result.isRetryableFailure, isTrue);
    expect(result.isSuccess, isFalse);
  });
}
