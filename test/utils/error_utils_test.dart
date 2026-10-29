import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/error_code.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/utils/error_utils.dart';

void main() {
  group('ErrorUtils.getErrorMessage', () {
    test('ApiException > errorCode 메시지', () {
      final exception = ApiException(statusCode: 400, responseBody: '{"errorCode":"DUPLICATE_REPORT"}');

      expect(ErrorUtils.getErrorMessage(exception), ErrorCode.fromCode('DUPLICATE_REPORT').koMessage);
    });

    test('ApiException 여러 줄 JSON body > errorCode 메시지 (정규식 단일행 한계 무관)', () {
      final exception = ApiException(statusCode: 400, responseBody: '{\n  "errorCode": "DUPLICATE_REPORT"\n}');

      expect(ErrorUtils.getErrorMessage(exception), ErrorCode.fromCode('DUPLICATE_REPORT').koMessage);
    });

    test('ApiException 비JSON body > unknown 메시지', () {
      final exception = ApiException(statusCode: 500, responseBody: 'oops');

      expect(ErrorUtils.getErrorMessage(exception), ErrorCode.unknown.koMessage);
    });

    test('기존 문자열 Exception > 정규식 폴백으로 같은 메시지', () {
      final exception = Exception('API 요청 실패: 400, {"errorCode":"DUPLICATE_REPORT"}');

      expect(ErrorUtils.getErrorMessage(exception), ErrorCode.fromCode('DUPLICATE_REPORT').koMessage);
    });

    test('JSON 없는 Exception > unknown 메시지', () {
      expect(ErrorUtils.getErrorMessage(Exception('plain')), ErrorCode.unknown.koMessage);
    });
  });
}
