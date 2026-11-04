import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/providers/trade_requests_provider.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';

/// 거래 요청 이력 생성 (테스트용 최소 필드, 보낸 요청은 giveItemId = 요청관리 카드 ID)
TradeRequestHistory buildTradeRequestHistory(String tradeRequestHistoryId, {bool? isNew, String? giveItemId}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: tradeRequestHistoryId,
    takeItem: Item(itemId: 'take-$tradeRequestHistoryId'),
    giveItem: Item(itemId: giveItemId ?? 'give-$tradeRequestHistoryId'),
    itemTradeOptions: const [],
    tradeStatus: 'PENDING',
    isNew: isNew,
  );
}

/// 거래 저장소 대역: 호출 기록, 응답 지연(Completer)·실패 주입, 보낸 요청 동시 호출 수 측정
class FakeTradeRepository implements TradeRepository {
  int requestTradeCallCount = 0;
  bool shouldFailRequestTrade = false;
  String? lastTakeItemId;
  String? lastGiveItemId;
  List<String>? lastItemTradeOptions;
  int? lastExtraChargeAmount;
  String? lastRequestMessage;

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

  // 조회 실패시킬 카드 ID (받은: takeItemId, 보낸: giveItemId)
  Set<String> failingReceivedTakeItemIds = {};
  Set<String> failingSentGiveItemIds = {};

  // 보낸 요청 동시 호출 수 측정 (true면 호출마다 한 번 양보해 겹치게 함)
  bool shouldYieldInSent = false;
  int activeSentCallCount = 0;
  int maximumActiveSentCallCount = 0;

  // 요청 거래 방식 수정: 호출 기록, 실패 여부
  final Map<String, List<String>> updatedTradeOptionsById = {};
  bool shouldFailUpdateTradeOptions = false;

  // 상세 조회: 응답, 호출 기록
  TradeRequestHistory? detailResponse;
  final List<String> detailRequestedIds = [];

  int cancelCallCount = 0;

  @override
  Future<void> requestTrade({
    required String? takeItemId,
    required String? giveItemId,
    required List<String> itemTradeOptions,
    int? extraChargeAmount,
    String? requestMessage,
  }) async {
    requestTradeCallCount++;
    if (shouldFailRequestTrade) throw Exception('request failed');
    lastTakeItemId = takeItemId;
    lastGiveItemId = giveItemId;
    lastItemTradeOptions = itemTradeOptions;
    lastExtraChargeAmount = extraChargeAmount;
    lastRequestMessage = requestMessage;
  }

