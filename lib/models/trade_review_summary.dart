import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

/// 받은 후기 요약: 평점별 수(모든 평점), 태그별 수(모든 태그, 수 내림차순)
/// 서버 통계(전체 후기, 블라인드 제외) 우선, 구버전 서버 > 불러온 후기 목록으로 계산
@immutable
class TradeReviewSummary {
  final Map<TradeReviewRating, int> ratingCounts;
  final List<MapEntry<TradeReviewTag, int>> sortedTagCounts;

  const TradeReviewSummary._({required this.ratingCounts, required this.sortedTagCounts});

  /// 서버 통계 > 요약 (모르는 서버 값 제외)
  factory TradeReviewSummary.fromStats(TradeReviewStats stats) {
    final ratingCountByServerName = stats.ratingCounts ?? const <String, int>{};
    final tagCountByServerName = stats.tagCounts ?? const <String, int>{};
    return TradeReviewSummary._(
      ratingCounts: {
        for (final rating in TradeReviewRating.values) rating: ratingCountByServerName[rating.serverName] ?? 0,
      },
      sortedTagCounts: _sortByCountDescending({
        for (final tag in TradeReviewTag.values) tag: tagCountByServerName[tag.serverName] ?? 0,
      }),
    );
  }

  /// 후기 목록 > 요약 (구버전 서버 폴백, 모르는 서버 값 제외)
  factory TradeReviewSummary.fromReviews(List<TradeReview> reviews) {
    final ratingCountByServerName = <String, int>{};
    final tagCountByServerName = <String, int>{};
    for (final review in reviews) {
      final ratingServerName = review.tradeReviewRating;
      if (ratingServerName != null) {
        ratingCountByServerName[ratingServerName] = (ratingCountByServerName[ratingServerName] ?? 0) + 1;
      }
      for (final tagServerName in review.tradeReviewTags ?? const <String>[]) {
        tagCountByServerName[tagServerName] = (tagCountByServerName[tagServerName] ?? 0) + 1;
      }
    }
    return TradeReviewSummary.fromStats(
      TradeReviewStats(ratingCounts: ratingCountByServerName, tagCounts: tagCountByServerName),
    );
  }

  // 태그 순서 유지 안정 정렬 (같은 수 > enum 순서)
  static List<MapEntry<TradeReviewTag, int>> _sortByCountDescending(Map<TradeReviewTag, int> tagCounts) {
    final sortedTagCounts = tagCounts.entries.toList();
    mergeSort(sortedTagCounts, compare: (first, second) => second.value.compareTo(first.value));
    return sortedTagCounts;
  }
}
