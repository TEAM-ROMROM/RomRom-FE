import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/app_version_comparison.dart';

/// 버전 문자열 파싱·비교: 마디 숫자 비교, 마디 수 차이, v 접두어·접미사 허용
void main() {
  group('parseVersionSegments', () {
    test('정상·v 접두어·공백·접미사 > 숫자 마디', () {
      expect(parseVersionSegments('1.10.10'), [1, 10, 10]);
      expect(parseVersionSegments('v1.10.10'), [1, 10, 10]);
      expect(parseVersionSegments('V2'), [2]);
      expect(parseVersionSegments(' 1.9 '), [1, 9]);
      expect(parseVersionSegments('1.10.10-beta'), [1, 10, 10]);
      expect(parseVersionSegments('1.10.10+12'), [1, 10, 10]);
    });

    test('빈 값·형식 오류 > null', () {
      for (final rawVersion in ['', '  ', 'v', 'latest', '1..2', '1.2.', '.1', '1.x', 'vv1.2', '-1.2']) {
        expect(parseVersionSegments(rawVersion), isNull, reason: '"$rawVersion"');
      }
    });

    test('64비트 초과 숫자 > null', () {
      expect(parseVersionSegments('1.99999999999999999999999'), isNull);
    });
  });

  group('isVersionSegmentsLower', () {
    test('마디별 숫자 비교 (문자열 비교 아님) > 1.10.9 < 1.10.10', () {
      expect(isVersionSegmentsLower([1, 10, 9], [1, 10, 10]), isTrue);
      expect(isVersionSegmentsLower([1, 10, 10], [1, 10, 9]), isFalse);
      expect(isVersionSegmentsLower([1, 9, 67], [1, 10, 0]), isTrue);
    });

    test('같은 버전 > false', () {
      expect(isVersionSegmentsLower([1, 10, 10], [1, 10, 10]), isFalse);
    });

    test('마디 수 다름 > 짧은 쪽 0 채움', () {
      expect(isVersionSegmentsLower([1, 10], [1, 10, 0]), isFalse);
      expect(isVersionSegmentsLower([1, 10], [1, 10, 1]), isTrue);
      expect(isVersionSegmentsLower([1, 10, 1], [1, 10]), isFalse);
      expect(isVersionSegmentsLower([2], [1, 99, 99]), isFalse);
    });
  });
}
