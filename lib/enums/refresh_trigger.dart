/// 홈 피드 새로고침 트리거 종류 (자동 2개: 30초 제한 적용, 사용자 요청 2개: 제한 우회)
enum RefreshTrigger {
  /// 다른 탭에서 홈 탭으로 재진입
  tabReentry(shouldBypassThrottle: false),

  /// 앱이 백그라운드 → 포그라운드로 복귀 (현재 탭이 홈일 때만)
  foregroundResume(shouldBypassThrottle: false),

  /// 빈 피드 '새로고침' 버튼 (사용자가 직접 누름 > 항상 조회)
  manualRefresh(shouldBypassThrottle: true),

  /// 탐색 범위 저장 성공 (조회 조건이 바뀜 > 항상 조회)
  searchRangeChanged(shouldBypassThrottle: true);

  const RefreshTrigger({required this.shouldBypassThrottle});

  /// 30초 자동 새로고침 제한 우회 여부
  final bool shouldBypassThrottle;
}
