/// 홈 피드 새로고침 트리거 종류 (자동 1개: 30초 제한 적용, 사용자 요청 2개: 제한 우회)
/// 탭 재진입은 피드가 10분 넘게 오래됐을 때만 새로고침 (그 전엔 보던 카드 유지)
enum RefreshTrigger {
  /// 앱이 백그라운드 → 포그라운드로 복귀 (현재 탭이 홈일 때만)
  foregroundResume(shouldBypassThrottle: false),

  /// 홈 탭 진입 시 피드가 오래됨 (마지막 조회 10분 초과)
  homeTabEntryAfterStale(shouldBypassThrottle: false),

  /// 빈 피드 '새로고침' 버튼 (사용자가 직접 누름 > 항상 조회)
  manualRefresh(shouldBypassThrottle: true),

  /// 탐색 범위 저장 성공 (조회 조건이 바뀜 > 항상 조회)
  searchRangeChanged(shouldBypassThrottle: true);

  const RefreshTrigger({required this.shouldBypassThrottle});

  /// 30초 자동 새로고침 제한 우회 여부
  final bool shouldBypassThrottle;
}
