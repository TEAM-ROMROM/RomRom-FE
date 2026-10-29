import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';

/// 거래 요청 이력 생성 (테스트용 최소 필드)
TradeRequestHistory buildTradeRequestHistory(String tradeRequestHistoryId, {bool? isNew}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: tradeRequestHistoryId,
    takeItem: Item(itemId: 'take-$tradeRequestHistoryId'),
    giveItem: Item(itemId: 'give-$tradeRequestHistoryId'),
    itemTradeOptions: const [],
    tradeStatus: 'PENDING',
    isNew: isNew,
  );
}

/// 거래 저장소 대역: 호출 기록, 응답 지연(Completer) 조절
class FakeTradeRepository implements TradeRepository {
  int requestTradeCallCount = 0;
  bool shouldFailRequestTrade = false;
  String? lastTakeItemId;
  String? lastGiveItemId;
  List<String>? lastItemTradeOptions;

  // 받은 요청: 카드 ID별 응답, 지연 응답, 호출 기록 (카드 ID·정렬)
  Map<String, List<TradeRequestHistory>> receivedByTakeItemId = {};
  Map<String, Completer<List<TradeRequestHistory>>> pendingReceivedByTakeItemId = {};
  final List<String> receivedRequestedTakeItemIds = [];
  final List<RequestSortType> receivedRequestedSortTypes = [];

  // 보낸 요청: 내 물품 ID별 응답, 지연 응답, 호출 기록 (물품 ID·정렬)
  Map<String, List<TradeRequestHistory>> sentByGiveItemId = {};
  Completer<void>? pendingSent;
  final List<String> sentRequestedGiveItemIds = [];
  final List<RequestSortType> sentRequestedSortTypes = [];

  // 상세 조회: 응답, 호출 기록
  TradeRequestHistory? detailResponse;
  final List<String> detailRequestedIds = [];

  int cancelCallCount = 0;

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
  Future<List<TradeRequestHistory>> getReceived({
    required String takeItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    receivedRequestedTakeItemIds.add(takeItemId);
    receivedRequestedSortTypes.add(sortType);
    final pendingReceived = pendingReceivedByTakeItemId[takeItemId];
    if (pendingReceived != null) return pendingReceived.future;
    return receivedByTakeItemId[takeItemId] ?? const [];
  }

  @override
  Future<List<TradeRequestHistory>> getSent({
    required String giveItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    sentRequestedGiveItemIds.add(giveItemId);
    sentRequestedSortTypes.add(sortType);
    if (pendingSent != null) await pendingSent!.future;
    return sentByGiveItemId[giveItemId] ?? const [];
  }

  @override
  Future<TradeRequestHistory?> getDetail(String tradeRequestHistoryId) async {
    detailRequestedIds.add(tradeRequestHistoryId);
    return detailResponse;
  }

  @override
  Future<void> cancel(String tradeRequestHistoryId) async => cancelCallCount++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 대기 중인 microtask 소진 (await 없이 시작된 재조회 반영)
Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTradeRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeTradeRepository();
    container = ProviderContainer(
      overrides: [
        tradeRepositoryProvider.overrideWithValue(fakeRepository),
        itemAddressResolverProvider.overrideWithValue(ItemAddressResolver(lookupAddress: (_) async => null)),
      ],
    );
  });

  tearDown(() => container.dispose());

  TradeRequestsNotifier readNotifier() => container.read(tradeRequestsProvider.notifier);

