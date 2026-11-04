# 홈 피드 옛 목록 유지 수정 Implementation Plan (#995)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 오래된 홈 피드 목록이 계속 남아 삭제·탈퇴 회원 물품이 보이는 문제를 막는다.

**Architecture:** `HomeFeedNotifier`가 피드를 받은 시각(`lastRefreshAt`)을 첫 로드부터 기록한다. 홈 탭에 들어올 때 받은 지 10분이 지났으면 새로 받는다(`refreshIfStale`). 상세 조회가 "볼 수 없는 물품" 오류를 주면 기존 신고 물품 제외 장치로 그 카드를 피드에서 뺀다(`excludeUnavailableItem`).

**Tech Stack:** Flutter, Riverpod (AsyncNotifier), flutter_test

**Spec:** 이슈 #995 본문 + 대화에서 승인된 설계 (아래 Global Constraints에 값 고정)

## Global Constraints

- 오래됨 기준: 받은 지 **10분** 초과 → 상수 `kHomeFeedStaleAfter = Duration(minutes: 10)` (`lib/providers/home_feed_provider.dart`, 기존 `kHomeFeedRefreshThrottle` 옆)
- 10분 이내 탭 재진입: 새로고침하지 않음(보던 카드 유지, 기존 의도 보존)
- 앱 복귀(`foregroundResume`)는 지금처럼 현재 탭이 홈일 때만 바로 새로고침 (30초 제한 유지)
- 피드에서 뺄 상세 오류 코드 4개: `deletedMember`, `suspendedMember`, `deletedItem`, `itemNotFound` + 새로 추가할 `itemAdminHidden`(`ITEM_ADMIN_HIDDEN`, '관리자에 의해 노출이 차단된 물품입니다.')
- 프로젝트 규칙: `dart format --line-length=120 .` → `flutter analyze` 통과, 모든 명령 앞 `source ~/.zshrc &&`, 주석은 한국어 짧은 구(코딩 규칙 7장)
- **커밋 금지**: 구현자·리뷰어 모두 `git add`/`git commit` 하지 않는다 (사용자 승인 후 메인 세션이 `/pro-commit`)

## Review Focus

- 첫 로드 직후 30초 안에 앱 복귀 → 기존처럼 throttle로 건너뜀(첫 로드도 이제 시각이 있으므로). 정상 동작으로 보고 테스트로 고정
- 새로고침 실패 시 `lastRefreshAt` 유지(갱신 안 됨) → 다음 홈 탭 진입 때 다시 시도
- 새로고침 진행 중 홈 탭 재진입 → 중복 요청 없음(기존 `_inFlightRefresh`로 건너뜀)
- 피드 로딩 전(`state.valueOrNull == null`)에 `refreshIfStale`/`excludeUnavailableItem` 호출 → 아무것도 안 함, 예외 없음
- 피드에 없는 물품 id로 `excludeUnavailableItem` → 상태 변화 없음

---

### Task 1: HomeFeedNotifier — 첫 로드 시각 기록 + refreshIfStale + excludeUnavailableItem

**Files:**
- Modify: `lib/providers/home_feed_provider.dart`
- Modify: `lib/enums/refresh_trigger.dart`
- Test: `test/providers/home_feed_provider_test.dart`

**Interfaces:**
- Produces:
  - `const Duration kHomeFeedStaleAfter = Duration(minutes: 10);`
  - `RefreshTrigger.homeTabEntryAfterStale(shouldBypassThrottle: false)` — enum 주석: 홈 탭 진입 시 피드가 오래됨(10분 초과)
  - `Future<HomeFeedRefreshResult> refreshIfStale()` — 데이터 없음·오래되지 않음 → `HomeFeedRefreshResult.skipped`, 오래됨 → `refresh(trigger: RefreshTrigger.homeTabEntryAfterStale)` 결과 반환. 시간 판정은 기존 테스트용 `now` 필드 사용
  - `void excludeUnavailableItem(String itemId)` — 기존 `excludeReportedItem`과 같은 제외 집합 사용 (세션 동안 기억 + 현재 목록에서 제거). 내부 집합 이름을 `_reportedItemIds` → `_excludedItemIds`로 바꾸고 주석을 "신고·볼 수 없는 물품"으로
- 첫 로드(`build()`가 반환하는 상태)의 `lastRefreshAt`을 `now()`로 채운다. `_fetchInitial`은 시간 함수를 부르지 않는다는 기존 원칙 유지 → `build()`에서 `copyWith(lastRefreshAt: now())`
- `_shouldThrottle`과 `_fetchAndReplaceFeed`의 `DateTime.now()`도 `now()`로 바꿔 테스트에서 시간 조절 가능하게

