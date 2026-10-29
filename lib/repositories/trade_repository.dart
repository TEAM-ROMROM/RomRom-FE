// lib/repositories/trade_repository.dart
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';

class TradeRepository {
  final TradeApi _api;

  TradeRepository(this._api);

  /// 현재 카드(takeItemId)의 받은 거래 요청 목록 조회 (정렬 기준 포함)
  Future<List<TradeRequestHistory>> getReceived({
    required String takeItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    final response = await _api.getReceivedTradeRequests(
      TradeRequest(
        takeItemId: takeItemId,
        sortField: sortType.serverSortField,
        sortDirection: sortType.serverDirection,
      ),
    );
    return response.content;
  }

  /// 특정 카드(giveItemId)의 보낸 거래 요청 목록 조회 (정렬 기준 포함)
  Future<List<TradeRequestHistory>> getSent({
    required String giveItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    final response = await _api.getSentTradeRequests(
      TradeRequest(
        giveItemId: giveItemId,
        sortField: sortType.serverSortField,
        sortDirection: sortType.serverDirection,
      ),
    );
    return response.content;
  }

  /// 거래 요청 상세 조회 (서버 읽음 처리 후 이력 반환, 없으면 null)
  Future<TradeRequestHistory?> getDetail(String tradeRequestHistoryId) async {
    final response = await _api.getDetailedTradeRequest(TradeRequest(tradeRequestHistoryId: tradeRequestHistoryId));
    return response.tradeRequestHistory;
  }

  /// 거래 요청 취소.
  Future<void> cancel(String tradeRequestHistoryId) =>
      _api.cancelTradeRequest(TradeRequest(tradeRequestHistoryId: tradeRequestHistoryId));

  /// 거래 요청 거절.
  Future<void> reject(String tradeRequestHistoryId) => _api.rejectTradeRequest(tradeRequestHistoryId);

  /// 내 물품(giveItemId) > 상대 물품(takeItemId) 교환 요청 존재 여부
  Future<bool> hasTradeRequest({required String? takeItemId, required String? giveItemId}) {
    return _api.checkTradeRequestExistence(TradeRequest(takeItemId: takeItemId, giveItemId: giveItemId));
  }

  /// 교환 요청 전송 (거래 방식 serverName 목록 포함)
  Future<void> requestTrade({
    required String? takeItemId,
    required String? giveItemId,
    required List<String> itemTradeOptions,
  }) {
    return _api.requestTrade(
      TradeRequest(takeItemId: takeItemId, giveItemId: giveItemId, itemTradeOptions: itemTradeOptions),
    );
  }

  /// 상대 물품(takeItemId) 기준 AI 추천 내 물품 목록 (추천순)
  Future<List<Item>> getAiRecommendedItems(String? takeItemId) async {
    final res = await _api.getAiRecommendItemList(TradeRequest(takeItemId: takeItemId));
    return res.itemPage?.content ?? <Item>[];
  }

  /// 거래 후기 작성 (태그·코멘트 null = 미전송)
  Future<void> postTradeReview({
    required String tradeRequestHistoryId,
    required String tradeReviewRating,
    List<String>? tradeReviewTags,
    String? reviewComment,
  }) {
    return _api.postTradeReview(
      TradeRequest(
        tradeRequestHistoryId: tradeRequestHistoryId,
        tradeReviewRating: tradeReviewRating,
        tradeReviewTags: tradeReviewTags,
        reviewComment: reviewComment,
      ),
    );
  }

  /// 회원이 받은 거래 후기 한 페이지 조회
  Future<List<TradeReview>> getTradeReviews({required String? memberId, int pageNumber = 0, int pageSize = 10}) async {
    final res = await _api.getTradeReview(
      TradeRequest(
        member: Member(memberId: memberId),
        pageNumber: pageNumber,
        pageSize: pageSize,
      ),
    );
    return res.tradeReviewPage?.content ?? <TradeReview>[];
  }
}
