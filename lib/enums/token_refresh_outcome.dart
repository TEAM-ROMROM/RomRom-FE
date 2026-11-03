/// 시작 화면 토큰 재발급 결과
enum TokenRefreshOutcome {
  success, // 재발급 성공 > 자동 로그인
  rejected, // 서버가 refresh 토큰 거절(만료·무효·제재) > 로그인 화면
  retryableFailure, // 연결 실패·시간 초과·서버 오류 > 다시 시도 화면
}
