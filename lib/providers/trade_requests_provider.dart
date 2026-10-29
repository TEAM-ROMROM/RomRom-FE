// lib/providers/trade_requests_provider.dart
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';
import 'package:romrom_fe/states/trade_requests_state.dart';

final tradeRequestsProvider = AsyncNotifierProvider<TradeRequestsNotifier, TradeRequestsState>(
  TradeRequestsNotifier.new,
);

/// 요청관리 거래 요청 단일 소유: 받은·보낸 조회(정렬·주소 변환), 읽음 처리, 전송·취소·거절 후 재조회
/// 조회 실패 시 해당 목록 빈 목록 (상태는 AsyncData 유지)
class TradeRequestsNotifier extends AsyncNotifier<TradeRequestsState> {
  TradeRepository get _repository => ref.read(tradeRepositoryProvider);
  ItemAddressResolver get _addressResolver => ref.read(itemAddressResolverProvider);

  // 레이스 방지 차수: 응답 도착 시 차수가 바뀌었으면 폐기 (카드 전환·정렬 변경)
  int _receivedLoadGeneration = 0;
  int _sentLoadGeneration = 0;

  // 화면이 마지막으로 요청한 카드 (정렬 변경·mutation 후 재조회 기준)
  String? _requestedTakeItemId;

  // 같은 카드·물품 목록 전체 로드 진행 중이면 합류 (첫 진입·당겨서 새로고침 중복 방지)
  Future<void>? _inFlightLoadForItems;
  String? _inFlightLoadForItemsKey;

  @override
  FutureOr<TradeRequestsState> build() {
    // 동기 초기화 (Notifier 재사용 시에도 세션별 값 리셋, 진행 중 로드 응답 폐기)
    _receivedLoadGeneration++;
    _sentLoadGeneration++;
    _requestedTakeItemId = null;
    _inFlightLoadForItems = null;
    _inFlightLoadForItemsKey = null;
    return const TradeRequestsState();
  }

  TradeRequestsState get _currentState => state.valueOrNull ?? const TradeRequestsState();

  /// 요청관리 카드 전체 로드: 대상 물품 기록 > 받은(현재 카드)·보낸(모든 카드) 병렬 조회
  Future<void> loadForItems({required List<String> myItemIds, required String? takeItemId}) {
    final loadKey = '${takeItemId ?? ''}|${myItemIds.join(',')}';
    final inFlightLoad = _inFlightLoadForItems;
    if (inFlightLoad != null && _inFlightLoadForItemsKey == loadKey) return inFlightLoad;

    state = AsyncData(_currentState.copyWith(myItemIds: List.unmodifiable(myItemIds)));
    final load = Future.wait([_loadReceived(takeItemId), _loadSent()]).whenComplete(() {
      if (_inFlightLoadForItemsKey != loadKey) return;
      _inFlightLoadForItems = null;
      _inFlightLoadForItemsKey = null;
    });
    _inFlightLoadForItems = load;
    _inFlightLoadForItemsKey = loadKey;
    return load;
  }

  /// 카드 전환: 해당 카드 받은 요청만 재조회
  Future<void> selectItem(String? takeItemId) => _loadReceived(takeItemId);

  /// 받은 요청 정렬 변경 > 현재 카드 재조회 (같은 정렬 무시)
  Future<void> changeReceivedSort(RequestSortType sortType) async {
    if (sortType == _currentState.receivedSortType) return;
    state = AsyncData(_currentState.copyWith(receivedSortType: sortType));
    await _loadReceived(_requestedTakeItemId);
  }

  /// 보낸 요청 정렬 변경 > 모든 카드 재조회 (같은 정렬 무시)
  Future<void> changeSentSort(RequestSortType sortType) async {
    if (sortType == _currentState.sentSortType) return;
    state = AsyncData(_currentState.copyWith(sentSortType: sortType));
    await _loadSent();
  }

