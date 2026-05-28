// lib/states/trade_requests_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

@immutable
class TradeRequestsState {
  /// 현재 보고 있는 카드(takeItemId) — 받은 요청이 어느 카드 기준인지 추적.
  final String? currentTakeItemId;

  /// 현재 카드(takeItemId)의 받은 요청 목록.
  final List<TradeRequestHistory> received;

  /// 모든 내 물건 카드(giveItemId)의 보낸 요청 통합 목록.
  final List<TradeRequestHistory> sent;

  const TradeRequestsState({this.currentTakeItemId, this.received = const [], this.sent = const []});

  // ignore: avoid_init_to_null
  static const _absent = Object();

  TradeRequestsState copyWith({
    Object? currentTakeItemId = _absent,
    List<TradeRequestHistory>? received,
    List<TradeRequestHistory>? sent,
  }) => TradeRequestsState(
    currentTakeItemId: currentTakeItemId == _absent ? this.currentTakeItemId : currentTakeItemId as String?,
    received: received ?? this.received,
    sent: sent ?? this.sent,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeRequestsState &&
          runtimeType == other.runtimeType &&
          currentTakeItemId == other.currentTakeItemId &&
          listEquals(received, other.received) &&
          listEquals(sent, other.sent);

  @override
  int get hashCode => Object.hash(currentTakeItemId, Object.hashAll(received), Object.hashAll(sent));

  @override
  String toString() =>
      'TradeRequestsState(takeItemId: $currentTakeItemId, received: ${received.length}, sent: ${sent.length})';
}
