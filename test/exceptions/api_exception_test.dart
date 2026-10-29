import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';

void main() {
  group('ApiException', () {
    test('JSON body > errorCode 파싱', () {
      final exception = ApiException(
        statusCode: 400,
        responseBody: '{"errorCode":"DUPLICATE_REPORT","errorMessage":"x"}',
      );

      expect(exception.errorCode, 'DUPLICATE_REPORT');
      expect(exception.responseJson?['errorMessage'], 'x');
    });

    test('비JSON body > errorCode·responseJson null', () {
      final exception = ApiException(statusCode: 500, responseBody: 'oops');

      expect(exception.errorCode, isNull);
      expect(exception.responseJson, isNull);
    });

    test('JSON 배열·errorCode 비문자열 > errorCode null', () {
      expect(ApiException(statusCode: 400, responseBody: '[1,2]').errorCode, isNull);
      expect(ApiException(statusCode: 400, responseBody: '{"errorCode":123}').errorCode, isNull);
    });

    test('toString > 기존 문구 유지', () {
      final exception = ApiException(statusCode: 400, responseBody: '{"errorCode":"DUPLICATE_REPORT"}');

      expect(exception.toString(), startsWith('API 요청 실패: 400, '));
      expect(exception.toString(), 'API 요청 실패: 400, {"errorCode":"DUPLICATE_REPORT"}');
    });

    test('토큰 갱신 후 실패 > toString 기존 문구 유지', () {
      final exception = ApiException(statusCode: 401, responseBody: 'denied', isAfterTokenRefresh: true);

      expect(exception.toString(), 'API 요청 실패 (토큰 갱신 후): 401, denied');
    });
  });
}
