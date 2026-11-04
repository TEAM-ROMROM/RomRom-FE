// lib/providers/trade_requests_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/chat_room_type.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';
import 'package:romrom_fe/states/trade_requests_state.dart';
import 'package:romrom_fe/utils/sent_requests_reload_policy.dart';

final tradeRequestsProvider = AsyncNotifierProvider<TradeRequestsNotifier, TradeRequestsState>(
  TradeRequestsNotifier.new,
);

/// 요청관리 거래 요청 단일 소유: 받은·보낸 조회(정렬·주소 변환), 읽음 처리, 전송·수정·취소·거절 후 재조회
/// 받은 요청은 카드별 캐시 먼저 표시 후 서버 재조회, 조회 실패 시 해당 목록 빈 목록 + 실패 플래그 (상태는 AsyncData 유지)
class TradeRequestsNotifier extends AsyncNotifier<TradeRequestsState> {
  // 보낸 요청 동시 조회 카드 수 (카드 수 제한 없음 > 카드별 호출이 한 번에 몰리지 않게 묶음 처리)
  static const int sentLoadConcurrency = 5;
  // 탭 진입·앱 복귀 보낸 요청 재조회 최소 간격 (연속 진입 시 카드 수만큼 호출 반복 방지)
  static const Duration sentBackgroundReloadMinimumInterval = Duration(seconds: 10);

  TradeRepository get _repository => ref.read(tradeRepositoryProvider);
  ChatRepository get _chatRepository => ref.read(chatRepositoryProvider);
  ItemAddressResolver get _addressResolver => ref.read(itemAddressResolverProvider);

  // 레이스 방지 차수: 응답 도착 시 차수가 바뀌었으면 폐기 (카드 전환·정렬 변경)
  int _receivedLoadGeneration = 0;
  int _sentLoadGeneration = 0;

  // 화면이 마지막으로 요청한 카드 (정렬 변경·mutation 후 재조회 기준)
  String? _requestedTakeItemId;

  // 같은 카드·물품 목록 로드 진행 중이면 합류 (첫 진입·당겨서 새로고침 중복 방지, 보낸 요청 포함 여부 기록)
  Future<void>? _inFlightLoadForItems;
  String? _inFlightLoadForItemsKey;
  bool _isInFlightLoadIncludingSent = false;

  // 보낸 요청 전체 조회 기록 (같은 카드 목록 재조회 생략, 백그라운드 재조회 최소 간격)
  final SentRequestsReloadPolicy _sentReloadPolicy = SentRequestsReloadPolicy(
    minimumBackgroundReloadInterval: sentBackgroundReloadMinimumInterval,
  );

  // 현재 시각 공급자 (테스트에서 교체)
  @visibleForTesting
  DateTime Function() now = DateTime.now;

  // 카드 ID > 받은 요청 마지막 서버 결과 (카드 전환 시 즉시 표시용, 현재 정렬 기준)
  final Map<String, List<TradeRequestHistory>> _receivedCacheByTakeItemId = {};

  @override
  FutureOr<TradeRequestsState> build() {
    // 동기 초기화 (Notifier 재사용 시에도 세션별 값 리셋, 진행 중 로드 응답 폐기)
    _receivedLoadGeneration++;
    _sentLoadGeneration++;
    _requestedTakeItemId = null;
    _inFlightLoadForItems = null;
    _inFlightLoadForItemsKey = null;
    _isInFlightLoadIncludingSent = false;
    _sentReloadPolicy.reset();
    _receivedCacheByTakeItemId.clear();
    return const TradeRequestsState();
  }

  TradeRequestsState get _currentState => state.valueOrNull ?? const TradeRequestsState();

  /// 요청관리 카드 로드: 대상 물품 기록 > 받은(현재 카드)·보낸(모든 카드) 병렬 조회
  /// 보낸 요청: 카드 목록 변경·강제(isSentReloadForced) 때만 조회, 같은 로드 진행 중 > 합류 (보낸 요청 빠졌으면 추가 조회)
  Future<void> loadForItems({
    required List<String> myItemIds,
    required String? takeItemId,
    bool isSentReloadForced = false,
  }) {
    final loadKey = '${takeItemId ?? ''}|${myItemIds.join(',')}';
    final shouldLoadSent = _sentReloadPolicy.shouldLoadForItems(myItemIds, isForced: isSentReloadForced);
    final inFlightLoad = _inFlightLoadForItems;
    if (inFlightLoad != null && _inFlightLoadForItemsKey == loadKey) {
      if (!shouldLoadSent || _isInFlightLoadIncludingSent) return inFlightLoad;
      return _trackInFlightLoad(loadKey, Future.wait([inFlightLoad, _loadSent()]), isIncludingSent: true);
    }

    final myItemIdSet = myItemIds.toSet();
    _receivedCacheByTakeItemId.removeWhere((cachedTakeItemId, _) => !myItemIdSet.contains(cachedTakeItemId));
    state = AsyncData(_currentState.copyWith(myItemIds: List.unmodifiable(myItemIds)));
    return _trackInFlightLoad(
      loadKey,
      Future.wait([_loadReceived(takeItemId), if (shouldLoadSent) _loadSent()]),
      isIncludingSent: shouldLoadSent,
    );
  }

