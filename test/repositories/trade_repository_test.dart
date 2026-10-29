import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/trade_request.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/apis/trade_api.dart';

/// 거래 API 대역: 마지막 요청 기록, 응답 조절
class FakeTradeApi implements TradeApi {
  TradeRequest? lastRequest;
  bool isTradeRequestExisting = false;
  TradeResponse aiRecommendResponse = TradeResponse();
  TradeResponse tradeReviewResponse = TradeResponse();

  @override
  Future<bool> checkTradeRequestExistence(TradeRequest request) async {
    lastRequest = request;
    return isTradeRequestExisting;
  }

  @override
  Future<TradeResponse> getAiRecommendItemList(TradeRequest request) async {
    lastRequest = request;
    return aiRecommendResponse;
  }

  @override
  Future<void> postTradeReview(TradeRequest request) async => lastRequest = request;

  @override
  Future<TradeResponse> getTradeReview(TradeRequest request) async {
    lastRequest = request;
    return tradeReviewResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('TradeRepository 단건 호출', () {
    late FakeTradeApi fakeApi;
    late TradeRepository repository;

    setUp(() {
      fakeApi = FakeTradeApi();
      repository = TradeRepository(fakeApi);
    });

    test('hasTradeRequest는 상대·내 물품 id를 전달하고 존재 여부 반환', () async {
      fakeApi.isTradeRequestExisting = true;

      expect(await repository.hasTradeRequest(takeItemId: 'take', giveItemId: 'give'), isTrue);
      expect(fakeApi.lastRequest?.takeItemId, 'take');
      expect(fakeApi.lastRequest?.giveItemId, 'give');
    });

    test('getAiRecommendedItems는 추천 목록 반환 (페이지 없으면 빈 목록)', () async {
      expect(await repository.getAiRecommendedItems('take'), isEmpty);

      fakeApi.aiRecommendResponse = TradeResponse(
        itemPage: PagedItem(
          content: [
            Item(itemId: 'A'),
            Item(itemId: 'B'),
          ],
          page: null,
        ),
      );
      final recommendedItems = await repository.getAiRecommendedItems('take');

      expect(recommendedItems.map((item) => item.itemId), ['A', 'B']);
      expect(fakeApi.lastRequest?.takeItemId, 'take');
    });

    test('postTradeReview는 평가·태그·코멘트를 요청에 담음', () async {
      await repository.postTradeReview(
        tradeRequestHistoryId: 'history-1',
        tradeReviewRating: 'GOOD',
        tradeReviewTags: const ['KIND'],
        reviewComment: '좋아요',
      );

      expect(fakeApi.lastRequest?.tradeRequestHistoryId, 'history-1');
      expect(fakeApi.lastRequest?.tradeReviewRating, 'GOOD');
      expect(fakeApi.lastRequest?.tradeReviewTags, ['KIND']);
      expect(fakeApi.lastRequest?.reviewComment, '좋아요');
    });

    test('getTradeReviews는 회원 id·페이지를 전달하고 후기 목록 반환 (없으면 빈 목록)', () async {
      final reviews = await repository.getTradeReviews(memberId: 'member-1', pageNumber: 0, pageSize: 10);

      expect(reviews, isEmpty);
      expect(fakeApi.lastRequest?.member?.memberId, 'member-1');
      expect(fakeApi.lastRequest?.pageSize, 10);
    });
  });
}
