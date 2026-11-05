import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';

void main() {
  group('buildLogoutRequestFields (#1021)', () {
    test('FCM 토큰 있음 > fcmToken 필드 포함', () {
      final fields = buildLogoutRequestFields(accessToken: 'access', refreshToken: 'refresh', fcmToken: 'device-token');

      expect(fields, {'accessToken': 'access', 'refreshToken': 'refresh', 'fcmToken': 'device-token'});
    });

    test('FCM 토큰 없음·빈 값 > fcmToken 필드 생략', () {
      for (final missingFcmToken in [null, '']) {
        final fields = buildLogoutRequestFields(
          accessToken: 'access',
          refreshToken: 'refresh',
          fcmToken: missingFcmToken,
        );

        expect(fields, {'accessToken': 'access', 'refreshToken': 'refresh'});
        expect(fields.containsKey(logoutFcmTokenFieldName), isFalse);
      }
    });
  });
}
