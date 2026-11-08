import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_setting_type.dart';
import 'package:romrom_fe/providers/notification_permission_prompt_service_provider.dart';
import 'package:romrom_fe/providers/notification_setting_provider.dart';
import 'package:romrom_fe/repositories/notification_setting_repository.dart';
import 'package:romrom_fe/services/notification_permission_prompt_service.dart';
import 'package:romrom_fe/widgets/common/notification_permission_prompt_modal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_design_screen.dart';

/// 알림 설정 저장 대역: 일괄 변경 값 기록
class _RecordingNotificationSettingRepository implements NotificationSettingRepository {
  final List<Map<NotificationSettingType, bool>> updatedValues = [];

  @override
  Future<void> updateAll(Map<NotificationSettingType, bool> values) async => updatedValues.add(values);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late int systemRequestCount;
  late int registerTokenCount;
  late AuthorizationStatus statusAfterRequest;
  late _RecordingNotificationSettingRepository settingRepository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    systemRequestCount = 0;
    registerTokenCount = 0;
    statusAfterRequest = AuthorizationStatus.authorized;
    settingRepository = _RecordingNotificationSettingRepository();
  });

  /// 버튼 탭 > 1회 안내 실행 화면 (안내 호출 교체 가능)
  Future<void> pumpPromptHarness(
    WidgetTester tester, {
    Future<void> Function(BuildContext context, WidgetRef ref) showPrompt = showNotificationPermissionPromptOnce,
  }) async {
    var status = AuthorizationStatus.notDetermined;
    useDesignScreenView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationSettingRepositoryProvider.overrideWithValue(settingRepository),
          notificationPermissionPromptServiceProvider.overrideWithValue(
            NotificationPermissionPromptService(
              isIos: true,
              readAuthorizationStatus: () async => status,
              requestSystemPermission: () async {
                systemRequestCount++;
                status = statusAfterRequest;
              },
              registerFcmToken: () async => registerTokenCount++,
            ),
          ),
        ],
        child: buildDesignScreenApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Center(
                child: GestureDetector(onTap: () => showPrompt(context, ref), child: const Text('교환 요청 성공')),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('이유 안내 모달이 시스템 권한 창보다 먼저, 나중에 > 요청 없음 + 다음 성공 때 재안내 없음', (tester) async {
    await pumpPromptHarness(tester);

    await tester.tap(find.text('교환 요청 성공'));
    await tester.pumpAndSettle();
    expect(find.textContaining('교환 요청과 채팅 답장을'), findsOneWidget);
    expect(systemRequestCount, 0);

    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(systemRequestCount, 0);

    await tester.tap(find.text('교환 요청 성공'));
    await tester.pumpAndSettle();
    expect(find.text('알림 켜기'), findsNothing);
  });

  testWidgets('알림 켜기 > 시스템 권한 요청 > 허용 > FCM 토큰 등록 + 교환·채팅 알림 켜기', (tester) async {
    await pumpPromptHarness(tester);

    await tester.tap(find.text('교환 요청 성공'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('알림 켜기'));
    await tester.pumpAndSettle();

    expect(systemRequestCount, 1);
    expect(registerTokenCount, 1);
    expect(settingRepository.updatedValues, [
      {NotificationSettingType.transaction: true, NotificationSettingType.chat: true},
    ]);
  });

  testWidgets('알림 켜기 > 시스템 거부 > 토큰·설정 변경 없음, 재안내 없음', (tester) async {
    statusAfterRequest = AuthorizationStatus.denied;
    await pumpPromptHarness(tester);

    await tester.tap(find.text('교환 요청 성공'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('알림 켜기'));
    await tester.pumpAndSettle();

    expect(registerTokenCount, 0);
    expect(settingRepository.updatedValues, isEmpty);

    await tester.tap(find.text('교환 요청 성공'));
    await tester.pumpAndSettle();
    expect(find.text('알림 켜기'), findsNothing);
  });

  testWidgets('키워드 등록 안내: 전달 문구 표시 > 허용 > 토큰 등록, 켤 설정 없음 > 설정 변경 없음 (#1020)', (tester) async {
    await pumpPromptHarness(
      tester,
      showPrompt: (context, ref) => showNotificationPermissionPromptOnce(
        context,
        ref,
        message: '키워드 새 물품 소식',
        settingTypesToEnableOnGrant: const {},
      ),
    );

    await tester.tap(find.text('교환 요청 성공'));
    await tester.pumpAndSettle();
    expect(find.text('키워드 새 물품 소식'), findsOneWidget);
    await tester.tap(find.text('알림 켜기'));
    await tester.pumpAndSettle();

    expect(systemRequestCount, 1);
    expect(registerTokenCount, 1);
    expect(settingRepository.updatedValues, isEmpty);
  });
}
