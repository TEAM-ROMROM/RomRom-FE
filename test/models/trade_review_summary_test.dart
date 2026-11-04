import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/trade_review_summary.dart';

/// 받은 후기 요약 검증: 서버 통계·후기 목록 > 모든 평점·태그 포함, 태그 수 내림차순, 모르는 서버 값 제외
void main() {
  test('서버 통계 > 평점별 수, 태그 수 내림차순 (없는 값 0, 모르는 값 제외)', () {
    final summary = TradeReviewSummary.fromStats(
      TradeReviewStats(ratingCounts: {'GREAT': 5, 'GOOD': 2, 'UNKNOWN': 9}, tagCounts: {'KIND': 3, 'PUNCTUAL': 7}),
    );

    expect(summary.ratingCounts[TradeReviewRating.great], 5);
    expect(summary.ratingCounts[TradeReviewRating.bad], 0);
    expect(summary.sortedTagCounts.first.key, TradeReviewTag.punctual);
    expect(summary.sortedTagCounts[1].key, TradeReviewTag.kind);
    expect(summary.sortedTagCounts.length, TradeReviewTag.values.length);
  });

  test('후기 목록(구버전 서버 폴백) > 같은 방식으로 집계', () {
    final summary = TradeReviewSummary.fromReviews([
      TradeReview(tradeReviewRating: 'GOOD', tradeReviewTags: const ['KIND']),
      TradeReview(tradeReviewRating: 'GOOD', tradeReviewTags: const ['KIND', 'FAST_RESPONSE']),
      TradeReview(tradeReviewRating: null),
    ]);

    expect(summary.ratingCounts[TradeReviewRating.good], 2);
    expect(summary.sortedTagCounts.first.key, TradeReviewTag.kind);
    expect(summary.sortedTagCounts.first.value, 2);
  });
}
