# #975 성능 개선 2단계 G1 (홈·탭) 계획

설계: `docs/superpowers/specs/2026-11-03-issue-975-performance-phase2-home-design.md`
검증: 작업마다 관련 테스트 먼저 작성(실패 확인) > 구현 > 통과. 끝에 `dart format --line-length=120 .` > `flutter analyze` > `flutter test`

## Task 1. 본 물품 기록 분리·묶음 저장 (항목 2)
- 테스트: `test/utils/home_feed_seen_item_history_test.dart` (LRU 100, 첫 기록 후 지연 1회 저장, flush 즉시 저장·타이머 취소, 변경 없으면 저장 안 함)
- 구현: `lib/utils/home_feed_seen_item_history.dart`
- `HomeFeedState.seenItemIds` 제거, notifier가 기록 소유 (`seenItemIds` 테스트용 getter, `flushSeenItemIds()`), dispose 시 flush
- 기존 provider 테스트의 `state.seenItemIds` > `notifier.seenItemIds`, 저장 횟수 테스트는 묶음 저장 기준으로 갱신

## Task 2. 차단 회원 물품 제외 (항목 9)
- 테스트: provider 테스트에 차단 시 현재 목록 제외, loadMore 결과 제외
- 구현: `home_feed_provider.dart` 숨김 필터(신고·차단) 통합, `memberBlockProvider` listen
- 화면 위치 보정: `HomeFeedAdSlotSchedule.virtualIndexAtFeedIndex` + 테스트, `_onFeedItemsRemoved` 보던 물품 기준 보정

## Task 3. AI 가격 매핑·카드 상세 덮어쓰기 제거·상세 미리 그리기 (항목 5, 6)
- 테스트: `home_feed_item_test.dart`에 `aiPrice`·`sourceItem` 매핑
- 구현: `home_feed_item.dart`, `home_feed_item_widget.dart`, `item_detail_description_screen.dart`

## Task 4. 탭 재진입 새로고침 제거·탭 지연 생성·저장 시점 (항목 3, 4)
- 테스트: `test/widgets/common/lazy_indexed_stack_test.dart`
- 구현: `lib/widgets/common/lazy_indexed_stack.dart`, `main_screen.dart` (홈·채팅 즉시, 나머지 첫 방문), `RefreshTrigger.tabReentry` 삭제, 생명주기·탭 이탈 시 본 물품 저장

## Task 5. 미확인 알림 수 provider (항목 8)
- 테스트: `test/providers/notification_unread_count_provider_test.dart`, 기존 알림 목록 테스트 유지
- 구현: `lib/providers/notification_unread_count_provider.dart`, 목록 provider 연동, 홈 배지 구독 교체, `userScopedProviders` 등록, 푸시 갱신 분기

## Task 6. 다음 카드 이미지 미리 받기 (항목 1)
- 테스트: `test/utils/cached_image_precache_test.dart` (CachedImage가 그리는 이미지 키 == 미리 받기 키)
- 구현: `lib/utils/cached_image_precache.dart`, 카드 표시 크기 단일화, 홈 화면 다음 2장 미리 받기

## Task 7. 광고 미리 요청 (항목 7)
- 테스트: `HomeFeedAdSlotSchedule.nextAdVirtualIndexAfter`, `test/widgets/home_tab/home_feed_native_ad_preloader_test.dart`
- 구현: `lib/widgets/home_tab/home_feed_native_ad_preloader.dart`, `native_ad_widget.dart` 미리 받은 광고 사용

## Task 8. 문서·검증
- `.claude/instructions/state-management.md` provider 현황 갱신
- format > analyze > test
