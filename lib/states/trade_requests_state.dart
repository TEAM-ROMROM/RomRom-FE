// lib/states/trade_requests_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

/// 요청관리 탭 거래 요청 상태: 현재 카드 받은 요청, 모든 카드 보낸 요청, 정렬 기준, 받은 요청 로딩·조회 실패 여부, 보낸 요청 실패 카드
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

  /// 받은 요청 조회 중 + 보여줄 캐시 없음 (캐시 있으면 캐시 표시 후 백그라운드 갱신 > false)
  final bool isReceivedLoading;

  /// 보낸 요청 마지막 조회에서 실패한 내 물품 ID (요청관리 카드 순서, 다시 시도 시 이 카드만 재조회)
  final List<String> sentFailedItemIds;

  /// 보낸 요청 조회 실패 카드 존재 여부 (일부 실패 > 성공 결과 + 배너, 결과 없음 > 오류 뷰)
  bool get hasSentLoadFailed => sentFailedItemIds.isNotEmpty;

  /// 받은 요청 중 요청자(상대 물품 주인)가 제외 회원(차단 등)인 요청 뺀 목록 (제외 회원 없음 > 원본)
  List<TradeRequestHistory> receivedExcludingRequesters(Set<String> excludedMemberIds) {
    if (excludedMemberIds.isEmpty) return received;
    return received.where((request) => !excludedMemberIds.contains(request.requester?.memberId)).toList();
  }

  /// 보낸 요청 중 상대 물품 주인이 제외 회원(차단 등)인 요청 뺀 목록 (제외 회원 없음 > 원본)
  List<TradeRequestHistory> sentExcludingOpponents(Set<String> excludedMemberIds) {
    if (excludedMemberIds.isEmpty) return sent;
    return sent.where((request) => !excludedMemberIds.contains(request.takeItem.member?.memberId)).toList();
  }

  const TradeRequestsState({
    this.currentTakeItemId,
    this.received = const [],
    this.sent = const [],
    this.myItemIds = const [],
    this.receivedSortType = RequestSortType.latest,
    this.sentSortType = RequestSortType.latest,
    this.hasReceivedLoadFailed = false,
    this.isReceivedLoading = false,
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
    bool? isReceivedLoading,
    List<String>? sentFailedItemIds,
  }) => TradeRequestsState(
    currentTakeItemId: currentTakeItemId == _absent ? this.currentTakeItemId : currentTakeItemId as String?,
    received: received ?? this.received,
    sent: sent ?? this.sent,
    myItemIds: myItemIds ?? this.myItemIds,
    receivedSortType: receivedSortType ?? this.receivedSortType,
    sentSortType: sentSortType ?? this.sentSortType,
    hasReceivedLoadFailed: hasReceivedLoadFailed ?? this.hasReceivedLoadFailed,
    isReceivedLoading: isReceivedLoading ?? this.isReceivedLoading,
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
          isReceivedLoading == other.isReceivedLoading &&
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
    isReceivedLoading,
    Object.hashAll(sentFailedItemIds),
  );

  @override
  String toString() =>
      'TradeRequestsState(takeItemId: $currentTakeItemId, received: ${received.length}, sent: ${sent.length}, '
      'myItems: ${myItemIds.length}, receivedSort: ${receivedSortType.name}, sentSort: ${sentSortType.name}, '
      'receivedFailed: $hasReceivedLoadFailed, receivedLoading: $isReceivedLoading, sentFailedItems: ${sentFailedItemIds.length})';
}