  /// 진행 중 로드 기록 (합류 판단용) > 끝나면 같은 로드일 때만 기록 해제
  Future<void> _trackInFlightLoad(String loadKey, Future<void> load, {required bool isIncludingSent}) {
    late final Future<void> trackedLoad;
    trackedLoad = load.whenComplete(() {
      if (!identical(_inFlightLoadForItems, trackedLoad)) return;
      _inFlightLoadForItems = null;
      _inFlightLoadForItemsKey = null;
      _isInFlightLoadIncludingSent = false;
    });
    _inFlightLoadForItems = trackedLoad;
    _inFlightLoadForItemsKey = loadKey;
    _isInFlightLoadIncludingSent = isIncludingSent;
    return trackedLoad;
  }

  /// 카드 전환: 해당 카드 받은 요청만 재조회
  Future<void> selectItem(String? takeItemId) => _loadReceived(takeItemId);

  /// 받은 요청 정렬 변경 > 카드별 캐시 비움 > 현재 카드 재조회 (같은 정렬 무시)
  Future<void> changeReceivedSort(RequestSortType sortType) async {
    if (sortType == _currentState.receivedSortType) return;
    _receivedCacheByTakeItemId.clear();
    state = AsyncData(_currentState.copyWith(receivedSortType: sortType));
    await _loadReceived(_requestedTakeItemId);
  }

  /// 보낸 요청 정렬 변경 > 모든 카드 재조회 (같은 정렬 무시)
  Future<void> changeSentSort(RequestSortType sortType) async {
    if (sortType == _currentState.sentSortType) return;
    state = AsyncData(_currentState.copyWith(sentSortType: sortType));
    await _loadSent();
  }

  /// 탭 진입·앱 복귀: 보낸 요청 모든 카드 백그라운드 재조회 (첫 로드 전·마지막 전체 조회 후 최소 간격 미만 > 생략)
  /// 상대 수락·취소 반영용, 화면은 기존 목록 유지 후 교체 (로딩 표시 없음)
  Future<void> reloadSentIfStale() async {
    if (!_sentReloadPolicy.shouldReloadInBackground(now())) return;
    await _loadSent();
  }

  /// 보낸 요청 모든 카드 즉시 재조회 (상대 수락·거절 푸시, 최소 간격 무시, #1007)
  Future<void> reloadSent() => _loadSent();

  /// 거래 상태 변경(채팅 거래완료 거절 등) 후 현재 카드 받은 요청 + 모든 카드 보낸 요청 서버 재조회
  Future<void> reloadReceivedAndSent() => Future.wait([reloadReceivedOfRequestedCard(), _loadSent()]);

  /// 보낸 요청 다시 시도 (실패 카드 있음 > 그 카드만 재조회, 없음 > 모든 카드)
  Future<void> retrySentLoad() => _loadSent(isFailedItemsOnly: _currentState.hasSentLoadFailed);

  /// 받은 요청 읽음 처리: 서버 상세 조회 > 해당 요청만 isNew 바꾼 새 목록 (현재 카드 캐시도 갱신, 실패 시 예외 전달)
  Future<void> markReceivedAsRead(String tradeRequestHistoryId) async {
    final detail = await _repository.getDetail(tradeRequestHistoryId);
    final updatedId = detail?.tradeRequestHistoryId;
    if (detail == null || updatedId == null) return;
    final current = _currentState;
    final updatedReceived = [
      for (final request in current.received)
        request.tradeRequestHistoryId == updatedId ? request.copyWithIsNew(detail.isNew) : request,
    ];
    final currentTakeItemId = current.currentTakeItemId;
    if (currentTakeItemId != null && _receivedCacheByTakeItemId.containsKey(currentTakeItemId)) {
      _receivedCacheByTakeItemId[currentTakeItemId] = updatedReceived;
    }
    state = AsyncData(current.copyWith(received: updatedReceived));
  }

