// lib/providers/trade_requests_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/states/trade_requests_state.dart';

final tradeRequestsProvider = AsyncNotifierProvider<TradeRequestsNotifier, TradeRequestsState>(
  TradeRequestsNotifier.new,
);

class TradeRequestsNotifier extends AsyncNotifier<TradeRequestsState> {
  TradeRepository get _repo => ref.read(tradeRepositoryProvider);

  @override
  Future<TradeRequestsState> build() async => const TradeRequestsState();

  /// 현재 카드의 받은 요청 로드 (카드 전환 시 호출).
  /// 주소 캐싱은 화면 레이어에서 계속 수행.
  Future<void> loadReceived(String takeItemId) async {
    try {
      final received = await _repo.getReceived(takeItemId: takeItemId);
      final cur = state.value ?? const TradeRequestsState();
      state = AsyncData(cur.copyWith(currentTakeItemId: takeItemId, received: received));
    } catch (e, st) {
      state = AsyncError<TradeRequestsState>(e, st).copyWithPrevious(state);
    }
  }

  /// 모든 카드(giveItemIds)의 보낸 요청 통합 로드.
  Future<void> loadSentForCards(List<String> giveItemIds) async {
    try {
      final results = await Future.wait(giveItemIds.map((id) => _repo.getSent(giveItemId: id)), eagerError: false);
      final sent = results.expand((e) => e).toList();
      final cur = state.value ?? const TradeRequestsState();
      state = AsyncData(cur.copyWith(sent: sent));
    } catch (e, st) {
      state = AsyncError<TradeRequestsState>(e, st).copyWithPrevious(state);
    }
  }

  /// 거래 요청 취소 — 서버 호출 후 목록에서 즉시 제거.
  /// (보낸/받은 양쪽 모두 제거 — 받은요청 삭제도 cancelTradeRequest 사용)
  Future<void> cancel({required String tradeRequestHistoryId}) async {
    await _repo.cancel(tradeRequestHistoryId);
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(
      cur.copyWith(
        received: cur.received.where((r) => r.tradeRequestHistoryId != tradeRequestHistoryId).toList(),
        sent: cur.sent.where((r) => r.tradeRequestHistoryId != tradeRequestHistoryId).toList(),
      ),
    );
  }

  /// 거래 요청 거절 — 서버 호출 후 받은요청 목록에서 즉시 제거.
  Future<void> reject(String tradeRequestHistoryId) async {
    await _repo.reject(tradeRequestHistoryId);
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(
      cur.copyWith(received: cur.received.where((r) => r.tradeRequestHistoryId != tradeRequestHistoryId).toList()),
    );
  }

  /// 화면에서 주소 캐싱 등 side-effect 처리 후 받은요청 목록 주입.
  /// loadReceived와 달리 API 호출 없이 가공된 리스트만 반영.
  /// [takeItemId]가 null이면 기존 currentTakeItemId 유지.
  void setReceived({String? takeItemId, required List<TradeRequestHistory> received}) {
    final cur = state.value ?? const TradeRequestsState();
    state = AsyncData(cur.copyWith(currentTakeItemId: takeItemId ?? cur.currentTakeItemId, received: received));
  }

  /// 화면에서 가공한 보낸요청 통합 리스트 주입.
  void setSent(List<TradeRequestHistory> sent) {
    final cur = state.value ?? const TradeRequestsState();
    state = AsyncData(cur.copyWith(sent: sent));
  }

  /// 외부 이벤트(거래완료 등)로 전체 재조회.
  /// [takeItemId]: 현재 카드(없으면 기존 currentTakeItemId 재사용).
  /// [giveItemIds]: 모든 내 물건 카드 ID 목록.
  Future<void> refreshCurrent({String? takeItemId, required List<String> giveItemIds}) async {
    final resolvedTakeItemId = takeItemId ?? state.value?.currentTakeItemId;
    if (resolvedTakeItemId != null) await loadReceived(resolvedTakeItemId);
    await loadSentForCards(giveItemIds);
  }
}
