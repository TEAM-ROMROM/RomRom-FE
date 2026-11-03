import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/utils/trade_review_rules.dart';

void main() {
  group('availableReviewTags', () {
    test('별로예요는 칭찬 태그를 보여주지 않고, 좋아요·최고에요는 전체 태그', () {
      expect(availableReviewTags(TradeReviewRating.bad), isEmpty);
      expect(availableReviewTags(TradeReviewRating.good), TradeReviewTag.values);
      expect(availableReviewTags(TradeReviewRating.great), TradeReviewTag.values);
    });
  });

  group('hasReviewDetails', () {
    test('평가에 맞는 태그 또는 한마디가 있으면 true', () {
      expect(
        hasReviewDetails(rating: TradeReviewRating.good, selectedTags: {TradeReviewTag.kind}, comment: ''),
        isTrue,
      );
      expect(hasReviewDetails(rating: TradeReviewRating.good, selectedTags: {}, comment: '  고마워요 '), isTrue);
      expect(hasReviewDetails(rating: TradeReviewRating.good, selectedTags: {}, comment: '   '), isFalse);
    });

    test('별로예요로 바꾸면 이전에 고른 칭찬 태그는 세지 않는다', () {
      expect(
        hasReviewDetails(rating: TradeReviewRating.bad, selectedTags: {TradeReviewTag.kind}, comment: ''),
        isFalse,
      );
    });
  });

  group('buildTradeReviewSubmission', () {
    test('평가에 맞는 태그만 보내고 한마디는 앞뒤 공백을 지운다', () {
      final submission = buildTradeReviewSubmission(
        rating: TradeReviewRating.great,
        selectedTags: {TradeReviewTag.kind, TradeReviewTag.punctual},
        comment: ' 감사합니다 ',
        isSkippingDetails: false,
      );

      expect(submission.tagServerNames, unorderedEquals(['KIND', 'PUNCTUAL']));
      expect(submission.comment, '감사합니다');
    });

    test('별로예요 + 한마디만이면 태그는 null, 한마디만 보낸다', () {
      final submission = buildTradeReviewSubmission(
        rating: TradeReviewRating.bad,
        selectedTags: {TradeReviewTag.kind},
        comment: '약속 시간을 안 지켰어요',
        isSkippingDetails: false,
      );

      expect(submission.tagServerNames, isNull);
      expect(submission.comment, '약속 시간을 안 지켰어요');
    });

    test('건너뛰기는 태그·한마디 없이 평가만 보낸다', () {
      final submission = buildTradeReviewSubmission(
        rating: TradeReviewRating.good,
        selectedTags: {TradeReviewTag.kind},
        comment: '좋아요',
        isSkippingDetails: true,
      );

      expect(submission.tagServerNames, isNull);
      expect(submission.comment, isNull);
    });
  });
}
