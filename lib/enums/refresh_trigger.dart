/// 홈 피드 자동 새로고침 트리거 종류.
/// 로깅/디버깅 구분용 — 실제 동작 분기는 하지 않는다.
enum RefreshTrigger {
  /// 다른 탭에서 홈 탭으로 재진입
  tabReentry,

  /// 앱이 백그라운드 → 포그라운드로 복귀 (현재 탭이 홈일 때만)
  foregroundResume,
}