  /// 받은 요청 읽음 처리: 서버 상세 조회 > 해당 요청만 isNew 바꾼 새 목록 (실패 시 예외 전달)
  Future<void> markReceivedAsRead(String tradeRequestHistoryId) async {
    final detail = await _repository.getDetail(tradeRequestHistoryId);
    final updatedId = detail?.tradeRequestHistoryId;
    if (detail == null || updatedId == null) return;
    final current = _currentState;
    final updatedReceived = [
      for (final request in current.received)
        request.tradeRequestHistoryId == updatedId ? request.copyWithIsNew(detail.isNew) : request,
    ];
    state = AsyncData(current.copyWith(received: updatedReceived));
  }

  /// 교환 요청 전송 (실패 시 예외 전달) > 보낸 요청 백그라운드 재조회
  Future<void> sendRequest({
    required String? takeItemId,
    required String? giveItemId,
    required List<String> itemTradeOptions,
  }) async {
    await _repository.requestTrade(takeItemId: takeItemId, giveItemId: giveItemId, itemTradeOptions: itemTradeOptions);
    unawaited(_loadSent());
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

  /// 받은 요청 조회: 정렬 반영 > 주소 변환 > 최신 요청일 때만 반영 (카드 없음 > 빈 목록)
  Future<void> _loadReceived(String? takeItemId) async {
    final generation = ++_receivedLoadGeneration;
    _requestedTakeItemId = takeItemId;
    if (takeItemId == null || takeItemId.isEmpty) {
      state = AsyncData(_currentState.copyWith(currentTakeItemId: null, received: const []));
      return;
    }

    List<TradeRequestHistory> received;
    try {
      received = await _repository.getReceived(takeItemId: takeItemId, sortType: _currentState.receivedSortType);
      await _addressResolver.resolveAndCacheAddresses(_itemsOf(received));
    } catch (error, stackTrace) {
      debugPrint('[trade requests] received load failed : $error\n$stackTrace');
      if (generation != _receivedLoadGeneration) return;
      state = AsyncData(_currentState.copyWith(received: const []));
      return;
    }
    if (generation != _receivedLoadGeneration) return;
    state = AsyncData(_currentState.copyWith(currentTakeItemId: takeItemId, received: received));
  }

  /// 보낸 요청 조회: 모든 카드 병렬(카드별 실패 제외) > 카드 순서대로 합침 > 주소 변환 > 최신 요청일 때만 반영
  Future<void> _loadSent() async {
    final generation = ++_sentLoadGeneration;
    final myItemIds = _currentState.myItemIds;
    final sortType = _currentState.sentSortType;

    List<TradeRequestHistory> sent;
    try {
      final sentByItem = await Future.wait(myItemIds.map((giveItemId) => _fetchSentOrEmpty(giveItemId, sortType)));
      sent = sentByItem.expand((requests) => requests).toList();
      await _addressResolver.resolveAndCacheAddresses(_itemsOf(sent));
    } catch (error, stackTrace) {
      debugPrint('[trade requests] sent load failed : $error\n$stackTrace');
      sent = const [];
    }
    if (generation != _sentLoadGeneration) return;
    state = AsyncData(_currentState.copyWith(sent: sent));
  }

  /// 카드 1개 보낸 요청 조회 (실패 시 빈 목록 > 다른 카드 결과는 유지)
  Future<List<TradeRequestHistory>> _fetchSentOrEmpty(String giveItemId, RequestSortType sortType) async {
    try {
      return await _repository.getSent(giveItemId: giveItemId, sortType: sortType);
    } catch (error, stackTrace) {
      debugPrint('[trade requests] sent load failed for item $giveItemId : $error\n$stackTrace');
      return const [];
    }
  }

  /// 요청 목록 > 주소 변환 대상 물품 (상대·내 물품)
  Iterable<Item> _itemsOf(List<TradeRequestHistory> requests) =>
      requests.expand((request) => [request.takeItem, request.giveItem]);
}