  @override
  Future<List<TradeRequestHistory>> getReceived({
    required String takeItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    receivedRequestedTakeItemIds.add(takeItemId);
    receivedRequestedSortTypes.add(sortType);
    if (failingReceivedTakeItemIds.contains(takeItemId)) throw Exception('received failed');
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
    activeSentCallCount++;
    if (activeSentCallCount > maximumActiveSentCallCount) maximumActiveSentCallCount = activeSentCallCount;
    try {
      if (shouldYieldInSent) await Future<void>.delayed(Duration.zero);
      if (pendingSent != null) await pendingSent!.future;
      if (failingSentGiveItemIds.contains(giveItemId)) throw Exception('sent failed');
      return sentByGiveItemId[giveItemId] ?? const [];
    } finally {
      activeSentCallCount--;
    }
  }

  @override
  Future<void> updateTradeOptions({
    required String tradeRequestHistoryId,
    required List<String> itemTradeOptions,
  }) async {
    if (shouldFailUpdateTradeOptions) throw Exception('update failed');
    updatedTradeOptionsById[tradeRequestHistoryId] = itemTradeOptions;
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

/// 채팅 저장소 대역: 물품별 채팅방 목록 응답, 호출 기록
class FakeChatRepository implements ChatRepository {
  List<ChatRoomDetailDto> roomsByItem = [];
  final List<String> requestedItemIds = [];

  @override
  Future<PagedChatRoomDetail> getChatRoomsByItemId({required String itemId, int pageSize = 50}) async {
    requestedItemIds.add(itemId);
    return PagedChatRoomDetail(content: roomsByItem);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 보낸 요청 1건: 내 물품(my-item) > 상대(opponent) 물품, 상대 물품 대표 이미지 지정 가능
TradeRequestHistory buildSentRequest({String takeItemImageUrl = 'take-image'}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'sent-1',
    takeItem: Item(
      itemId: 'take-item',
      member: Member(memberId: 'opponent'),
      itemImages: [ItemImage(imageUrl: takeItemImageUrl)],
    ),
    giveItem: Item(itemId: 'my-item'),
    itemTradeOptions: const [],
    tradeStatus: 'CHATTING',
  );
}

/// 채팅방 목록 행 1개 (내가 보낸 요청 방 기본)
ChatRoomDetailDto buildChatRoom(
  String chatRoomId, {
  String targetMemberId = 'opponent',
  ChatRoomType chatRoomType = ChatRoomType.requested,
  String targetItemImageUrl = 'take-image',
}) {
  return ChatRoomDetailDto(
    chatRoomId: chatRoomId,
    targetMember: Member(memberId: targetMemberId),
    chatRoomType: chatRoomType,
    targetItemImageUrl: targetItemImageUrl,
  );
}

/// 대기 중인 microtask 소진 (await 없이 시작된 재조회 반영)
Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeTradeRepository fakeRepository;
  late FakeChatRepository fakeChatRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeTradeRepository();
    fakeChatRepository = FakeChatRepository();
    container = ProviderContainer(
      overrides: [
        tradeRepositoryProvider.overrideWithValue(fakeRepository),
        chatRepositoryProvider.overrideWithValue(fakeChatRepository),
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
      expect(fakeRepository.lastExtraChargeAmount, isNull);
      expect(fakeRepository.lastRequestMessage, isNull);
    });

    test('추가금·한 줄 메시지 그대로 저장소 전달 (#1005)', () async {
      await container.read(tradeRequestsProvider.future);

      await readNotifier().sendRequest(
        takeItemId: 'take',
        giveItemId: 'give',
        itemTradeOptions: const ['EXTRA_CHARGE'],
        extraChargeAmount: 5000,
        requestMessage: '주말 가능해요',
      );

      expect(fakeRepository.lastExtraChargeAmount, 5000);
      expect(fakeRepository.lastRequestMessage, '주말 가능해요');
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

  group('tradeRequestsProvider 조회 실패·재시도', () {
    test('받은 요청 조회 실패 > 빈 목록과 구분되는 실패 상태, 재시도 성공 > 실패 해제', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.failingReceivedTakeItemIds = {'a'};

      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      expect(container.read(tradeRequestsProvider).valueOrNull?.hasReceivedLoadFailed, isTrue);

      fakeRepository.failingReceivedTakeItemIds = {};
      fakeRepository.receivedByTakeItemId = {
        'a': [buildTradeRequestHistory('received-1')],
      };
      await readNotifier().reloadReceivedOfRequestedCard();

      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(fakeRepository.receivedRequestedTakeItemIds, ['a', 'a']);
      expect(state.hasReceivedLoadFailed, isFalse);
      expect(state.received.map((r) => r.tradeRequestHistoryId), ['received-1']);
    });

    test('보낸 요청 카드 1개 실패 > 성공 카드 결과 유지 + 실패 카드 기록, 재시도 > 실패 카드만 재조회·카드 순서 유지', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.failingSentGiveItemIds = {'a'};
      fakeRepository.sentByGiveItemId = {
        'a': [buildTradeRequestHistory('sent-a', giveItemId: 'a')],
        'b': [buildTradeRequestHistory('sent-b', giveItemId: 'b')],
      };

      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');
      var state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.hasSentLoadFailed, isTrue);
      expect(state.sentFailedItemIds, ['a']);
      expect(state.sent.map((r) => r.tradeRequestHistoryId), ['sent-b']);

      fakeRepository.failingSentGiveItemIds = {};
      await readNotifier().retrySentLoad();

      state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a']);
      expect(state.hasSentLoadFailed, isFalse);
      expect(state.sent.map((r) => r.tradeRequestHistoryId), ['sent-a', 'sent-b']);
    });

    test('조회 성공 > 실패 상태 아님', () async {
      await container.read(tradeRequestsProvider.future);

      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');

      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.hasReceivedLoadFailed, isFalse);
      expect(state.hasSentLoadFailed, isFalse);
    });
  });

  group('tradeRequestsProvider 보낸 요청 카드 수 제한 없음', () {
    test('카드 12개 > 12개 모두 조회, 카드 순서대로 합침, 동시 호출은 5개 이하', () async {
      await container.read(tradeRequestsProvider.future);
      final myItemIds = [for (var index = 0; index < 12; index++) 'item-$index'];
      fakeRepository.shouldYieldInSent = true;
      fakeRepository.sentByGiveItemId = {
        for (final itemId in myItemIds) itemId: [buildTradeRequestHistory('sent-$itemId')],
      };

      await readNotifier().loadForItems(myItemIds: myItemIds, takeItemId: 'item-0');

      expect(fakeRepository.sentRequestedGiveItemIds, myItemIds);
      expect(fakeRepository.maximumActiveSentCallCount, lessThanOrEqualTo(5));
      // 묶음 안에서는 병렬 (2개 이상 동시 진행)
      expect(fakeRepository.maximumActiveSentCallCount, greaterThanOrEqualTo(2));
      final sentIds = container.read(tradeRequestsProvider).valueOrNull?.sent.map((r) => r.tradeRequestHistoryId);
      expect(sentIds, [for (final itemId in myItemIds) 'sent-$itemId']);
    });
  });

  group('tradeRequestsProvider 보낸 요청 묶음 조회 중단', () {
    test('첫 묶음 조회 중 더 새 조회 시작 > 이전 조회의 남은 묶음 호출 생략', () async {
      await container.read(tradeRequestsProvider.future);
      final myItemIds = [for (var index = 0; index < 12; index++) 'item-$index'];
      final pendingSent = Completer<void>();
      fakeRepository.pendingSent = pendingSent;

      final firstLoading = readNotifier().loadForItems(myItemIds: myItemIds, takeItemId: 'item-0');
      await flushMicrotasks();
      expect(fakeRepository.sentRequestedGiveItemIds, myItemIds.take(5));

      final secondLoading = readNotifier().changeSentSort(RequestSortType.priceLow);
      await flushMicrotasks();
      pendingSent.complete();
      await Future.wait([firstLoading, secondLoading]);

      // 이전 조회 첫 묶음 5 + 새 조회 전체 12 (이전 조회 남은 7 생략)
      expect(fakeRepository.sentRequestedGiveItemIds.length, 17);
      expect(fakeRepository.sentRequestedGiveItemIds.sublist(5), myItemIds);
    });
  });

  group('tradeRequestsProvider.updateTradeOptions', () {
    test('저장소에 요청 ID·거래 방식 1회 전달 > 보낸 요청 서버 재조회', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');

      await readNotifier().updateTradeOptions(
        tradeRequestHistoryId: 'sent-a',
        itemTradeOptions: const ['DELIVERY_ONLY'],
      );

      expect(fakeRepository.updatedTradeOptionsById, {
        'sent-a': ['DELIVERY_ONLY'],
      });
      await flushMicrotasks();
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'a']);
    });