  /// 교환 요청 전송 (추가금·한 줄 메시지 선택, 실패 시 예외 전달) > 보낸 요청 백그라운드 재조회
  Future<void> sendRequest({
    required String? takeItemId,
    required String? giveItemId,
    required List<String> itemTradeOptions,
    int? extraChargeAmount,
    String? requestMessage,
  }) async {
    await _repository.requestTrade(
      takeItemId: takeItemId,
      giveItemId: giveItemId,
      itemTradeOptions: itemTradeOptions,
      extraChargeAmount: extraChargeAmount,
      requestMessage: requestMessage,
    );
    unawaited(_loadSent());
  }

  /// 보낸 요청 거래 방식 수정: 서버 호출 > 보낸 요청 백그라운드 재조회 (저장 성공 즉시 반환, 실패 시 예외 전달)
  Future<void> updateTradeOptions({
    required String tradeRequestHistoryId,
    required List<String> itemTradeOptions,
  }) async {
    await _repository.updateTradeOptions(
      tradeRequestHistoryId: tradeRequestHistoryId,
      itemTradeOptions: itemTradeOptions,
    );
    unawaited(_loadSent());
  }

  /// 보낸 요청의 채팅방 ID 찾기: 내 물품 채팅방 목록 > 내가 보낸 방 + 상대 회원 일치 > 상대 물품 대표 이미지 일치
  /// (서버 채팅방 생성은 요청 받은 사람만 가능 > 보낸 사람은 목록에서 찾음, 못 찾거나 구분 불가 > null, 조회 실패 시 예외 전달)
  /// 이미지 있으면 방 1개여도 이미지 일치 필수 (같은 상대의 다른 요청 방 열기 방지), 이미지 없으면 방 1개일 때만
  Future<String?> findChatRoomIdOfSentRequest(TradeRequestHistory request) async {
    final myItemId = request.giveItem.itemId;
    final opponentMemberId = request.takeItem.member?.memberId;
    if (myItemId == null || opponentMemberId == null) return null;

    final chatRooms = (await _chatRepository.getChatRoomsByItemId(itemId: myItemId)).content;
    final sentRoomsWithOpponent = chatRooms
        .where((room) => room.chatRoomType == ChatRoomType.requested && room.targetMember?.memberId == opponentMemberId)
        .toList();
    final opponentItemImageUrl = request.takeItem.primaryImageUrl;
    final matchedRooms = opponentItemImageUrl == null
        ? sentRoomsWithOpponent
        : sentRoomsWithOpponent.where((room) => room.targetItemImageUrl == opponentItemImageUrl).toList();
    return matchedRooms.length == 1 ? matchedRooms.single.chatRoomId : null;
  }

  /// 거래 요청 취소: 서버 호출 > 받은(현재 카드)·보낸 요청 재조회 (실패 시 예외 전달)
  Future<void> cancel({required String tradeRequestHistoryId}) async {
    await _repository.cancel(tradeRequestHistoryId);
    await Future.wait([_loadReceived(_requestedTakeItemId), _loadSent()]);
  }

  /// 거래 요청 거절: 서버 호출 > 현재 카드 받은 요청 재조회 (실패 시 예외 전달)
  Future<void> reject(String tradeRequestHistoryId) async {
    await _repository.reject(tradeRequestHistoryId);
    await _loadReceived(_requestedTakeItemId);
  }

  /// 마지막으로 요청한 카드 받은 요청 재조회 (조회 실패 후 재시도·푸시 수신 공통, 카드 선택 전이면 무시)
  Future<void> reloadReceivedOfRequestedCard() async {
    final requestedTakeItemId = _requestedTakeItemId;
    if (requestedTakeItemId == null || requestedTakeItemId.isEmpty) return;
    await _loadReceived(requestedTakeItemId);
  }

