import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/exceptions/account_suspended_exception.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/exceptions/email_already_registered_exception.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';

void main() {
  ApiException buildApiException(int statusCode, String responseBody) =>
      ApiException(statusCode: statusCode, responseBody: responseBody);

  group('toEmailAlreadyRegisteredException', () {
    test('409 본문의 registeredSocialPlatform 전달', () {
      final exception = RomAuthApi.toEmailAlreadyRegisteredException(
        buildApiException(409, '{"registeredSocialPlatform":"GOOGLE"}'),
      );
      expect(exception.registeredSocialPlatform, 'GOOGLE');
    });

    test('비JSON·필드 누락이면 빈 문자열', () {
      expect(
        RomAuthApi.toEmailAlreadyRegisteredException(buildApiException(409, 'not json')).registeredSocialPlatform,
        '',
      );
      expect(RomAuthApi.toEmailAlreadyRegisteredException(buildApiException(409, '{}')).registeredSocialPlatform, '');
    });
  });

  group('toKakaoFirebaseTokenException', () {
    test('409 > EmailAlreadyRegisteredException', () {
      final exception = RomAuthApi.toKakaoFirebaseTokenException(
        buildApiException(409, '{"registeredSocialPlatform":"APPLE"}'),
      );
      expect(exception, isA<EmailAlreadyRegisteredException>());
      expect((exception as EmailAlreadyRegisteredException).registeredSocialPlatform, 'APPLE');
    });

    test('errorCode EMAIL_ALREADY_REGISTERED (409 아님) > EmailAlreadyRegisteredException', () {
      final exception = RomAuthApi.toKakaoFirebaseTokenException(
        buildApiException(400, '{"errorCode":"EMAIL_ALREADY_REGISTERED"}'),
      );
      expect(exception, isA<EmailAlreadyRegisteredException>());
    });

    test('구버전 code 키 EMAIL_ALREADY_REGISTERED > EmailAlreadyRegisteredException', () {
      final exception = RomAuthApi.toKakaoFirebaseTokenException(
        buildApiException(400, '{"code":"EMAIL_ALREADY_REGISTERED"}'),
      );
      expect(exception, isA<EmailAlreadyRegisteredException>());
    });

    test('SUSPENDED_MEMBER > AccountSuspendedException (사유·기간 전달)', () {
      final exception = RomAuthApi.toKakaoFirebaseTokenException(
        buildApiException(400, '{"errorCode":"SUSPENDED_MEMBER","suspendReason":"spam","suspendedUntil":"2026-12-31"}'),
      );
      expect(exception, isA<AccountSuspendedException>());
      expect((exception as AccountSuspendedException).suspendReason, 'spam');
      expect(exception.suspendedUntil, '2026-12-31');
    });

    test('그 외 응답 > null (호출부가 원본 ApiException 유지)', () {
      expect(RomAuthApi.toKakaoFirebaseTokenException(buildApiException(500, '{"errorCode":"INTERNAL"}')), isNull);
      expect(RomAuthApi.toKakaoFirebaseTokenException(buildApiException(502, '<html>')), isNull);
    });
  });
}
