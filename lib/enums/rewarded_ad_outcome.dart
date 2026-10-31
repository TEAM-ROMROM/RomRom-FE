/// 보상형 광고 표시 결과
enum RewardedAdOutcome {
  // 보상 적립 (끝까지 시청)
  earned,
  // 시청 중 이탈 (보상 미적립)
  notEarned,
  // 광고 단위 미설정·로드 실패·표시 실패
  unavailable,
}
