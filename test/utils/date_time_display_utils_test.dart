import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/date_time_display_utils.dart';

void main() {
  // 기준 현재 시각 (2026-11-01 일요일 12:00 로컬)
  final now = DateTime(2026, 11, 1, 12);

  String timeAgoBefore(Duration elapsed) => getTimeAgo(now.subtract(elapsed), now: now);

  group('getTimeAgo', () {
    test('시각 없음 > 빈 문자열 (방금으로 대체하지 않음)', () {
      expect(getTimeAgo(null, now: now), '');
    });

    test('1초 미만·미래 시각 > 방금', () {
      expect(timeAgoBefore(Duration.zero), '방금');
      expect(timeAgoBefore(const Duration(milliseconds: 999)), '방금');
      expect(getTimeAgo(now.add(const Duration(minutes: 3)), now: now), '방금');
    });

    test('초·분·시간·일 경계', () {
      expect(timeAgoBefore(const Duration(seconds: 1)), '1초 전');
      expect(timeAgoBefore(const Duration(seconds: 59)), '59초 전');
      expect(timeAgoBefore(const Duration(seconds: 60)), '1분 전');
      expect(timeAgoBefore(const Duration(minutes: 59)), '59분 전');
      expect(timeAgoBefore(const Duration(hours: 1)), '1시간 전');
      expect(timeAgoBefore(const Duration(hours: 23, minutes: 59)), '23시간 전');
      expect(timeAgoBefore(const Duration(days: 1)), '1일 전');
      expect(timeAgoBefore(const Duration(days: 6)), '6일 전');
    });

    test('주·달 경계', () {
      expect(timeAgoBefore(const Duration(days: 7)), '1주 전');
      expect(timeAgoBefore(const Duration(days: 29)), '4주 전');
      expect(timeAgoBefore(const Duration(days: 30)), '1달 전');
      expect(timeAgoBefore(const Duration(days: 359)), '11달 전');
    });

    test('년 경계 (360~364일도 12달이 아니라 1년 전)', () {
      expect(timeAgoBefore(const Duration(days: 360)), '1년 전');
      expect(timeAgoBefore(const Duration(days: 364)), '1년 전');
      expect(timeAgoBefore(const Duration(days: 365)), '1년 전');
      expect(timeAgoBefore(const Duration(days: 729)), '1년 전');
      expect(timeAgoBefore(const Duration(days: 730)), '2년 전');
      expect(timeAgoBefore(const Duration(days: 365 * 5)), '5년 전');
    });
  });

  group('getLastActivityTime', () {
    test('시각 없음 > 오래 전 활동, 1분 미만 > 방금 전 활동', () {
      expect(getLastActivityTime(null, now: now), '오래 전 활동');
      expect(getLastActivityTime(now.subtract(const Duration(seconds: 30)), now: now), '방금 전 활동');
    });

    test('1분 이상 > 공통 경과 시간 + 활동', () {
      expect(getLastActivityTime(now.subtract(const Duration(minutes: 5)), now: now), '5분 전 활동');
      expect(getLastActivityTime(now.subtract(const Duration(days: 3)), now: now), '3일 전 활동');
      expect(getLastActivityTime(now.subtract(const Duration(days: 400)), now: now), '1년 전 활동');
    });
  });

  group('isSameLocalDate', () {
    test('같은 날 00:00 <-> 23:59 > 같은 날짜', () {
      expect(isSameLocalDate(DateTime(2026, 11, 1), DateTime(2026, 11, 1, 23, 59, 59)), isTrue);
    });

    test('자정 경계·연도 경계 > 다른 날짜', () {
      expect(isSameLocalDate(DateTime(2026, 10, 31, 23, 59), DateTime(2026, 11, 1)), isFalse);
      expect(isSameLocalDate(DateTime(2025, 12, 31, 23, 59), DateTime(2026, 1, 1)), isFalse);
      expect(isSameLocalDate(DateTime(2025, 11, 1, 10), DateTime(2026, 11, 1, 10)), isFalse);
    });

    test('UTC 입력은 로컬로 바꿔 비교 (시간대 무관)', () {
      final localMidnightAfter = DateTime(2026, 11, 1, 0, 5);
      final localBeforeMidnight = DateTime(2026, 10, 31, 23, 55);
      expect(isSameLocalDate(localMidnightAfter.toUtc(), localBeforeMidnight), isFalse);
      expect(isSameLocalDate(localMidnightAfter.toUtc(), DateTime(2026, 11, 1, 23)), isTrue);
    });
  });

  group('formatListTimestamp (채팅 목록·알림 목록)', () {
    test('시각 없음 > 빈 문자열', () {
      expect(formatListTimestamp(null, now: now), '');
    });

    test('오늘 > 시각만 (오늘 00:00 포함)', () {
      expect(formatListTimestamp(DateTime(2026, 11, 1, 15, 5), now: now), '오후 3:05');
      expect(formatListTimestamp(DateTime(2026, 11, 1), now: now), '오전 12:00');
    });

    test('로컬 자정 경계 > 어제 23:59는 어제, 그저께 23:59는 날짜', () {
      expect(formatListTimestamp(DateTime(2026, 10, 31, 23, 59, 59), now: now), '어제');
      expect(formatListTimestamp(DateTime(2026, 10, 31), now: now), '어제');
      expect(formatListTimestamp(DateTime(2026, 10, 30, 23, 59, 59), now: now), '10월 30일');
    });

    test('자정 직후 현재 > 직전 23:59는 어제 (시간 차 1분이어도 날짜 기준)', () {
      final justAfterMidnight = DateTime(2026, 11, 1, 0, 1);
      expect(formatListTimestamp(DateTime(2026, 10, 31, 23, 59), now: justAfterMidnight), '어제');
    });

    test('올해 이전 날짜 > "M월 d일"', () {
      expect(formatListTimestamp(DateTime(2026, 10, 28, 9), now: now), '10월 28일');
      expect(formatListTimestamp(DateTime(2026, 1, 1), now: now), '1월 1일');
    });

    test('연도 경계 > 이전 연도는 "yyyy. M. d.", 1월 1일의 어제는 12월 31일', () {
      expect(formatListTimestamp(DateTime(2025, 10, 28, 9), now: now), '2025. 10. 28.');
      final newYearsDay = DateTime(2026, 1, 1, 9);
      expect(formatListTimestamp(DateTime(2025, 12, 31, 23), now: newYearsDay), '어제');
      expect(formatListTimestamp(DateTime(2025, 12, 30, 23), now: newYearsDay), '2025. 12. 30.');
    });

    test('UTC 입력 > 로컬 날짜·시각 기준 (시간대 무관)', () {
      expect(formatListTimestamp(DateTime(2026, 11, 1, 0, 5).toUtc(), now: now), '오전 12:05');
      expect(formatListTimestamp(DateTime(2026, 10, 31, 23, 55).toUtc(), now: now), '어제');
    });
  });

  group('formatChatDateDividerLabel', () {
    test('연도·월·일·요일 (올해도 연도 표시)', () {
      expect(formatChatDateDividerLabel(DateTime(2026, 11, 1)), '2026년 11월 1일 일요일');
      expect(formatChatDateDividerLabel(DateTime(2026, 11, 2, 23, 59)), '2026년 11월 2일 월요일');
      expect(formatChatDateDividerLabel(DateTime(2025, 12, 31)), '2025년 12월 31일 수요일');
    });

    test('UTC 입력 > 로컬 날짜 기준 문구', () {
      final localMidnightAfter = DateTime(2026, 11, 1, 0, 5);
      expect(formatChatDateDividerLabel(localMidnightAfter.toUtc()), '2026년 11월 1일 일요일');
    });
  });

  group('formatMessageTime / isSameMinute', () {
    test('12시간제 오전·오후, 시각 없으면 빈 문자열', () {
      expect(formatMessageTime(DateTime(2026, 11, 1, 0, 5)), '오전 12:05');
      expect(formatMessageTime(DateTime(2026, 11, 1, 9, 5)), '오전 9:05');
      expect(formatMessageTime(DateTime(2026, 11, 1, 12, 30)), '오후 12:30');
      expect(formatMessageTime(null), '');
    });

    test('같은 분 판정 (날짜 다르면 false, 하나라도 없으면 false)', () {
      expect(isSameMinute(DateTime(2026, 11, 1, 9, 5, 1), DateTime(2026, 11, 1, 9, 5, 59)), isTrue);
      expect(isSameMinute(DateTime(2026, 11, 1, 9, 5), DateTime(2026, 11, 2, 9, 5)), isFalse);
      expect(isSameMinute(DateTime(2026, 11, 1, 9, 5), null), isFalse);
    });
  });
}
