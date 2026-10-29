import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/notification_permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationPermissionService 시작 권한 대기', () {
    final originalWaitForStartupPermissionRequest = NotificationPermissionService.waitForStartupPermissionRequest;
    late Completer<void> startupPermissionCompleter;

    setUp(() {
      startupPermissionCompleter = Completer<void>();
      NotificationPermissionService.waitForStartupPermissionRequest = () => startupPermissionCompleter.future;
    });

    tearDown(() {
      NotificationPermissionService.waitForStartupPermissionRequest = originalWaitForStartupPermissionRequest;
    });

    test('isPermissionGranted > 시작 권한 응답 전에는 완료되지 않음, 응답 후 상태 조회', () async {
      var isCompleted = false;
      final grantedFuture = NotificationPermissionService().isPermissionGranted().whenComplete(
        () => isCompleted = true,
      );

      await pumpEventQueue();
      expect(isCompleted, isFalse);

      startupPermissionCompleter.complete();
      // 테스트 환경엔 Firebase 앱 없음 > 조회 실패 시 미허용(false)
      expect(await grantedFuture, isFalse);
      expect(isCompleted, isTrue);
    });

    test('requestOrOpenSettings > 시작 권한 응답 전에는 재요청하지 않음', () async {
      var isSettled = false;
      final requestFuture = NotificationPermissionService().requestOrOpenSettings().then<void>(
        (_) => isSettled = true,
        onError: (Object _) => isSettled = true, // 테스트 환경 Firebase 없음 > 재요청 단계에서 실패
      );

      await pumpEventQueue();
      expect(isSettled, isFalse);

      startupPermissionCompleter.complete();
      await requestFuture;
      expect(isSettled, isTrue);
    });

    test('시작 권한 응답 완료 후 > 대기 없이 바로 조회', () async {
      startupPermissionCompleter.complete();

      expect(await NotificationPermissionService().isPermissionGranted(), isFalse);
    });
  });
}
