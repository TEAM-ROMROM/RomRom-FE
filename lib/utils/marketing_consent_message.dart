/// 마케팅 수신 동의 변경 안내: 처리 일자(기기 날짜) + 동의·거부 (정보통신망법 수신 동의 처리 결과 고지)
String buildMarketingConsentMessage({required bool isAgreed, required DateTime processedAt}) {
  final year = processedAt.year.toString();
  final month = processedAt.month.toString().padLeft(2, '0');
  final day = processedAt.day.toString().padLeft(2, '0');
  return '$year.$month.$day 마케팅 정보 수신 ${isAgreed ? '동의' : '거부'} 처리되었어요';
}