- [ ] **Step 1: Write the failing tests** (`group('#995 오래된 피드', ...)`)
  - `첫 로드 상태에 lastRefreshAt 기록`: `notifier.now = () => t0` 설정 후 첫 로드 → `state.lastRefreshAt == t0`
  - `10분 이내 refreshIfStale은 조회 안 함`: t0 로드 → now = t0+9분 → `refreshIfStale()` == `skipped`, `repository.callCount` 그대로
  - `10분 초과 refreshIfStale은 새로 조회`: now = t0+11분 → 결과 `refreshed`, callCount 증가, `lastRefreshAt == t0+11분`
  - `새로고침 실패 시 lastRefreshAt 유지 > 다음 refreshIfStale 재시도`: 저장소가 예외 던지게 → 결과 `failed`, `lastRefreshAt == t0`; 예외 해제 후 다시 `refreshIfStale()` → `refreshed`
  - `excludeUnavailableItem은 카드 제거 + 이후 조회에서도 제외`: 목록 [a,b] → `excludeUnavailableItem('a')` → items == [b]; 이후 refresh 응답에 a 포함돼도 결과 [b]
  - `피드 로드 전 호출은 무시`: 로드 완료 전 `refreshIfStale()` == skipped, `excludeUnavailableItem('x')` 예외 없음
  - 시간 조절이 필요하면 `notifier.now`를 첫 `read(homeFeedProvider.future)` 전에 설정 (`container.read(homeFeedProvider.notifier).now = ...`)
  - 실패 저장소가 필요하면 기존 `_FakeRepository`에 `Object? errorToThrow` 필드 추가

- [ ] **Step 2: Run tests to verify they fail**
  Run: `source ~/.zshrc && flutter test test/providers/home_feed_provider_test.dart`
  Expected: 새 테스트 FAIL (`refreshIfStale`/`excludeUnavailableItem` 없음)

- [ ] **Step 3: Implement** 위 Interfaces 그대로

- [ ] **Step 4: Run tests to verify they pass**
  Run: `source ~/.zshrc && flutter test test/providers/home_feed_provider_test.dart test/screens/home_tab_screen_feed_state_test.dart`
  Expected: 전부 PASS (기존 39개 포함)

---

### Task 2: 홈 탭 진입 시 refreshIfStale 호출

**Files:**
- Modify: `lib/screens/main_screen.dart` (`build`의 `ref.listen<int>(currentTabIndexProvider, ...)`)

**Interfaces:**
- Consumes: Task 1 `refreshIfStale()`
- 홈 탭으로 들어오는 전환(`previousTabIndex != home && nextTabIndex == home`)에서 `ref.read(homeFeedProvider.notifier).refreshIfStale()` 호출 (결과 무시, `unawaited`)
- 기존 리스너 주석 "(탭 재진입 새로고침 없음 > 다녀와도 보던 카드 유지)"를 "홈 탭 진입: 10분 넘게 지난 피드만 새로고침, 이탈: 본 물품 기록 즉시 저장" 같은 짧은 구로 갱신
- `lib/enums/refresh_trigger.dart` 맨 위 주석 "탭 재진입은 새로고침하지 않음"을 "탭 재진입은 피드가 10분 넘게 지났을 때만 새로고침"으로 갱신 (Task 1에서 했으면 생략)

- [ ] **Step 1: Implement** 위 내용
- [ ] **Step 2: Verify**
  Run: `source ~/.zshrc && dart format --line-length=120 lib test && flutter analyze`
  Expected: `No issues found!`

---

### Task 3: 상세 조회 "볼 수 없는 물품" 오류 → 피드에서 제거

**Files:**
- Modify: `lib/enums/error_code.dart` — `itemAdminHidden(code: 'ITEM_ADMIN_HIDDEN', koMessage: '관리자에 의해 노출이 차단된 물품입니다.')`를 물품 오류 묶음(`deletedItem` 근처)에 추가
- Modify: `lib/screens/item_detail/item_detail_loading.dart` (`_loadItemDetail`의 `catch`)
- Test: `test/enums/` 또는 기존 error_code 관련 테스트가 없으면 Task 1 테스트로 충분 (화면 단위 테스트 추가 안 함)

**Interfaces:**
- Consumes: Task 1 `excludeUnavailableItem(String itemId)`
- `ErrorCode`에 질문형 getter 추가: `bool get isUnavailableItemError` → 위 5개 코드면 true (enum 안 extension 또는 멤버, 기존 파일 스타일 따름)
- catch에서 `errorCode.isUnavailableItemError`면 `ref.read(homeFeedProvider.notifier).excludeUnavailableItem(widget.itemId)` 호출 (기존 모달·오류 화면 동작은 그대로)

- [ ] **Step 1: Write the failing test**: `test/enums/error_code_unavailable_item_test.dart` — 5개 코드 true, `ErrorCode.itemNotFound` 외 임의 코드(예: `ErrorCode.alreadyHiddenItem`) false, `ApiException.parseErrorCode`류로 `'ITEM_ADMIN_HIDDEN'` 문자열이 `itemAdminHidden`으로 풀리는지(기존 조회 함수가 있으면 그것으로)
- [ ] **Step 2: Run to fail** — `source ~/.zshrc && flutter test test/enums/error_code_unavailable_item_test.dart` → FAIL
- [ ] **Step 3: Implement**
- [ ] **Step 4: Verify** — 위 테스트 PASS + `source ~/.zshrc && dart format --line-length=120 lib test && flutter analyze` → `No issues found!` + `source ~/.zshrc && flutter test` 전체 PASS

---

### Task 4 (메인 세션): 시뮬레이터 1대 E2E

- `/pro-launch`로 iOS 시뮬레이터 1대에서 worktree 앱 실행(운영 서버)
- 홈 피드 → 채팅 탭 이동 → 홈 탭 복귀(10분 이내: 카드 유지) 캡처
- 상세 진입·정상 동작 캡처 (볼 수 없는 물품 재현은 운영 데이터를 건드려야 해서 단위 테스트로 갈음)
