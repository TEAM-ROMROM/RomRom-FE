import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/models/apis/responses/keyword_alert_response.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/providers/notification_permission_prompt_service_provider.dart';
import 'package:romrom_fe/repositories/keyword_alert_repository.dart';
import 'package:romrom_fe/services/notification_permission_prompt_service.dart';
import 'package:romrom_fe/widgets/keyword_alert/keyword_alert_bell_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/pump_design_screen.dart';

/// 키워드 알림 저장소 대역: 등록·삭제 호출 기록
class _FakeKeywordAlertRepository implements KeywordAlertRepository {
  List<KeywordAlert> serverKeywordAlerts = [];
  int maximumKeywordAlertCount = 10;
  final List<String> registeredKeywords = [];
  final List<String> deletedKeywordAlertIds = [];

  KeywordAlertResponse _buildResponse() => KeywordAlertResponse(
    keywordAlerts: List.of(serverKeywordAlerts),
    maximumKeywordAlertCount: maximumKeywordAlertCount,
  );

  @override
  Future<KeywordAlertResponse> getKeywordAlerts() async => _buildResponse();

  @override
  Future<KeywordAlertResponse> registerKeywordAlert(String keyword) async {
    registeredKeywords.add(keyword);
    serverKeywordAlerts = [KeywordAlert(keywordAlertId: 'new', keyword: keyword), ...serverKeywordAlerts];
    return _buildResponse();
  }

  @override
  Future<KeywordAlertResponse> deleteKeywordAlert(String keywordAlertId) async {
    deletedKeywordAlertIds.add(keywordAlertId);
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

  Future<void> pumpBellButton(WidgetTester tester, String keyword) async {
    useDesignScreenView(tester);
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
        child: buildDesignScreenApp(
          home: Scaffold(
            body: Center(child: KeywordAlertBellButton(keyword: keyword)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 스낵바 타이머 소진
  Future<void> flushSnackBars(WidgetTester tester) => tester.pumpAndSettle(const Duration(seconds: 3));

  testWidgets('미등록 검색어 > 빈 종 > 탭 > 등록 + 채운 종', (tester) async {
    await pumpBellButton(tester, '닌텐도 스위치');
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(repository.registeredKeywords, ['닌텐도 스위치']);
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
    await flushSnackBars(tester);
  });

  testWidgets('등록된 검색어(대소문자·공백 차이) > 채운 종 > 탭 > 해제', (tester) async {
    repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: 'Nintendo Switch')];
    await pumpBellButton(tester, 'nintendo  switch');
    expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(repository.deletedKeywordAlertIds, ['a']);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
    await flushSnackBars(tester);
  });

  testWidgets('1자 검색어 > 서버 요청 없이 길이 안내', (tester) async {
    await pumpBellButton(tester, '책');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('키워드는 2자 이상 입력해 주세요'), findsOneWidget);
    expect(repository.registeredKeywords, isEmpty);
    await flushSnackBars(tester);
  });

  testWidgets('최대 개수 도달 > 서버 요청 없이 개수 안내', (tester) async {
    repository.maximumKeywordAlertCount = 1;
    repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
    await pumpBellButton(tester, '아이패드');
    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('키워드는 최대 1개까지 등록할 수 있어요'), findsOneWidget);
    expect(repository.registeredKeywords, isEmpty);
    await flushSnackBars(tester);
  });
}
