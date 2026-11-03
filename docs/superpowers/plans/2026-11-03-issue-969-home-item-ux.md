# #969 홈 피드·물품 등록·상세 사용성 개선 구현 계획

설계: `docs/superpowers/specs/2026-11-03-issue-969-home-item-ux-design.md`
로직 변경은 실패 테스트 먼저 > 구현. 커밋은 하지 않음 (사용자 확인 후 `/pro-commit`).

## Task 1. 홈 피드 provider
- [x] `RefreshTrigger.manualRefresh`·`searchRangeChanged` + `shouldBypassThrottle`
- [x] `HomeFeedRefreshResult` enum (`lib/enums/home_feed_refresh_result.dart`), `refresh` 반환
- [x] `excludeReportedItem` + 이후 페이지 필터
- [x] 테스트: `test/providers/home_feed_provider_test.dart`

## Task 2. 광고 실패 칸 접기
- [x] `HomeFeedAdSlotSchedule.removeAdAtVirtualIndex` + 테스트
- [x] `NativeAdWidget.onLoadFailed`, 홈 탭 현재 페이지 보정

## Task 3. 홈 탭 화면
- [x] 빈 피드: `EmptyStateView` 보조 버튼 추가, 새로고침 로딩·결과 안내, 탐색 범위 이동
- [x] 신고 후 제외, 카드 덱 실패 버튼(`HomeTabMyItemsLoadErrorButton`)
- [x] 블러 문구 분기, AI 추천 실패·0개 안내

## Task 4. 물품 상세
- [x] `ErrorUtils.getErrorCode` + 테스트
- [x] 교환 완료 흐름(상대 선택 화면 재사용), 교환 가능 변경 확인 창
- [x] 요청하기 버튼 교환 가능일 때만, 삭제 물품 안내, `showItemDeleteConfirmDialog`

## Task 5. 물품 등록·수정
- [x] AI 가격 실패 롤백 + 위젯 테스트
- [x] 수정 화면 실패 뷰 + 위젯 테스트
- [x] 위치 폴백 안내·현재 위치 버튼 안내
- [x] `NewImageUploadCache` + 테스트, 제출 연결
- [x] 수정 모드 주소 실패 표시, `AiPriceBasis` + 테스트

## Task 6. 등록 탭·내 물건·우선 노출
- [x] `MyItemToggleStatus` 빈 상태 문구 + 두 화면 적용
- [x] 10개 한도 모달
- [x] 우선 노출 확인 창, 만료 시 다시 그리기 + 테스트

## Task 7. 좋아요·탐색 범위·카테고리
- [x] 좋아요: 홈 이동, 가격, 해제 유지, 다음 페이지 실패
- [x] 탐색 범위: 오류 분리, 저장 롤백, 피드 갱신, `searchRangeIndexForRadius` + 테스트
- [x] 카테고리: 로딩 종료, 실패 시 저장 차단 + 위젯 테스트

## Task 8. 검증
- [x] `dart format --line-length=120 .` > `flutter analyze` > `flutter test`
- [x] 전체 diff 자기 검토 (이슈 목록·규칙 대조)
