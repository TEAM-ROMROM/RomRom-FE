import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/log_masking.dart';

void main() {
  group('LogMasking.maskHeaders', () {
    test('Authorization 값만 *** 로 가리고 나머지는 유지', () {
      final masked = LogMasking.maskHeaders({'Authorization': 'Bearer abc', 'Content-Type': 'application/json'});
      expect(masked, {'Authorization': '***', 'Content-Type': 'application/json'});
    });

    test('소문자 cookie, Set-Cookie 도 가림 (대소문자 무관)', () {
      final masked = LogMasking.maskHeaders({'cookie': 'a=b', 'Set-Cookie': 'c=d'});
      expect(masked, {'cookie': '***', 'Set-Cookie': '***'});
    });
  });

  group('LogMasking.maskJsonValue', () {
    test('token·password 키 값만 중첩 Map/List 까지 재귀로 가림', () {
      final masked = LogMasking.maskJsonValue({
        'refreshToken': 'r',
        'nested': {'accessToken': 'a', 'name': 'n'},
        'list': [
          {'password': 'p'},
        ],
      });
      expect(masked, {
        'refreshToken': '***',
        'nested': {'accessToken': '***', 'name': 'n'},
        'list': [
          {'password': '***'},
        ],
      });
    });
  });

  group('LogMasking.formatBody', () {
    test('JSON 이면 민감 값을 가리고 pretty 출력', () {
      final formatted = LogMasking.formatBody('{"accessToken":"a","b":1}');
      expect(formatted.contains('"a"'), isFalse);
      expect(formatted.contains('"***"'), isTrue);
    });

    test('JSON 이 아니면 원문, 빈 문자열은 빈 문자열', () {
      expect(LogMasking.formatBody('not json'), 'not json');
      expect(LogMasking.formatBody(''), '');
    });

    test('최대 길이 초과 시 잘라내고 생략 글자 수 부가', () {
      final formatted = LogMasking.formatBody('x' * 2500);
      expect(formatted.startsWith('x' * LogMasking.maxBodyLength), isTrue);
      expect(formatted.contains('500자 생략'), isTrue);
      expect(formatted.length <= LogMasking.maxBodyLength + 30, isTrue);
    });
  });
}
