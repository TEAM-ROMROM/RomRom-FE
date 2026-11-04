import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/services/notification_permission_prompt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 플랫폼 대역: 권한 상태 지정, 요청 후 상태 지정, 요청·토큰 등록 횟수 기록
class FakeNotificationPlatform {
  AuthorizationStatus status = AuthorizationStatus.notDetermined;
  AuthorizationStatus statusAfterRequest = AuthorizationStatus.authorized;
  bool shouldFailStatusRead = false;
  int requestCount = 0;
  int registerTokenCount = 0;

  NotificationPermissionPromptService buildService({bool isIos = true}) => NotificationPermissionPromptService(
    isIos: isIos,
    readAuthorizationStatus: () async {
      if (shouldFailStatusRead) throw Exception('firebase unavailable');
      return status;
    },
    requestSystemPermission: () async {
      requestCount++;
      status = statusAfterRequest;
    },
    registerFcmToken: () async => registerTokenCount++,
  );
}

void main() {
  late FakeNotificationPlatform platform;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    platform = FakeNotificationPlatform();
  });

  group('tryStartPrompt (설치당 1회)', () {
    test('미안내 + 미결정 > 안내 시작, 안내 기록 저장 > 다음 성공 때 재안내 없음', () async {
      final service = platform.buildService();

      expect(await service.tryStartPrompt(), isTrue);
      service.finishPrompt();

      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(StorageKeys.notificationPermissionPromptAsked.key), isTrue);
      expect(await service.tryStartPrompt(), isFalse);
    });

    test('이미 허용 > 안내 없음, 기록 안 함', () async {
      platform.status = AuthorizationStatus.authorized;
      final service = platform.buildService();

      expect(await service.tryStartPrompt(), isFalse);
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getBool(StorageKeys.notificationPermissionPromptAsked.key), isNull);
    });

    test('iOS 거부(시스템 창 재노출 불가) > 안내 없음, Android 거부(미결정 포함) > 안내', () async {
      platform.status = AuthorizationStatus.denied;

      expect(await platform.buildService(isIos: true).tryStartPrompt(), isFalse);
      expect(await platform.buildService(isIos: false).tryStartPrompt(), isTrue);
    });

    test('안내 진행 중 재호출 > 즉시 false (모달 중복 방지)', () async {
      final service = platform.buildService();

      expect(await service.tryStartPrompt(), isTrue);
      expect(await service.tryStartPrompt(), isFalse);
    });

    test('권한 상태 조회 실패 > 안내 없음 (예외 없음)', () async {
      platform.shouldFailStatusRead = true;

      expect(await platform.buildService().tryStartPrompt(), isFalse);
    });
  });

  group('requestPermissionAndRegisterToken', () {
    test('허용 > FCM 토큰 재등록', () async {
      final service = platform.buildService();

      expect(await service.requestPermissionAndRegisterToken(), isTrue);
      expect(platform.requestCount, 1);
      expect(platform.registerTokenCount, 1);
    });

    test('거부 > 토큰 등록 없음', () async {
      platform.statusAfterRequest = AuthorizationStatus.denied;
      final service = platform.buildService();

      expect(await service.requestPermissionAndRegisterToken(), isFalse);
      expect(platform.registerTokenCount, 0);
    });
  });
}
