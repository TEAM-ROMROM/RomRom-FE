import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/models/apis/responses/keyword_alert_response.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/providers/notification_permission_prompt_service_provider.dart';
import 'package:romrom_fe/repositories/keyword_alert_repository.dart';
import 'package:romrom_fe/screens/keyword_alert_settings_screen.dart';
import 'package:romrom_fe/services/notification_permission_prompt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_design_screen.dart';

/// 키워드 알림 저장소 대역: 서버 목록 보관, 첫 조회 실패 횟수 지정
class _FakeKeywordAlertRepository implements KeywordAlertRepository {
  List<KeywordAlert> serverKeywordAlerts = [];
  int remainingGetFailureCount = 0;
  final List<String> registeredKeywords = [];

  KeywordAlertResponse _buildResponse() =>
      KeywordAlertResponse(keywordAlerts: List.of(serverKeywordAlerts), maximumKeywordAlertCount: 10);

  @override
  Future<KeywordAlertResponse> getKeywordAlerts() async {
    if (remainingGetFailureCount > 0) {
      remainingGetFailureCount--;
      throw Exception('network');
    }
    return _buildResponse();
  }

  @override
  Future<KeywordAlertResponse> registerKeywordAlert(String keyword) async {
    registeredKeywords.add(keyword);
    serverKeywordAlerts = [KeywordAlert(keywordAlertId: 'new-$keyword', keyword: keyword), ...serverKeywordAlerts];
    return _buildResponse();
  }

  @override
  Future<KeywordAlertResponse> deleteKeywordAlert(String keywordAlertId) async {
    serverKeywordAlerts = serverKeywordAlerts.where((alert) => alert.keywordAlertId != keywordAlertId).toList();
    return _buildResponse();
  }
}

void main() {
  late _FakeKeywordAlertRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _FakeKeywordAlertRepository();
  });

  Future<void> pumpScreen(WidgetTester tester, {Size screenSize = designScreenSize}) async {
    useDesignScreenView(tester, screenSize: screenSize);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keywordAlertRepositoryProvider.overrideWithValue(repository),
          // 이미 허용 상태 > 권한 안내 없음
          notificationPermissionPromptServiceProvider.overrideWithValue(
            NotificationPermissionPromptService(
              isIos: true,
              readAuthorizationStatus: () async => AuthorizationStatus.authorized,
            ),
          ),
        ],
        child: buildDesignScreenApp(home: const KeywordAlertSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 스낵바 타이머 소진
  Future<void> flushSnackBars(WidgetTester tester) => tester.pumpAndSettle(const Duration(seconds: 3));

  testWidgets('목록·개수 표시 > 삭제 > 서버 응답 목록으로 갱신', (tester) async {
    repository.serverKeywordAlerts = [
      const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰'),
      const KeywordAlert(keywordAlertId: 'b', keyword: '맥북'),
    ];
    await pumpScreen(tester);

    expect(find.text(KeywordAlertSettingsScreen.descriptionText), findsOneWidget);
    expect(find.text('2/10'), findsOneWidget);
    expect(find.text('아이폰'), findsOneWidget);

    await tester.tap(find.byTooltip('아이폰 삭제'));
    await tester.pumpAndSettle();

    expect(find.text('아이폰'), findsNothing);
    expect(find.text('1/10'), findsOneWidget);
    await flushSnackBars(tester);
  });

  testWidgets('빈 목록 안내 > 1자 입력은 추가 불가 > 2자 이상 추가 > 입력 비움 + 목록 반영', (tester) async {
    await pumpScreen(tester);
    expect(find.text('등록한 키워드가 없어요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '맥');
    await tester.pump();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    expect(repository.registeredKeywords, isEmpty);

    await tester.enterText(find.byType(TextField), '  맥북   프로 ');
    await tester.pump();
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();

    expect(repository.registeredKeywords, ['맥북 프로']);
    expect(find.text('맥북 프로'), findsWidgets);
    expect(find.text('1/10'), findsOneWidget);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, isEmpty);
    await flushSnackBars(tester);
  });

  testWidgets('이미 등록한 키워드 입력 > 안내 문구, 추가 안 됨', (tester) async {
    repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: 'iPhone')];
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'IPHONE');
    await tester.pump();

    expect(find.text('이미 등록한 키워드예요'), findsOneWidget);
    await tester.tap(find.text('추가'));
    await tester.pumpAndSettle();
    expect(repository.registeredKeywords, isEmpty);
  });

  testWidgets('첫 로드 실패 > 다시 시도 > 목록', (tester) async {
    // 첫 조회만 실패 (진입 시 재조회는 첫 로드 중이라 무시)
    repository.remainingGetFailureCount = 1;
    repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
    await pumpScreen(tester);

    expect(find.text('키워드 알림을 불러오지 못했어요'), findsOneWidget);
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();

    expect(find.text('아이폰'), findsOneWidget);
  });

  testWidgets('iPad 크기에서도 넘침 없이 표시', (tester) async {
    repository.serverKeywordAlerts = List.generate(
      10,
      (index) => KeywordAlert(keywordAlertId: 'id-$index', keyword: '키워드$index'),
    );
    await pumpScreen(tester, screenSize: const Size(1024, 1366));

    expect(tester.takeException(), isNull);
    expect(find.text('10/10'), findsOneWidget);
    expect(find.text('키워드는 최대 10개까지 등록할 수 있어요'), findsOneWidget);
  });
}
