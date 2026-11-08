import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/keyword_alert_rejection_reason.dart';
import 'package:romrom_fe/utils/keyword_alert_rules.dart';

void main() {
  group('normalizeKeywordAlert (서버 정규화와 동일)', () {
    test('앞뒤 공백 제거 > 연속 공백 1칸 > 소문자', () {
      expect(normalizeKeywordAlert('  Nintendo   Switch\t OLED  '), 'nintendo switch oled');
      expect(normalizeKeywordAlert('아이폰\n15'), '아이폰 15');
    });

    test('정리는 대소문자 원문 유지', () {
      expect(tidyKeywordAlert('  iPhone   15 Pro '), 'iPhone 15 Pro');
    });

    test('같은 키워드 판정은 정규화 값 비교', () {
      expect(isSameKeywordAlert('iPhone 15', '  iphone   15 '), isTrue);
      expect(isSameKeywordAlert('아이폰', '아이폰15'), isFalse);
    });
  });

  group('findKeywordAlertRejectionReason', () {
    KeywordAlertRejectionReason? findReason(String keyword, {List<String> registered = const [], int maximum = 10}) =>
        findKeywordAlertRejectionReason(
          keyword: keyword,
          registeredKeywords: registered,
          maximumKeywordAlertCount: maximum,
        );

    test('정규화 후 2~20자만 통과 (경계값)', () {
      expect(findReason(' 가 '), KeywordAlertRejectionReason.tooShort);
      expect(findReason('가나'), isNull);
      expect(findReason('가' * 20), isNull);
      expect(findReason('가' * 21), KeywordAlertRejectionReason.tooLong);
      // 연속 공백은 1칸으로 세서 길이 판정
      expect(findReason('가     나'), isNull);
    });

    test('이미 등록한 키워드 (대소문자·공백 차이 무시)', () {
      expect(
        findReason('  NINTENDO  switch', registered: ['Nintendo Switch']),
        KeywordAlertRejectionReason.alreadyRegistered,
      );
    });

    test('최대 개수 도달 > 개수 초과 (중복이 먼저)', () {
      final registered = List.generate(10, (index) => '키워드$index');
      expect(findReason('새 키워드', registered: registered), KeywordAlertRejectionReason.limitReached);
      expect(findReason('키워드3', registered: registered), KeywordAlertRejectionReason.alreadyRegistered);
      expect(findReason('새 키워드', registered: registered.take(9).toList()), isNull);
    });

    test('거부 문구: 개수 초과는 서버 최대 개수 사용', () {
      expect(
        KeywordAlertRejectionReason.limitReached.buildMessage(maximumKeywordAlertCount: 7),
        '키워드는 최대 7개까지 등록할 수 있어요',
      );
      expect(
        KeywordAlertRejectionReason.tooShort.buildMessage(maximumKeywordAlertCount: 10),
        '키워드는 $minimumKeywordAlertLength자 이상 입력해 주세요',
      );
    });
  });
}