    test('저장 성공 즉시 반환 (보낸 요청 재조회 완료를 기다리지 않음)', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      final pendingSent = Completer<void>();
      fakeRepository.pendingSent = pendingSent;

      var isUpdateReturned = false;
      unawaited(
        readNotifier()
            .updateTradeOptions(tradeRequestHistoryId: 'sent-a', itemTradeOptions: const ['DELIVERY_ONLY'])
            .then((_) => isUpdateReturned = true),
      );
      await flushMicrotasks();

      expect(isUpdateReturned, isTrue);
      pendingSent.complete();
      await flushMicrotasks();
    });

    test('실패 시 예외 전달 + 재조회 없음', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      fakeRepository.shouldFailUpdateTradeOptions = true;

      await expectLater(
        readNotifier().updateTradeOptions(tradeRequestHistoryId: 'sent-a', itemTradeOptions: const ['DIRECT_ONLY']),
        throwsException,
      );
      expect(fakeRepository.sentRequestedGiveItemIds, ['a']);
    });
  });

  group('tradeRequestsProvider.findChatRoomIdOfSentRequest', () {
    test('내 물품 채팅방 중 내가 보낸 방 + 상대 회원 일치 1개 > 그 방 ID', () async {
      fakeChatRepository.roomsByItem = [
        buildChatRoom('received-room', chatRoomType: ChatRoomType.received),
        buildChatRoom('other-member-room', targetMemberId: 'someone-else'),
        buildChatRoom('target-room'),
      ];

      final chatRoomId = await readNotifier().findChatRoomIdOfSentRequest(buildSentRequest());

      expect(fakeChatRepository.requestedItemIds, ['my-item']);
      expect(chatRoomId, 'target-room');
    });

    test('같은 상대에게 보낸 방이 여러 개 > 상대 물품 대표 이미지로 구분', () async {
      fakeChatRepository.roomsByItem = [
        buildChatRoom('other-item-room', targetItemImageUrl: 'other-image'),
        buildChatRoom('target-room', targetItemImageUrl: 'take-image'),
      ];

      expect(await readNotifier().findChatRoomIdOfSentRequest(buildSentRequest()), 'target-room');
    });

    test('일치 방 없음·구분 불가 > null', () async {
      fakeChatRepository.roomsByItem = [buildChatRoom('received-room', chatRoomType: ChatRoomType.received)];
      expect(await readNotifier().findChatRoomIdOfSentRequest(buildSentRequest()), isNull);

      fakeChatRepository.roomsByItem = [buildChatRoom('room-1'), buildChatRoom('room-2')];
      expect(await readNotifier().findChatRoomIdOfSentRequest(buildSentRequest()), isNull);
    });

    test('같은 상대 보낸 방 1개 + 상대 물품 이미지 불일치 > null (다른 요청 방 열기 방지)', () async {
      fakeChatRepository.roomsByItem = [buildChatRoom('other-item-room', targetItemImageUrl: 'other-image')];

      expect(await readNotifier().findChatRoomIdOfSentRequest(buildSentRequest()), isNull);
    });
  });

  group('tradeRequestsProvider.reloadReceivedOfRequestedCard', () {
    test('카드 선택 전이면 조회하지 않고 상태를 유지한다', () async {
      final initialState = await container.read(tradeRequestsProvider.future);

      await readNotifier().reloadReceivedOfRequestedCard();

      expect(fakeRepository.receivedRequestedTakeItemIds, isEmpty);
      expect(container.read(tradeRequestsProvider).valueOrNull, initialState);
    });

    test('마지막으로 선택한 카드로 받은 요청을 다시 조회한다', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.receivedByTakeItemId = {
        'item-1': [buildTradeRequestHistory('r1')],
      };
      await readNotifier().selectItem('item-1');
      fakeRepository.receivedByTakeItemId = {
        'item-1': [buildTradeRequestHistory('r1'), buildTradeRequestHistory('r2')],
      };

      await readNotifier().reloadReceivedOfRequestedCard();

      expect(fakeRepository.receivedRequestedTakeItemIds, ['item-1', 'item-1']);
      expect(container.read(tradeRequestsProvider).valueOrNull?.received.length, 2);
    });
  });
  group('tradeRequestsProvider 보낸 요청 재조회 조건', () {
    test('같은 카드 목록으로 다시 로드 > 받은 요청만 재조회, 보낸 요청 재조회 없음', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      expect(fakeRepository.receivedRequestedTakeItemIds, ['a', 'a']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b']);
    });

    test('카드 목록 변경 > 보낸 요청 모든 카드 재조회', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      await readNotifier().loadForItems(myItemIds: const ['a', 'c'], takeItemId: 'a');

      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'c']);
    });

    test('강제 재조회 > 같은 카드 목록이어도 보낸 요청 재조회', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a', isSentReloadForced: true);

      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'b']);
    });

    test('받은 요청만 하는 로드 진행 중 강제 재조회 > 받은 요청 중복 없이 보낸 요청만 추가', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};

      final receivedOnlyLoading = readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      final forcedLoading = readNotifier().loadForItems(
        myItemIds: const ['a'],
        takeItemId: 'a',
        isSentReloadForced: true,
      );
      pendingReceived.complete(const []);
      await Future.wait([receivedOnlyLoading, forcedLoading]);

      expect(fakeRepository.receivedRequestedTakeItemIds, ['a', 'a']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'a']);
    });
  });

  group('tradeRequestsProvider 받은 요청 카드별 캐시', () {
    test('이미 본 카드로 돌아오면 응답 전 캐시 즉시 표시(로딩 아님) > 응답 후 서버 값', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.receivedByTakeItemId = {
        'a': [buildTradeRequestHistory('received-a')],
        'b': [buildTradeRequestHistory('received-b')],
      };
      await readNotifier().selectItem('a');
      await readNotifier().selectItem('b');
      final pendingReceivedForA = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceivedForA};

      final loading = readNotifier().selectItem('a');

      var state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.currentTakeItemId, 'a');
      expect(state.received.map((r) => r.tradeRequestHistoryId), ['received-a']);
      expect(state.isReceivedLoading, isFalse);

      pendingReceivedForA.complete([buildTradeRequestHistory('received-a'), buildTradeRequestHistory('received-a2')]);
      await loading;

      state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(fakeRepository.receivedRequestedTakeItemIds, ['a', 'b', 'a']);
      expect(state.received.map((r) => r.tradeRequestHistoryId), ['received-a', 'received-a2']);
    });

    test('처음 보는 카드 > 응답 전까지 로딩 표시, 응답 후 해제', () async {
      await container.read(tradeRequestsProvider.future);
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};

      final loading = readNotifier().selectItem('a');
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isTrue);

      pendingReceived.complete(const []);
      await loading;
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isFalse);
    });

    test('정렬 변경 > 캐시 비움 (새 정렬 응답 전까지 로딩 표시)', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().selectItem('a');
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};

      final loading = readNotifier().changeReceivedSort(RequestSortType.priceHigh);
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isTrue);

      pendingReceived.complete(const []);
      await loading;
    });

    test('조회 실패 > 실패 표시 + 캐시 비움 (다음 진입은 로딩 표시)', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().selectItem('a');
      await readNotifier().selectItem('b');
      fakeRepository.failingReceivedTakeItemIds = {'a'};
      await readNotifier().selectItem('a');
      expect(container.read(tradeRequestsProvider).valueOrNull?.hasReceivedLoadFailed, isTrue);
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isFalse);

      fakeRepository.failingReceivedTakeItemIds = {};
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};
      final loading = readNotifier().selectItem('a');
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isTrue);

      pendingReceived.complete(const []);
      await loading;
    });

    test('이전 카드의 늦은 응답은 상태·캐시 모두에 쓰지 않음', () async {
      await container.read(tradeRequestsProvider.future);
      final staleReceivedForA = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': staleReceivedForA};
      final staleLoading = readNotifier().selectItem('a');
      await readNotifier().selectItem('b');
      staleReceivedForA.complete([buildTradeRequestHistory('stale-a')]);
      await staleLoading;

      final pendingReceivedForA = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceivedForA};
      final loading = readNotifier().selectItem('a');
      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(state.isReceivedLoading, isTrue);
      expect(state.received.map((r) => r.tradeRequestHistoryId), isNot(contains('stale-a')));

      pendingReceivedForA.complete(const []);
      await loading;
    });

    test('읽음 처리 > 캐시도 갱신 (카드 복귀 시 읽음 상태 유지)', () async {
      await container.read(tradeRequestsProvider.future);
      fakeRepository.receivedByTakeItemId = {
        'a': [buildTradeRequestHistory('received-1', isNew: true)],
      };
      await readNotifier().selectItem('a');
      fakeRepository.detailResponse = buildTradeRequestHistory('received-1', isNew: false);
      await readNotifier().markReceivedAsRead('received-1');
      await readNotifier().selectItem('b');
      final pendingReceivedForA = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceivedForA};

      final loading = readNotifier().selectItem('a');
      expect(container.read(tradeRequestsProvider).valueOrNull?.received.single.isNew, isFalse);

      pendingReceivedForA.complete(const []);
      await loading;
    });

    test('카드 목록에서 빠진 카드 캐시 비움 (다시 생기면 로딩 표시)', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'b');
      await readNotifier().loadForItems(myItemIds: const ['a'], takeItemId: 'a');
      final pendingReceivedForB = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'b': pendingReceivedForB};

      final loading = readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'b');
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isTrue);

      pendingReceivedForB.complete(const []);
      await loading;
    });

    test('provider 무효화(로그아웃·계정 전환) > 캐시 비움', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().selectItem('a');
      container.invalidate(tradeRequestsProvider);
      await container.read(tradeRequestsProvider.future);
      final pendingReceived = Completer<List<TradeRequestHistory>>();
      fakeRepository.pendingReceivedByTakeItemId = {'a': pendingReceived};

      final loading = readNotifier().selectItem('a');
      expect(container.read(tradeRequestsProvider).valueOrNull?.isReceivedLoading, isTrue);

      pendingReceived.complete(const []);
      await loading;
    });
  });

  group('tradeRequestsProvider.reloadSentIfStale (탭 진입·앱 복귀)', () {
    test('요청관리 첫 로드 전 > 조회 안 함', () async {
      await container.read(tradeRequestsProvider.future);

      await readNotifier().reloadSentIfStale();

      expect(fakeRepository.sentRequestedGiveItemIds, isEmpty);
    });

    test('마지막 전체 조회 후 최소 간격 미만 > 생략, 지나면 보낸 요청만 모든 카드 재조회 (로딩 표시 없음)', () async {
      await container.read(tradeRequestsProvider.future);
      var now = DateTime(2026, 11, 3, 12);
      readNotifier().now = () => now;
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'a');

      now = now.add(const Duration(seconds: 9));
      await readNotifier().reloadSentIfStale();
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b']);

      now = now.add(TradeRequestsNotifier.sentBackgroundReloadMinimumInterval);
      fakeRepository.sentByGiveItemId = {
        'b': [buildTradeRequestHistory('sent-b-accepted', giveItemId: 'b')],
      };
      await readNotifier().reloadSentIfStale();

      final state = container.read(tradeRequestsProvider).valueOrNull!;
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'b']);
      expect(fakeRepository.receivedRequestedTakeItemIds, ['a']);
      expect(state.sent.map((r) => r.tradeRequestHistoryId), ['sent-b-accepted']);
      expect(state.isReceivedLoading, isFalse);
    });
  });

  group('tradeRequestsProvider.reloadReceivedAndSent (채팅 거래완료 거절 등)', () {
    test('현재 카드 받은 요청 + 모든 카드 보낸 요청 서버 재조회', () async {
      await container.read(tradeRequestsProvider.future);
      await readNotifier().loadForItems(myItemIds: const ['a', 'b'], takeItemId: 'b');

      await readNotifier().reloadReceivedAndSent();

      expect(fakeRepository.receivedRequestedTakeItemIds, ['b', 'b']);
      expect(fakeRepository.sentRequestedGiveItemIds, ['a', 'b', 'a', 'b']);
    });
  });
}