  group('tradeRequestsProvider.sendRequest', () {
    test('저장소에 요청 1회 전달 (상대 물품·내 물품·거래 방식)', () async {
      await container.read(tradeRequestsProvider.future);

      await readNotifier().sendRequest(takeItemId: 'take', giveItemId: 'give', itemTradeOptions: const ['DIRECT_ONLY']);

      expect(fakeRepository.requestTradeCallCount, 1);
      expect(fakeRepository.lastTakeItemId, 'take');
      expect(fakeRepository.lastGiveItemId, 'give');
      expect(fakeRepository.lastItemTradeOptions, ['DIRECT_ONLY']);
    });

    test('실패 시 예외 전달 + 상태 변경 없음', () async {
      final initialState = await container.read(tradeRequestsProvider.future);
      fakeRepository.shouldFailRequestTrade = true;

      await expectLater(
        readNotifier().sendRequest(takeItemId: 'take', giveItemId: 'give', itemTradeOptions: const []),
        throwsException,
      );
      expect(container.read(tradeRequestsProvider).valueOrNull, initialState);
    });

    test('전송 성공 > 보낸 요청 목록 서버 재조회 (모든 내 물품 카드)', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');
      fakeRepository.sentByGiveItemId = {
        'a': [buildTradeRequestHistory('sent-new')],
      };

      await readNotifier().sendRequest(takeItemId: 'other', giveItemId: 'a', itemTradeOptions: const []);
      await flushMicrotasks();

      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'b']);
      final sentIds = container.read(tradeRequestsProvider).valueOrNull?.sent.map((r) => r.tradeRequestHistoryId);
      expect(sentIds, ['sent-new']);
    });
  });

  group('tradeRequestsProvider.loadForItems', () {
    test('첫 진입 > 받은 요청 1회(현재 카드)·보낸 요청 카드별 1회 조회, 카드 순서대로 합침', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.receivedByTakeItemId = {
        'a': [buildTradeRequestHistory('received-1')],
      };
      fakeRepository.sentByGiveItemId = {
        'a': [buildTradeRequestHistory('sent-a')],
        'b': [buildTradeRequestHistory('sent-b')],
      };

      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      expect(fakeRepository.receivedRequestedTakeItemIds, ['a']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b']);
      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.currentTakeItemId, 'a');
      expect(state.received.map((r) => r.tradeRequestHistoryId), ['received-1']);
      expect(state.sent.map((r) => r.tradeRequestHistoryId), ['sent-a', 'sent-b']);
    });

    test('받은·보낸 요청 병렬 조회 (받은 요청 응답 전에 보낸 요청 조회 시작)', () async {
      await container.read(tradeRequestsProvider.future);
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};

      final loading = readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');
      await flushMicrotasks();

      expect(fakeRepository.receivedRequestedTakeItemIds, ['a']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b']);
      pendingReceived.complete(const []);
      await loading;
    });

    test('같은 카드·물품 목록 로드 진행 중 재호출 > 진행 중 로드에 합류 (중복 조회 없음)', () async {
      await container.read(tradeRequestsProvider.future);
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};

      final firstLoading = readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      final secondLoading = readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      pendingReceived.complete(const []);
      await Future.wait([firstLoading, secondLoading]);

      expect(fakeRepository.receivedRequestedTakeItemIds, ['a']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a']);
    });

    test('카드 없음 > 조회 없이 받은·보낸 요청 비움', () async {
      await container.read(tradeRequestsProvider.future);

      await readNotifier().loadForItems(myItemIds: const [], takeItemId: null);

      expect(fakeRepository.receivedRequestedTakeItemIds, isEmpty);
      expect(fakeRepository.sentRequestedGiveItemIds, isEmpty);
      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.received, isEmpty);
      expect(state.sent, isEmpty);
    });
  });

  group('tradeRequestsProvider 초기화·세션 전환', () {
    test('첫 read 직후(build 완료 대기 없이) 로드 > 내 물품 ID 유지, 이후 전송 시 모든 카드 재조회', () async {
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');
      await readNotifier().sendRequest(takeItemId: 'other', giveItemId: 'a', itemTradeOptions: const []);
      await flushMicrotasks();

      expect(container.read(tradeRequestsProvider).valueOrNull?.myItemIds, ['a', 'b']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'b']);
    });

    test('로드 진행 중 provider 무효화(로그아웃·계정 전환) > 이전 응답은 새 세션 상태에 쓰지 않음', () async {
      await container.read(tradeRequestsProvider.future);
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      final pendingSent = Completer<void>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};
      fakeRepository.pendingSent = pendingSent;
      fakeRepository.sentByGiveItemId = {
        'a': [buildTradeRequestHistory('old-sent')],
      };
      final loading = readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      await flushMicrotasks();

      container.invalidate(tradeRequestsProvider);
      await container.read(tradeRequestsProvider.future);
      pendingReceived.complete([buildTradeRequestHistory('old-received')]);
      pendingSent.complete();
      await loading;

      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.received, isEmpty);
      expect(state.sent, isEmpty);
      expect(state.currentTakeItemId, isNull);
    });
  });

  group('tradeRequestsProvider 카드 전환·정렬', () {
    test('카드 전환 중 이전 카드 응답이 늦게 와도 현재 카드 목록 유지', () async {
      await container.read(tradeRequestsProvider.future);
      final pendingReceivedForA = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceivedForA};
      fakeRepository.receivedByTakeItemId = {
        'b': [buildTradeRequestHistory('received-b')],
      };

      final loadingA = readNotifier().selectItem('a');
      await readNotifier().selectItem('b');
      pendingReceivedForA.complete([buildTradeRequestHistory('received-a')]);
      await loadingA;

      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.currentTakeItemId, 'b');
      expect(state.received.map((r) => r.tradeRequestHistoryId), ['received-b']);
    });

    test('받은 요청 정렬 변경 > 현재 카드를 새 정렬로 재조회, 같은 정렬 재선택은 무시', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');

      await readNotifier().changeReceivedSort(RequestSortType.priceHigh);
      await readNotifier().changeReceivedSort(RequestSortType.priceHigh);

      expect(fakeRepository.receivedRequestedTakeItemIds, ['a', 'a']);
      expect(fakeRepository.receivedRequestedSortTypes.last, RequestSortType.priceHigh);
      expect(container.read(tradeRequestsProvider).valueOrNull?.receivedSortType, RequestSortType.priceHigh);
    });

    test('보낸 요청 정렬 변경 > 모든 카드를 새 정렬로 재조회', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      await readNotifier().changeSentSort(RequestSortType.priceLow);

      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'b']);
      expect(fakeRepository.sentRequestedSortTypes.sublist(2), [RequestSortType.priceLow, RequestSortType.priceLow]);
      expect(container.read(tradeRequestsProvider).valueOrNull?.sentSortType, RequestSortType.priceLow);
    });
  });

  group('tradeRequestsProvider.markReceivedAsRead', () {
    test('상세 조회 1회 > 새 상태 객체로 해당 요청 isNew만 갱신 (기존 객체 불변)', () async {
      await container.read(tradeRequestsProvider.future);
      final unreadRequest = buildTradeRequestHistory('received-1', isNew: true);
      final otherRequest = buildTradeRequestHistory('received-2', isNew: true);
      fakeRepository.receivedByTakeItemId = {
        'a': [unreadRequest, otherRequest],
      };
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      final previousState = container.read(tradeRequestsProvider).valueOrNull!;
      fakeRepository.detailResponse = buildTradeRequestHistory('received-1', isNew: false);

      await readNotifier().markReceivedAsRead('received-1');

      final nextState = container.read(tradeRequestsProvider).valueOrNull!;
      expect(fakeRepository.detailRequestedIds, ['received-1']);
      expect(identical(nextState, previousState), isFalse);
      expect(nextState.received.first.isNew, isFalse);
      expect(identical(nextState.received.last, otherRequest), isTrue);
      expect(unreadRequest.isNew, isTrue);
      expect(previousState.received.first.isNew, isTrue);
    });
  });

  group('tradeRequestsProvider.cancel', () {
    test('취소 > 받은·보낸 요청 서버 재조회', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.sentByGiveItemId = {
        'a': [buildTradeRequestHistory('sent-a')],
      };
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      fakeRepository.sentByGiveItemId = {};

      await readNotifier().cancel(tradeRequestHistoryId: 'sent-a');

      expect(fakeRepository.cancelCallCount, 1);
      expect(fakeRepository.receivedRequestedTakeItemIds, ['a', 'a']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'a']);
      expect(container.read(tradeRequestsProvider).valueOrNull?.sent, isEmpty);
    });
  });
}
