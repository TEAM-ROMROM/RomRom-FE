// lib/states/trade_requests_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

/// 요청관리 탭 거래 요청 상태: 현재 카드 받은 요청, 모든 카드 보낸 요청, 정렬 기준, 조회 실패 여부
@immutable
class TradeRequestsState {
  /// 현재 보고 있는 카드(takeItemId) — 받은 요청이 어느 카드 기준인지 추적.
  final String? currentTakeItemId;

  /// 현재 카드(takeItemId)의 받은 요청 목록.
  final List<TradeRequestHistory> received;

  /// 모든 내 물건 카드(giveItemId)의 보낸 요청 통합 목록.
  final List<TradeRequestHistory> sent;

  /// 보낸 요청 조회 대상 내 물품 ID 목록 (요청관리 카드 순서)
  final List<String> myItemIds;

  /// 받은 요청 정렬 기준
  final RequestSortType receivedSortType;

  /// 보낸 요청 정렬 기준
  final RequestSortType sentSortType;

  /// 받은 요청 마지막 조회 실패 여부 (빈 목록과 구분 > 다시 시도 표시)
  final bool hasReceivedLoadFailed;

  /// 보낸 요청 마지막 조회에서 실패한 내 물품 ID (요청관리 카드 순서, 다시 시도 시 이 카드만 재조회)
  final List<String> sentFailedItemIds;

  /// 보낸 요청 조회 실패 카드 존재 여부 (일부 실패 > 성공 결과 + 배너, 결과 없음 > 오류 뷰)
  bool get hasSentLoadFailed => sentFailedItemIds.isNotEmpty;

  const TradeRequestsState({
    this.currentTakeItemId,
    this.received = const [],
    this.sent = const [],
    this.myItemIds = const [],
    this.receivedSortType = RequestSortType.latest,
    this.sentSortType = RequestSortType.latest,
    this.hasReceivedLoadFailed = false,
    this.sentFailedItemIds = const [],
  });

  // ignore: avoid_init_to_null
  static const _absent = Object();

  TradeRequestsState copyWith({
    Object? currentTakeItemId = _absent,
    List<TradeRequestHistory>? received,
    List<TradeRequestHistory>? sent,
    List<String>? myItemIds,
    RequestSortType? receivedSortType,
    RequestSortType? sentSortType,
    bool? hasReceivedLoadFailed,
    List<String>? sentFailedItemIds,
  }) => TradeRequestsState(
    currentTakeItemId: currentTakeItemId == _absent ? this.currentTakeItemId : currentTakeItemId as String?,
    received: received ?? this.received,
    sent: sent ?? this.sent,
    myItemIds: myItemIds ?? this.myItemIds,
    receivedSortType: receivedSortType ?? this.receivedSortType,
    sentSortType: sentSortType ?? this.sentSortType,
    hasReceivedLoadFailed: hasReceivedLoadFailed ?? this.hasReceivedLoadFailed,
    sentFailedItemIds: sentFailedItemIds ?? this.sentFailedItemIds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeRequestsState &&
          runtimeType == other.runtimeType &&
          currentTakeItemId == other.currentTakeItemId &&
          listEquals(received, other.received) &&
          listEquals(sent, other.sent) &&
          listEquals(myItemIds, other.myItemIds) &&
          receivedSortType == other.receivedSortType &&
          sentSortType == other.sentSortType &&
          hasReceivedLoadFailed == other.hasReceivedLoadFailed &&
          listEquals(sentFailedItemIds, other.sentFailedItemIds);

  @override
  int get hashCode => Object.hash(
    currentTakeItemId,
    Object.hashAll(received),
    Object.hashAll(sent),
    Object.hashAll(myItemIds),
    receivedSortType,
    sentSortType,
    hasReceivedLoadFailed,
    Object.hashAll(sentFailedItemIds),
  );

  @override
  String toString() =>
      'TradeRequestsState(takeItemId: $currentTakeItemId, received: ${received.length}, sent: ${sent.length}, '
      'myItems: ${myItemIds.length}, receivedSort: ${receivedSortType.name}, sentSort: ${sentSortType.name}, '
      'receivedFailed: $hasReceivedLoadFailed, sentFailedItems: ${sentFailedItemIds.length})';
}