  /// 받은 요청 조회: 캐시 즉시 표시(없으면 로딩 표시) > 정렬 반영 > 주소 변환 > 최신 요청일 때만 반영·캐시
  /// 카드 없음 > 빈 목록, 실패 > 빈 목록 + 실패 플래그 + 해당 카드 캐시 비움
  Future<void> _loadReceived(String? takeItemId) async {
    final generation = ++_receivedLoadGeneration;
    _requestedTakeItemId = takeItemId;
    if (takeItemId == null || takeItemId.isEmpty) {
      state = AsyncData(
        _currentState.copyWith(
          currentTakeItemId: null,
          received: const [],
          hasReceivedLoadFailed: false,
          isReceivedLoading: false,
        ),
      );
      return;
    }

    final cachedReceived = _receivedCacheByTakeItemId[takeItemId];
    state = AsyncData(
      cachedReceived == null
          ? _currentState.copyWith(isReceivedLoading: true)
          : _currentState.copyWith(
              currentTakeItemId: takeItemId,
              received: cachedReceived,
              hasReceivedLoadFailed: false,
              isReceivedLoading: false,
            ),
    );

    List<TradeRequestHistory> received;
    try {
      received = await _repository.getReceived(takeItemId: takeItemId, sortType: _currentState.receivedSortType);
      await _addressResolver.resolveAndCacheAddresses(_itemsOf(received));
    } catch (error, stackTrace) {
      debugPrint('[trade requests] received load failed : $error\n$stackTrace');
      if (generation != _receivedLoadGeneration) return;
      _receivedCacheByTakeItemId.remove(takeItemId);
      state = AsyncData(
        _currentState.copyWith(received: const [], hasReceivedLoadFailed: true, isReceivedLoading: false),
      );
      return;
    }
    if (generation != _receivedLoadGeneration) return;
    _receivedCacheByTakeItemId[takeItemId] = received;
    state = AsyncData(
      _currentState.copyWith(
        currentTakeItemId: takeItemId,
        received: received,
        hasReceivedLoadFailed: false,
        isReceivedLoading: false,
      ),
    );
  }

  /// 보낸 요청 조회: 대상 카드 묶음별 병렬 > 카드 순서대로 합침 > 주소 변환 > 최신 요청일 때만 반영
  /// 대상: 전체 카드 또는 실패 카드만(isFailedItemsOnly, 다른 카드 기존 결과 유지)
  /// 카드별 실패 > 성공 카드 결과 유지 + 실패 카드 ID 기록
  Future<void> _loadSent({bool isFailedItemsOnly = false}) async {
    final generation = ++_sentLoadGeneration;
    final current = _currentState;
    final myItemIds = current.myItemIds;
    if (!isFailedItemsOnly) _sentReloadPolicy.recordFullLoad(myItemIds, startedAt: now());
    final sortType = current.sentSortType;
    final targetItemIds = isFailedItemsOnly ? current.sentFailedItemIds.where(myItemIds.contains).toList() : myItemIds;

    // 실패 카드만 재조회 > 나머지 카드 기존 결과를 카드 ID별로 유지
    final sentByItemId = <String, List<TradeRequestHistory>>{};
    if (isFailedItemsOnly) {
      for (final request in current.sent) {
        sentByItemId.putIfAbsent(request.giveItem.itemId ?? '', () => []).add(request);
      }
    }

    List<TradeRequestHistory> sent;
    List<String> failedItemIds = [];
    try {
      for (var batchStart = 0; batchStart < targetItemIds.length; batchStart += sentLoadConcurrency) {
        final batchItemIds = targetItemIds.skip(batchStart).take(sentLoadConcurrency).toList();
        final batchResults = await Future.wait(
          batchItemIds.map((giveItemId) => _fetchSentOrNull(giveItemId, sortType)),
        );
        // 더 최신 조회 시작됨 > 남은 묶음 호출 생략
        if (generation != _sentLoadGeneration) return;
        for (var index = 0; index < batchItemIds.length; index++) {
          final itemSent = batchResults[index];
          if (itemSent == null) {
            failedItemIds.add(batchItemIds[index]);
          } else {
            sentByItemId[batchItemIds[index]] = itemSent;
          }
        }
      }
      sent = [for (final itemId in myItemIds) ...?sentByItemId[itemId]];
      await _addressResolver.resolveAndCacheAddresses(_itemsOf(sent));
    } catch (error, stackTrace) {
      debugPrint('[trade requests] sent load failed : $error\n$stackTrace');
      sent = const [];
      failedItemIds = List.of(myItemIds);
    }
    if (generation != _sentLoadGeneration) return;
    state = AsyncData(_currentState.copyWith(sent: sent, sentFailedItemIds: List.unmodifiable(failedItemIds)));
  }

  /// 카드 1개 보낸 요청 조회 (실패 > null, 다른 카드 결과는 유지)
  Future<List<TradeRequestHistory>?> _fetchSentOrNull(String giveItemId, RequestSortType sortType) async {
    try {
      return await _repository.getSent(giveItemId: giveItemId, sortType: sortType);
    } catch (error, stackTrace) {
      debugPrint('[trade requests] sent load failed for item $giveItemId : $error\n$stackTrace');
      return null;
    }
  }

  /// 요청 목록 > 주소 변환 대상 물품 (상대·내 물품)
  Iterable<Item> _itemsOf(List<TradeRequestHistory> requests) =>
      requests.expand((request) => [request.takeItem, request.giveItem]);
}
