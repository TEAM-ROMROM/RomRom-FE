/// 홈 피드 새로고침 결과: 화면이 사용자 피드백(로딩 종료·안내)을 고르는 기준
enum HomeFeedRefreshResult {
  /// 첫 페이지 다시 조회 완료 (결과가 비어 있을 수 있음)
  refreshed,

  /// 조회하지 않음 (30초 제한·진행 중·첫 로드 전)
  skipped,

  /// 조회 실패 (기존 목록 유지)
  failed,
}
