/// 우선노출(롬업) 시도 결과.
/// 화면은 이 값으로 토스트를 분기한다. notifier가 UI에 의존하지 않게 하기 위함.
enum PromoteResult {
  success, // 광고 보상 + 백엔드 활성화 성공
  adNotEarned, // 광고 미시청/중도이탈/로드실패 — 보상 미적립
  failed, // 보상은 받았으나 백엔드 활성화 실패
  alreadyInFlight, // 동일 itemId 처리 중 — 중복 무시
}
