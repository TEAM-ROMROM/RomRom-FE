// lib/repositories/trade_repository.dart
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';

class TradeRepository {
  final TradeApi _api;

  TradeRepository(this._api);

  /// 현재 카드(takeItemId)의 받은 거래 요청 목록 조회.
  Future<List<TradeRequestHistory>> getReceived({required String takeItemId, int pageSize = 10}) async {
    final res = await _api.getReceivedTradeRequests(
      TradeRequest(takeItemId: takeItemId, pageNumber: 0, pageSize: pageSize),
    );
    return res.content;
  }

  /// 특정 카드(giveItemId)의 보낸 거래 요청 목록 조회.
  Future<List<TradeRequestHistory>> getSent({required String giveItemId, int pageSize = 10}) async {
    final res = await _api.getSentTradeRequests(
      TradeRequest(giveItemId: giveItemId, pageNumber: 0, pageSize: pageSize),
    );
    return res.content;
  }

  /// 거래 요청 취소.
  Future<void> cancel(String tradeRequestHistoryId) =>
      _api.cancelTradeRequest(TradeRequest(tradeRequestHistoryId: tradeRequestHistoryId));

  /// 거래 요청 거절.
  Future<void> reject(String tradeRequestHistoryId) => _api.rejectTradeRequest(tradeRequestHistoryId);
}
