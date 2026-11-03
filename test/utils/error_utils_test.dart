import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

  group('ErrorUtils 네트워크 오류', () {
    test('SocketException·TimeoutException·ClientException > 인터넷 연결 문구', () {
      for (final error in [
        const SocketException('Failed host lookup'),
        TimeoutException('timeout'),
        http.ClientException('Connection closed'),
      ]) {
        expect(ErrorUtils.isNetworkError(error), isTrue, reason: '$error');
        expect(ErrorUtils.getErrorMessage(error), ErrorUtils.networkErrorMessage);
      }
    });

    test('문자열로 감싼 네트워크 예외 > 인터넷 연결 문구', () {
      final wrapped = Exception('API 요청 실패: SocketException: Failed host lookup');

      expect(ErrorUtils.isNetworkError(wrapped), isTrue);
      expect(ErrorUtils.getErrorMessage(wrapped), ErrorUtils.networkErrorMessage);
    });

    test('서버 오류 응답 > 네트워크 오류 아님', () {
      final exception = ApiException(statusCode: 500, responseBody: 'oops');

      expect(ErrorUtils.isNetworkError(exception), isFalse);
      expect(ErrorUtils.isNetworkError(Exception('plain')), isFalse);
    });
  });

  group('ErrorUtils.getErrorCode', () {
    test('ApiException > errorCode enum', () {
      final exception = ApiException(statusCode: 404, responseBody: '{"errorCode":"DELETED_ITEM"}');

      expect(ErrorUtils.getErrorCode(exception), ErrorCode.deletedItem);
    });

    test('기존 문자열 Exception > 정규식 폴백으로 enum', () {
      final exception = Exception('API 요청 실패: 404, {"errorCode":"ITEM_NOT_FOUND"}');

      expect(ErrorUtils.getErrorCode(exception), ErrorCode.itemNotFound);
    });

    test('JSON 없는 Exception > unknown', () {
      expect(ErrorUtils.getErrorCode(Exception('plain')), ErrorCode.unknown);
    });
  });
}
