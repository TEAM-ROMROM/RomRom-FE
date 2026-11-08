import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/models/apis/responses/keyword_alert_response.dart';
import 'package:romrom_fe/providers/keyword_alerts_provider.dart';
import 'package:romrom_fe/repositories/keyword_alert_repository.dart';
import 'package:romrom_fe/states/keyword_alerts_state.dart';
import 'package:romrom_fe/utils/keyword_alert_rules.dart';

/// 키워드 알림 저장소 대역: 서버 목록 보관, 변경 응답 = 변경 후 목록 (최신 등록순)
class _FakeKeywordAlertRepository implements KeywordAlertRepository {
  List<KeywordAlert> serverKeywordAlerts = [];
  int? serverMaximumKeywordAlertCount = 10;
  int getCallCount = 0;
  int registerCallCount = 0;
  int deleteCallCount = 0;
  Object? getError;
  Object? registerError;
  Object? deleteError;
  int _nextId = 1;

  KeywordAlertResponse _buildResponse() => KeywordAlertResponse(
    keywordAlerts: List.of(serverKeywordAlerts),
    maximumKeywordAlertCount: serverMaximumKeywordAlertCount,
  );

  @override
  Future<KeywordAlertResponse> getKeywordAlerts() async {
    getCallCount++;
    if (getError != null) throw getError!;
    return _buildResponse();
  }

  @override
  Future<KeywordAlertResponse> registerKeywordAlert(String keyword) async {
    registerCallCount++;
    if (registerError != null) throw registerError!;
    serverKeywordAlerts = [KeywordAlert(keywordAlertId: 'id-${_nextId++}', keyword: keyword), ...serverKeywordAlerts];
    return _buildResponse();
  }

  @override
  Future<KeywordAlertResponse> deleteKeywordAlert(String keywordAlertId) async {
    deleteCallCount++;
    if (deleteError != null) throw deleteError!;
    serverKeywordAlerts = serverKeywordAlerts.where((alert) => alert.keywordAlertId != keywordAlertId).toList();
    return _buildResponse();
  }
}

void main() {
  late _FakeKeywordAlertRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeKeywordAlertRepository();
    container = ProviderContainer(overrides: [keywordAlertRepositoryProvider.overrideWithValue(repository)]);
  });
  tearDown(() => container.dispose());

  KeywordAlertsNotifier notifier() => container.read(keywordAlertsProvider.notifier);
  KeywordAlertsState? currentState() => container.read(keywordAlertsProvider).valueOrNull;

  group('keywordAlertsProvider', () {
    test('첫 로드: 서버 목록·최대 개수 반영', () async {
      repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
      repository.serverMaximumKeywordAlertCount = 7;

      final state = await container.read(keywordAlertsProvider.future);

      expect(state.registeredKeywords, ['아이폰']);
      expect(state.maximumKeywordAlertCount, 7);
      expect(state.isKeywordRegistered('  아이폰 '), isTrue);
    });

    test('최대 개수 없는 응답 > 기본 10개', () async {
      repository.serverMaximumKeywordAlertCount = null;

      final state = await container.read(keywordAlertsProvider.future);

      expect(state.maximumKeywordAlertCount, defaultMaximumKeywordAlertCount);
    });

    test('등록 > 서버 응답 목록으로 갱신 (최신 등록순)', () async {
      repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
      await container.read(keywordAlertsProvider.future);

      await notifier().register('Nintendo Switch');

      expect(repository.registerCallCount, 1);
      expect(currentState()!.registeredKeywords, ['Nintendo Switch', '아이폰']);
      expect(currentState()!.findByKeyword('nintendo   switch')?.keywordAlertId, 'id-1');
    });

    test('삭제 > 서버 응답 목록으로 갱신', () async {
      repository.serverKeywordAlerts = [
        const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰'),
        const KeywordAlert(keywordAlertId: 'b', keyword: '맥북'),
      ];
      await container.read(keywordAlertsProvider.future);

      await notifier().delete('a');

      expect(repository.deleteCallCount, 1);
      expect(currentState()!.registeredKeywords, ['맥북']);
    });

    test('등록 거부(서버 오류) > 예외 전달, 이전 목록 유지', () async {
      repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
      final before = await container.read(keywordAlertsProvider.future);
      repository.registerError = ApiException(
        statusCode: 400,
        responseBody: '{"errorCode":"KEYWORD_ALERT_LIMIT_EXCEEDED","errorMessage":"키워드는 최대 10개까지 등록할 수 있어요"}',
      );

      await expectLater(notifier().register('맥북'), throwsA(isA<ApiException>()));

      expect(currentState(), before);
    });

    test('삭제 실패 > 예외 전달, 이전 목록 유지', () async {
      repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
      final before = await container.read(keywordAlertsProvider.future);
      repository.deleteError = Exception('network');

      await expectLater(notifier().delete('a'), throwsA(isA<Exception>()));

      expect(currentState(), before);
    });

    test('다시 조회 실패 > 이전 데이터 유지 (화면 blank 방지)', () async {
      repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
      await container.read(keywordAlertsProvider.future);
      repository.getError = Exception('network');

      await notifier().reload();

      final asyncState = container.read(keywordAlertsProvider);
      expect(asyncState.hasError, isTrue);
      expect(asyncState.valueOrNull?.registeredKeywords, ['아이폰']);
    });

    test('첫 로드 실패 > 다시 조회 성공 > 데이터', () async {
      repository.getError = Exception('network');
      await expectLater(container.read(keywordAlertsProvider.future), throwsA(isA<Exception>()));

      repository.getError = null;
      repository.serverKeywordAlerts = [const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰')];
      await notifier().reload();

      expect(container.read(keywordAlertsProvider).hasError, isFalse);
      expect(currentState()!.registeredKeywords, ['아이폰']);
    });

    test('개수 도달 판정', () async {
      repository.serverMaximumKeywordAlertCount = 2;
      repository.serverKeywordAlerts = [
        const KeywordAlert(keywordAlertId: 'a', keyword: '아이폰'),
        const KeywordAlert(keywordAlertId: 'b', keyword: '맥북'),
      ];

      final state = await container.read(keywordAlertsProvider.future);

      expect(state.registeredCount, 2);
      expect(state.hasReachedLimit, isTrue);
    });
  });
}
