// 키워드 알림 정규화·등록 검사 (순수 함수, 서버 정책과 동일: BE #873)
import 'package:romrom_fe/enums/keyword_alert_rejection_reason.dart';

// 정규화 후 키워드 길이 범위 (2~20자)
const int minimumKeywordAlertLength = 2;
const int maximumKeywordAlertLength = 20;

// 서버 응답에 최대 개수가 없을 때 기본값
const int defaultMaximumKeywordAlertCount = 10;

final RegExp _consecutiveWhitespacePattern = RegExp(r'\s+');

/// 등록용 키워드 정리: 앞뒤 공백 제거 > 연속 공백 1칸 (대소문자는 원문 유지)
String tidyKeywordAlert(String keyword) => keyword.trim().replaceAll(_consecutiveWhitespacePattern, ' ');

/// 키워드 정규화 (비교용): 정리 > 소문자
String normalizeKeywordAlert(String keyword) => tidyKeywordAlert(keyword).toLowerCase();

/// 같은 키워드인지 (정규화 값 비교)
bool isSameKeywordAlert(String firstKeyword, String secondKeyword) =>
    normalizeKeywordAlert(firstKeyword) == normalizeKeywordAlert(secondKeyword);

/// 등록 검사 순서: 길이(짧음·김) > 이미 등록 > 개수 초과, 통과 시 null
KeywordAlertRejectionReason? findKeywordAlertRejectionReason({
  required String keyword,
  required Iterable<String> registeredKeywords,
  required int maximumKeywordAlertCount,
}) {
  final normalizedLength = normalizeKeywordAlert(keyword).length;
  if (normalizedLength < minimumKeywordAlertLength) return KeywordAlertRejectionReason.tooShort;
  if (normalizedLength > maximumKeywordAlertLength) return KeywordAlertRejectionReason.tooLong;
  if (registeredKeywords.any((registeredKeyword) => isSameKeywordAlert(registeredKeyword, keyword))) {
    return KeywordAlertRejectionReason.alreadyRegistered;
  }
  if (registeredKeywords.length >= maximumKeywordAlertCount) return KeywordAlertRejectionReason.limitReached;
  return null;
}
