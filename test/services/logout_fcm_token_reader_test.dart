import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/logout_fcm_token_reader.dart';

void main() {
  group('readFcmTokenForLogout (#1021)', () {
    test('토큰 발급 성공 > 토큰 반환', () async {
      final fcmToken = await readFcmTokenForLogout(readFcmToken: () async => 'device-token');

      expect(fcmToken, 'device-token');
    });

    test('빈 값·null > null', () async {
      expect(await readFcmTokenForLogout(readFcmToken: () async => ''), isNull);
      expect(await readFcmTokenForLogout(readFcmToken: () async => null), isNull);
    });

    test('조회 오류 > 예외 없이 null', () async {
      final fcmToken = await readFcmTokenForLogout(readFcmToken: () async => throw Exception('no token'));

      expect(fcmToken, isNull);
    });

    test('응답 없음 > 상한 시간 뒤 null (로그아웃 지연 방지)', () async {
      final neverCompletingToken = Completer<String?>();
      final stopwatch = Stopwatch()..start();

      final fcmToken = await readFcmTokenForLogout(
        readFcmToken: () => neverCompletingToken.future,
        timeout: const Duration(milliseconds: 50),
      );

      expect(fcmToken, isNull);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 1)));
    });

    test('기본 상한 2초', () {
      expect(logoutFcmTokenTimeout, const Duration(seconds: 2));
    });
  });
}
