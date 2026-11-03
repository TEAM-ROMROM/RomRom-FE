# #972 구현 계획

설계: `docs/superpowers/specs/2026-11-03-issue-972-account-notification-ux-design.md`
원칙: 로직 변경은 실패 테스트 먼저, 화면 변경은 공통 위젯 재사용. 커밋하지 않음.

## Task 1. 공통 오류 문구
- `ErrorUtils.isNetworkError`, `networkErrorMessage` 추가, `getErrorMessage`가 네트워크 오류에 문구 반환
- 테스트: `test/utils/error_utils_test.dart`

## Task 2. 딥링크 게이트·라우터
- `lib/models/pending_deep_link.dart`, `lib/services/deep_link_gate.dart`, `lib/enums/deep_link_route.dart`
- `deep_link_router.dart`: `ColdStartDeepLinkData` 제거 > 게이트, 경로 판정 `resolveRoute`, 모르는 경로 알림함, 내 물품 판정
- `main.dart`, `firebase_service.dart`, `login_button.dart`, `onboarding_flow_screen.dart`, `user_session_lifecycle.dart` 연결
- 테스트: `test/services/deep_link_gate_test.dart`, `test/utils/deep_link_router_test.dart`, `test/utils/deep_link_router_gate_test.dart`

## Task 3. 스플래시 재시도
- `TokenRefreshOutcome` enum, `TokenReissueResult.fromFailedResponse`·`connectionFailed`, `RomAuthApi.refreshAccessTokenWithOutcome`, `AuthRepository.tryRefreshAccessToken`
- 스플래시: 실패 > 다시 시도 화면, 실행 세대 번호, 권장 업데이트 안내, 회원 조회 오류 분류(`isRetryableMemberLoadError`)
- 테스트: `test/models/token_reissue_result_test.dart`, `test/services/splash_startup_sequence_test.dart`

## Task 4. 앱 업데이트
- `AppVersionApi.resolveUpdateType` (최소·최신 버전), `recommended_update_prompt_rule.dart`
- `app_update_screen.dart`: 스토어 실패 스낵바, iOS 닫기 유지
- 테스트: `test/services/app_version_update_type_test.dart`, `test/services/recommended_update_prompt_service_test.dart`

## Task 5. 알림
- `notification_read_rules.dart`, `NotificationListNotifier.markVisitedTabsAsRead` (동시 4건 제한)
- 알림함: 방문 탭 기록, 전체 삭제 확인, 삭제 알림 payload 전달
- `ExpandableText` 공통 위젯 (알림 본문·후기)
- 설정 화면: 실패 표시, 권한 배너, 마케팅 처리 일자 (`setEnabled` bool 반환)
- `CompletedToggleSwitch` 접근성·터치 영역
- 테스트: 규칙·provider·위젯 테스트

## Task 6. 마이페이지·계정
- 탈퇴 화면, 라이선스·문의 메뉴, 프로필 실패·위치 등록, 차단 목록 실패, 온보딩 이탈 확인, 문의 메일 단일 원본
- 테스트: `test/screens/member_withdrawal_screen_test.dart`

## Task 7. 프로필
- 타인 프로필 다시 시도, 교환 물품 카드 이동, 후기 실패 표시, 닉네임 길이 안내, 카메라·앨범
- 테스트: `test/utils/nickname_rules_test.dart`

## Task 8. 검증
- `dart format --line-length=120 .` > `flutter analyze` > `flutter test`
- diff 자체 검토 (이슈 항목·규칙)
