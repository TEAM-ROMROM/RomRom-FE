// 규칙 테스트: 권한은 필요한 순간에만 요청 (앱 시작·스플래시·로그인·온보딩 시점 요청 금지, #986)
// lib/ 소스 텍스트 스캔
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// 시작·가입 흐름 파일 (권한 요청 호출 금지)
const startupFlowPaths = [
  'lib/main.dart',
  'lib/services/app_initializer.dart',
  'lib/services/splash_startup_sequence.dart',
  'lib/screens/splash_screen.dart',
  'lib/screens/login_screen.dart',
  'lib/widgets/login_button.dart',
  'lib/screens/main_screen.dart',
];

// 권한 요청 호출 패턴 (위치·알림·카메라·사진)
final permissionRequestPattern = RegExp(
  r'requestNotificationPermission\(|\.requestPermission\(|Permission\.\w+\.request\(|requestOrOpenSettings\(',
);

void main() {
  test('시작·로그인 흐름 파일은 권한을 요청하지 않음', () {
    final violations = <String>[];
    for (final path in startupFlowPaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      if (permissionRequestPattern.hasMatch(file.readAsStringSync())) violations.add(path);
    }
    for (final entity in Directory('lib/screens/onboarding').listSync(recursive: true)) {
      if (entity is File && permissionRequestPattern.hasMatch(entity.readAsStringSync())) violations.add(entity.path);
    }
    expect(violations, isEmpty, reason: '권한 요청은 기능 사용 순간 안내 뒤에만');
  });

  test('알림 시스템 권한 요청은 1회 안내·사용자 알림 켜기 동작에서만 시작', () {
    final callers = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.readAsStringSync().contains('requestNotificationPermission')) callers.add(entity.path);
    }
    expect(callers.toSet(), {
      'lib/services/firebase_service.dart',
      'lib/services/notification_permission_prompt_service.dart',
      // 사용자가 누른 알림 켜기(설정 이동) > 미결정이면 요청
      'lib/services/notification_permission_service.dart',
    });
  });

  test('FCM 토큰 등록은 권한을 요청하지 않음 (진행 중 요청 대기만)', () {
    final source = File('lib/services/firebase_service.dart').readAsStringSync();
    final handleFcmTokenStart = source.indexOf('Future<void> handleFcmToken()');
    final handleFcmTokenBody = source.substring(handleFcmTokenStart, source.indexOf('\n  }\n', handleFcmTokenStart));
    expect(handleFcmTokenBody, isNot(contains('requestNotificationPermission(')));
    expect(handleFcmTokenBody, contains('waitForPendingPermissionRequest('));
  });

  test('로컬 알림 초기화는 iOS 권한 창을 띄우지 않음', () {
    final source = File('lib/services/local_notification_service.dart').readAsStringSync();
    expect(source, contains('requestAlertPermission: false'));
    expect(source, contains('requestBadgePermission: false'));
    expect(source, contains('requestSoundPermission: false'));
  });
}
