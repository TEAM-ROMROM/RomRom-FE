import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';

/// 교환 요청 전송만 흉내 내는 저장소 대역 (호출 횟수·마지막 인자 기록)
class FakeTradeRepository implements TradeRepository {
  int requestTradeCallCount = 0;
  bool shouldFailRequestTrade = false;
  String? lastTakeItemId;
  String? lastGiveItemId;
  List<String>? lastItemTradeOptions;

  @override
  Future<void> requestTrade({
    required String? takeItemId,
    required String? giveItemId,
    required List<String> itemTradeOptions,
  }) async {
    requestTradeCallCount++;
    if (shouldFailRequestTrade) throw Exception('request failed');
    lastTakeItemId = takeItemId;
    lastGiveItemId = giveItemId;
    lastItemTradeOptions = itemTradeOptions;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('tradeRequestsProvider.sendRequest', () {
    late FakeTradeRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeTradeRepository();
      container = ProviderContainer(overrides: [tradeRepositoryProvider.overrideWithValue(fakeRepository)]);
    });

    tearDown(() => container.dispose());

    test('저장소에 요청 1회 전달 (상대 물품·내 물품·거래 방식)', () async {
      await container.read(tradeRequestsProvider.future);

      await container
          .read(tradeRequestsProvider.notifier)
          .sendRequest(takeItemId: 'take', giveItemId: 'give', itemTradeOptions: const ['DIRECT_ONLY']);

      expect(fakeRepository.requestTradeCallCount, 1);
      expect(fakeRepository.lastTakeItemId, 'take');
      expect(fakeRepository.lastGiveItemId, 'give');
      expect(fakeRepository.lastItemTradeOptions, ['DIRECT_ONLY']);
    });

    test('실패 시 예외 전달 + 상태 변경 없음', () async {
      final initialState = await container.read(tradeRequestsProvider.future);
      fakeRepository.shouldFailRequestTrade = true;

      await expectLater(
        container
            .read(tradeRequestsProvider.notifier)
            .sendRequest(takeItemId: 'take', giveItemId: 'give', itemTradeOptions: const []),
        throwsException,
      );
      expect(container.read(tradeRequestsProvider).valueOrNull, initialState);
    });
  });
}
