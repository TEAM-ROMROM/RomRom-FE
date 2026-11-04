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

  /// 특정 카드(giveItemId)의 보낸 거래 요청 목록 조회 (정렬 기준 포함, 거절 건 포함)
  Future<List<TradeRequestHistory>> getSent({
    required String giveItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    final response = await _api.getSentTradeRequests(
      TradeRequest(
        giveItemId: giveItemId,
        sortField: sortType.serverSortField,
        sortDirection: sortType.serverDirection,
        isRejectedIncluded: true,
      ),
    );
    return response.content;
  }

  // 보낸 요청 전체 조회 페이지 크기·최대 페이지 수 (100건 x 20쪽 = 2,000건까지, 무한 반복 방지)
  static const int allSentPageSize = 100;
  static const int allSentMaximumPageCount = 20;

  /// 내 보낸 거래 요청 전체 (모든 물품 한 번에, 마지막 페이지까지 이어 조회, 정렬 기준 포함)
  /// 구버전 서버(API 없음)·조회 실패 > 예외 전달 (호출부가 물품별 조회로 대체)
  Future<List<TradeRequestHistory>> getAllSent({RequestSortType sortType = RequestSortType.latest}) async {
    final allSent = <TradeRequestHistory>[];
    for (var pageNumber = 0; pageNumber < allSentMaximumPageCount; pageNumber++) {
      final sentPage = await _api.getAllSentTradeRequests(
        TradeRequest(
          pageNumber: pageNumber,
          pageSize: allSentPageSize,
          sortField: sortType.serverSortField,
          sortDirection: sortType.serverDirection,
        ),
      );
      allSent.addAll(sentPage.content);
      final totalPages = sentPage.page?.totalPages ?? 0;
      if (sentPage.content.length < allSentPageSize || pageNumber + 1 >= totalPages) break;
    }
    return allSent;
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

  /// 보낸 거래 요청의 거래 방식 수정 (서버: 대기 상태 요청만 허용)
  Future<void> updateTradeOptions({required String tradeRequestHistoryId, required List<String> itemTradeOptions}) =>
      _api.updateTradeRequest(tradeRequestHistoryId, itemTradeOptions);

  /// 내 물품(giveItemId) > 상대 물품(takeItemId) 교환 요청 존재 여부
  Future<bool> hasTradeRequest({required String? takeItemId, required String? giveItemId}) {
    return _api.checkTradeRequestExistence(TradeRequest(takeItemId: takeItemId, giveItemId: giveItemId));
  }

  /// 교환 요청 전송 (거래 방식 serverName 목록 + 선택 추가금·한 줄 메시지)
  Future<void> requestTrade({
    required String? takeItemId,
    required String? giveItemId,
    required List<String> itemTradeOptions,
    int? extraChargeAmount,
    String? requestMessage,
  }) {
    return _api.requestTrade(
      TradeRequest(
        takeItemId: takeItemId,
        giveItemId: giveItemId,
        itemTradeOptions: itemTradeOptions,
        extraChargeAmount: extraChargeAmount,
        requestMessage: requestMessage,
      ),
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

  /// 회원이 받은 거래 후기 통계 (구버전 서버·실패 > 예외 전달)
  Future<TradeReviewStats?> getTradeReviewStats(String memberId) => _api.getTradeReviewStats(memberId);

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
