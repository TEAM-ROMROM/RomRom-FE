// 거래 후기 작성 판정 순수 함수: 평가별 태그, 상세 작성 여부, 제출 값 정리
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';

// 한마디 최대 글자 수 (서버 제한 미확인 > 보수적 값)
const int tradeReviewCommentMaxLength = 200;

/// 평가별 선택 가능한 태그 (별로예요 > 없음: 서버 태그가 칭찬 5종뿐이라 한마디로만 남김)
List<TradeReviewTag> availableReviewTags(TradeReviewRating rating) {
  return rating == TradeReviewRating.bad ? const [] : TradeReviewTag.values;
}

/// 평가에 맞는 태그 또는 한마디가 있는지 (완료 버튼 활성, 건너뛰기 전 확인 판정)
bool hasReviewDetails({
  required TradeReviewRating rating,
  required Set<TradeReviewTag> selectedTags,
  required String comment,
}) {
  return _selectAvailableTags(rating, selectedTags).isNotEmpty || comment.trim().isNotEmpty;
}

/// 제출 값 정리: 평가에 맞는 태그만, 한마디 앞뒤 공백 제거, 빈 값 null (건너뛰기 > 평가만)
({List<String>? tagServerNames, String? comment}) buildTradeReviewSubmission({
  required TradeReviewRating rating,
  required Set<TradeReviewTag> selectedTags,
  required String comment,
  required bool isSkippingDetails,
}) {
  if (isSkippingDetails) return (tagServerNames: null, comment: null);
  final availableTags = _selectAvailableTags(rating, selectedTags);
  final trimmedComment = comment.trim();
  return (
    tagServerNames: availableTags.isEmpty ? null : availableTags.map((tag) => tag.serverName).toList(),
    comment: trimmedComment.isEmpty ? null : trimmedComment,
  );
}

/// 고른 태그 중 현재 평가에서 선택 가능한 것만 (평가를 바꾼 뒤 남은 태그 제외)
List<TradeReviewTag> _selectAvailableTags(TradeReviewRating rating, Set<TradeReviewTag> selectedTags) {
  final availableTags = availableReviewTags(rating);
  return selectedTags.where(availableTags.contains).toList();
}
