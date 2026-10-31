# 홈 피드 자동 새로고침 + seen-set 기반 중복 노출 방지 — Design Spec

- 작성일: 2026-05-31
- 작성자: SUH SAECHAN (with Claude)
- 관련 이슈(폐기): #848 — 🚀[기능개선][Home] 홈 피드 당겨서 새로고침 기능 추가
- 후속 이슈: (신규) FE — 홈 피드 자동 새로고침 / BE — 홈 피드 셔플 seed/cursor

---

## 1. 배경 & 문제 정의

### 1.1 현재 동작
- `MainScreen`은 `IndexedStack`(`lib/screens/main_screen.dart:135`) 구조이므로 5개 탭이 항상 메모리에 생존한다. 탭 전환 시 `initState`가 다시 실행되지 않는다.
- `HomeTabScreen._loadInitialItems()`는 `initState()`에서 **앱 cold start 1회만** 호출된다 (`lib/screens/home_tab_screen.dart:90`).
- `_loadMoreItems()`는 마지막 페이지 도달 시 `_currentPage = 0`으로 되감아 **동일한 아이템을 동일한 순서로 무한 순환**시킨다 (`lib/screens/home_tab_screen.dart:319`).
- 결과적으로 홈 피드는 **앱 재시작 전까지 절대 갱신되지 않으며**, 본 아이템이 반복해서 같은 순서로 노출된다.

### 1.2 이슈 #848의 한계
- "당겨서 새로고침"은 능동 인터랙션이라 사용자가 그 기능의 존재를 모르면 평생 안 쓴다.
- `PageView(scrollDirection: vertical)` 에 `RefreshIndicator`를 직접 감쌀 수 없어 구현 복잡도가 큼.
- "언제 최신화되는지" 자체에 대한 답이 없음 — 자동 갱신 시점이 정의되지 않음.

### 1.3 목표
1. **자동 갱신 시점 정의**: 사용자가 의식하지 않아도 홈 피드가 자연스럽게 최신 상태가 된다.
2. **중복 노출 최소화**: 데이팅 앱처럼 "방금 본 아이템이 또 보이는" 경험을 줄인다.
3. **API 비용/플리커 통제**: 자동화로 인한 과도한 호출과 시각적 깜빡임을 방지한다.

### 1.4 비목표 (Non-goals)
- 이슈 #848의 "당겨서 새로고침" UI는 **구현하지 않는다** (자동 새로고침으로 대체).
- 서버 측 셔플 seed/cursor는 본 spec 범위 밖 (별도 BE 이슈로 분리).
- 광고 슬롯 노출 빈도/위치 로직 변경 없음 (`_scheduleAdsForNewItems` 기존 동작 유지).

---

## 2. 솔루션 개요

### 2.1 핵심 결정사항
| 항목 | 결정 |
|------|------|
| **트리거** | (a) 홈 탭 재진입 (다른 탭 → 홈 탭) + (b) 앱 포그라운드 복귀(`AppLifecycleState.resumed`) |
| **Throttle** | 직전 새로고침 후 **30초 이내** 트리거는 스킵 |
| **스크롤 위치** | 새로고침 시 무조건 **page 0으로 점프** (`_pageController.jumpToPage(0)`) |
| **로딩 표시** | 상단에 얇은 progress 바만 표시 (스켈레톤 풀스크린 금지) |
| **중복 방지** | 클라 메모리에 `seen itemId Set` 보관, 새로고침 응답에서 **seen 아이템을 뒤로 재정렬** (필터링/제외 아님) |
| **seen-set 크기 제한** | 최대 100개, LRU로 오래된 것부터 제거 |
| **seen-set 리셋** | API가 빈 페이지를 반환하면(풀 소진) seen-set 전체 클리어 |

### 2.2 왜 이 조합인가
- **자동 새로고침이 있는 이상 "당겨서 새로고침"은 잉여 기능** → 이슈 #848 폐기.
- **page 0 점프**: 데이팅 앱 컨셉상 새 카드가 위에서부터 보여야 자연스러움. 사용자가 5번째 카드 보다가 다른 탭 갔다 와도 어차피 컨텍스트가 끊기므로 위치 보존의 가치가 낮음.
- **상단 progress 바**: 자동 트리거라 스켈레톤 풀스크린은 거슬리고, 표시 없음은 무성의함. 얇은 상단 바는 사용자가 거의 인지하지 못하면서도 진행 중임을 알림.
- **seen 재정렬 vs 필터링**: 필터링하면 seen 비율이 높을 때 화면이 비어버림. 재정렬(신선한 것 먼저, 본 것 뒤로)은 빈 화면 위험 없이 체감 다양성을 확보.
- **30초 throttle**: 사용자가 탭을 빠르게 왔다갔다할 때 API 폭격을 막는 최소 가드. 30초는 보수적 기본값으로, 추후 텔레메트리 보고 조정 가능.
- **서버 시드는 BE 이슈로 분리**: 클라 단독으로는 한계가 있지만, FE만 먼저 출시 가능한 형태로 격리하여 의존성 차단.

---

## 3. 아키텍처 & 변경 지점

### 3.1 새 컴포넌트: `HomeFeedNotifier` (Riverpod)
CLAUDE.md의 **상태관리 4-레이어 표준 구조**를 따른다. 홈 피드 상태(아이템 목록, 로딩, seen-set, 마지막 새로고침 시각, 현재 정렬 필드)는 화면 로컬 `setState`가 아니라 **Riverpod provider 단일 소유**로 옮긴다. 자동 새로고침 트리거가 외부(`MainScreen`)에서 들어오므로 provider 중앙화가 필수.

```
lib/repositories/home_feed_repository.dart   ← ItemApi 래핑 (UI 모름)
lib/states/home_feed_state.dart               ← @immutable 상태 모델
lib/providers/home_feed_provider.dart         ← AsyncNotifier + Provider
```

#### `HomeFeedState` 필드
```dart
@immutable
class HomeFeedState {
  final List<HomeFeedItem> items;       // 현재 화면에 표시할 피드
  final int currentPage;                 // 다음 _loadMore에서 요청할 페이지
  final bool hasMoreItems;
  final ItemSortField currentSortField;  // 폴백 결과 저장
  final LinkedHashSet<String> seenItemIds; // 삽입순 보존, LRU 100개 한도
  final DateTime? lastRefreshAt;         // throttle 계산용
}
```

#### `HomeFeedNotifier` (`AsyncNotifier<HomeFeedState>`) 주요 메서드
- `Future<void> loadInitial()` — 폴백 순서(`recommended → distance → preferredCategory → createdDate`)로 페이지 0 조회. 기존 `_loadInitialItems` 로직 이식.
- `Future<void> loadMore()` — 페이지+1 조회. 빈 페이지 시 page 0으로 되감기 + seen-set 클리어.
- `Future<void> refresh({required RefreshTrigger trigger})` — 자동 새로고침 진입점. **30초 throttle 검사**, 통과 시 page 0 조회 + seen 재정렬 + `lastRefreshAt` 갱신.
- `void markSeen(String itemId)` — 화면에 노출된 아이템을 seen-set에 추가 (LRU 관리).

#### Throttle 로직
```dart
bool _shouldThrottle() {
  final last = state.value?.lastRefreshAt;
  if (last == null) return false;
  return DateTime.now().difference(last) < const Duration(seconds: 30);
}
```
- `refresh` 호출 시 throttle 걸리면 silent return (에러 아님, 로그도 안 남김).
- `loadInitial`(cold start 1회)은 throttle 적용 안 함.

#### seen 재정렬 로직
```dart
List<HomeFeedItem> _reorderBySeen(List<HomeFeedItem> fresh, Set<String> seenIds) {
  final unseen = <HomeFeedItem>[];
  final seen = <HomeFeedItem>[];
  for (final item in fresh) {
    if (item.itemUuid != null && seenIds.contains(item.itemUuid)) {
      seen.add(item);
    } else {
      unseen.add(item);
    }
  }
  return [...unseen, ...seen];
}
```

#### seen-set LRU
- `Set<String>` 대신 **`LinkedHashSet<String>`** 사용 — 삽입 순서 보존.
- 추가 시 이미 있으면 제거 후 다시 추가(MRU 갱신).
- 크기 > 100이면 `first` 제거(LRU).
- API가 빈 페이지 반환 시 `clear()`.

### 3.2 `HomeTabScreen` 변경
- 로컬 상태 (`_feedItems`, `_currentPage`, `_hasMoreItems`, `_isLoading`, `_isLoadingMore`, `_currentSortField`)를 **모두 제거**하고 `ref.watch(homeFeedProvider)`로 구독.
- 광고 슬롯 가상 인덱스 시스템 (`_adVirtualIndices`, `_scheduleAdsForNewItems`, `_currentVirtualIndex`)은 **화면 로컬 유지** — 광고는 표시 계층 관심사. `ref.listen<AsyncValue<HomeFeedState>>`에서 items가 교체되는 것을 감지하면, `_adVirtualIndices.clear()` + `_adVirtualIndicesSorted.clear()` + `_nextAdAfterFeedIndex = _adFreeCount` 리셋 후 `_scheduleAdsForNewItems()` 재호출(§7과 동일 로직).
- `initState`에서 `_loadInitialItems()` 직접 호출 제거 → provider가 lazy build 시 자동 호출.
- `PageView.builder`의 `onPageChanged` 콜백에서 현재 노출된 아이템의 `itemUuid`를 `ref.read(homeFeedProvider.notifier).markSeen(...)`로 전달.
- 새로고침 응답으로 아이템이 교체되면 `_pageController.jumpToPage(0)` 호출. provider 상태 변경을 `ref.listen`으로 감지하여 처리.

### 3.3 `MainScreen` 변경
- 탭 인덱스 변화를 감지하여 **0(홈) 진입 시** `ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry)` 호출.
  ```dart
  ref.listen<int>(currentTabIndexProvider, (prev, next) {
    if (next == 0 && prev != null && prev != 0) {
      ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);
    }
  });
  ```
  - `prev != null && prev != 0` 조건: 앱 최초 시작 시 (`prev == null`) 트리거 안 함. cold start는 `loadInitial`이 담당.
- `didChangeAppLifecycleState`에 `AppLifecycleState.resumed` 분기 추가:
  ```dart
  if (state == AppLifecycleState.resumed) {
    final currentTab = ref.read(currentTabIndexProvider);
    if (currentTab == 0) {
      ref.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);
    }
    // 기존 _syncNotificationPermissionToBackend / _tryShowReviewPopup 유지
  }
  ```
  - 포그라운드 복귀 시 **현재 탭이 홈일 때만** 새로고침. 다른 탭에서 백그라운드 들어갔다 오면 다음 홈 탭 진입 시 자연 트리거됨.

### 3.4 상단 progress 바
- `HomeTabScreen`의 기존 `Stack` 최상단에 얇은 `LinearProgressIndicator`(높이 2~3px) 추가.
- `state.isLoading && state.hasValue` (= 새로고침 중이고 표시할 데이터가 있음)일 때만 노출.
- 색상: `AppColors.primaryYellow`. 직접 색상 코드 금지 규칙 준수.
- cold start의 풀스크린 스켈레톤(`HomeFeedSkeleton`)은 그대로 유지 (이건 자동 새로고침이 아니라 최초 로딩).

---

## 4. 데이터 플로우

### 4.1 Cold start
```
앱 실행 → MainScreen.build → HomeTabScreen build → ref.watch(homeFeedProvider)
  → AsyncNotifier.build() → loadInitial() → API 호출 → state 갱신
  → HomeFeedSkeleton에서 실제 피드로 전환
```

### 4.2 탭 재진입
```
사용자가 채팅 탭(3) → 홈 탭(0) 누름
  → currentTabIndexProvider.set(0)
  → MainScreen의 ref.listen 발화 (prev=3, next=0)
  → refresh(tabReentry) 호출
    → throttle 검사 (30초 이내면 silent return)
    → page 0 API 호출 (currentSortField로)
    → 응답을 seen-set 기준 재정렬
    → state.items 교체, lastRefreshAt 갱신
  → HomeTabScreen의 ref.listen이 items 변경 감지
    → _pageController.jumpToPage(0)
    → 광고 슬롯 인덱스 리셋 (_adVirtualIndices.clear(), _scheduleAdsForNewItems())
```

### 4.3 포그라운드 복귀
```
앱이 백그라운드 → 사용자가 다시 앱 열음
  → MainScreen.didChangeAppLifecycleState(resumed)
  → 현재 탭이 0인지 확인
  → 0이면 refresh(foregroundResume) — throttle 동일 적용
  → 다른 탭이면 아무것도 안 함
```

### 4.4 무한 스크롤 (기존 _loadMoreItems 대체)
```
사용자가 PageView 끝까지 스크롤 → ScrollNotification maxScrollExtent 감지
  → loadMore() 호출
  → page+1 API 호출
  → 빈 페이지면 page=0 + seenItemIds.clear() + 재호출 (기존 "또돌이표" 유지)
  → 응답을 seen-set 기준 재정렬 후 items에 append
```

### 4.5 seen 마킹
```
PageView.onPageChanged(index)
  → 광고 슬롯이 아니면 현재 아이템의 itemUuid를 markSeen으로 전달
  → LinkedHashSet에 추가 (이미 있으면 제거 후 재추가 = MRU)
  → 크기 > 100이면 first 제거
```

---

## 5. 에러 처리

| 상황 | 처리 |
|------|------|
| Cold start API 실패 | 기존 동작 유지 — `CommonSnackBar.error` + 빈 상태 노출 |
| 자동 새로고침 API 실패 | **silent fail** — 사용자가 트리거한 게 아니므로 SnackBar 안 띄움. 기존 items 그대로 유지. 로그만 남김 (`debugPrint`) |
| loadMore API 실패 | 기존 동작 유지 — `CommonSnackBar.error` |
| 새로고침 중 사용자가 또 새로고침 트리거 | `state.isLoading`이면 silent return (중복 진행 방지) |
| jumpToPage 호출 시점에 PageController가 attach 안 됨 | `addPostFrameCallback`으로 감싸서 다음 프레임에 호출. `hasClients` 체크. |

---

## 6. 테스트 전략

### 6.1 단위 테스트 (`test/providers/home_feed_provider_test.dart`)
- `loadInitial`: 폴백 순서 동작 (첫 정렬에서 빈 결과 → 다음 정렬로 진행)
- `refresh` throttle: 30초 이내 호출 시 API 호출 안 됨, 30초 후 호출 시 동작
- seen 재정렬: seen 아이템이 응답 끝으로 이동
- seen-set LRU: 100개 초과 시 가장 오래된 것 제거
- 빈 페이지 응답 시 seen-set 클리어
- 자동 새로고침 silent fail: 에러 시 기존 items 유지, state.error 안 set
- 중복 새로고침 가드: `isLoading` 중 `refresh` 호출 시 무시

### 6.2 위젯 테스트
- 탭 인덱스 0→3→0 변경 시 `refresh` 호출 검증 (mock notifier 사용)
- 탭 인덱스 null→0 (cold start)은 `refresh` 호출 안 함
- 새로고침 완료 시 `_pageController.jumpToPage(0)` 호출 검증

### 6.3 수동 QA 시나리오
1. 홈 → 채팅 → 홈 30초 내 → API 호출 안 됨 확인 (네트워크 로그)
2. 홈 → 채팅 → 홈 31초 후 → API 호출 + 상단 progress 바 노출 + 맨 위로 이동 확인
3. 홈에서 카드 5개 정도 본 후 다른 탭 → 홈 → 본 카드들이 응답 끝쪽으로 밀려 있는지 (재정렬) 확인
4. 앱 백그라운드 → 5분 후 포그라운드 + 현재 탭이 홈 → 새로고침 발생 확인
5. 앱 백그라운드 → 포그라운드 + 현재 탭이 채팅 → 홈 새로고침 발생 안 함 확인
6. cold start 시 풀스크린 스켈레톤은 그대로, 자동 새로고침 시에는 상단 progress 바만 확인
7. 새로고침 중 API 실패 → SnackBar 안 뜸, 기존 피드 유지 확인

---

## 7. 마이그레이션 / 호환성

- 기존 `_loadInitialItems`, `_loadMoreItems`, `_currentPage`, `_currentSortField`, `_feedItems`, `_isLoading`, `_isLoadingMore`, `_hasMoreItems` **전부 제거**.
- `HomeTabScreen`의 `onLoaded` 콜백 (`main_screen.dart:33,52`): 알림 권한 바텀시트 트리거에 사용 중. provider의 초기 로드 완료 시점에 호출해야 함 → `ref.listen<AsyncValue<HomeFeedState>>`에서 `previous == AsyncLoading() && next is AsyncData` 전환을 감지하여 `onLoaded` 호출. 1회만 호출되도록 가드.
- `myItemsProvider` 기반 블러(`isBlurShown`) 로직: 그대로 유지. 블러일 때는 `PageView` 스크롤이 막혀 있어 새로고침도 사실상 동작 안 함. 추가 가드 불필요(트리거 자체는 들어오지만 사용자가 화면을 못 보므로 무해).
- 광고 슬롯 로직: 화면 로컬 유지 — 아이템 교체 시 `_adVirtualIndices.clear()` + `_nextAdAfterFeedIndex = _adFreeCount` 리셋 후 `_scheduleAdsForNewItems()` 재호출. `ref.listen`으로 items 변경 감지하여 처리.

---

## 8. 후속 작업

### 8.1 본 spec 범위 (FE)
- 본 문서 기반으로 신규 GitHub 이슈 발행: **"홈 피드 자동 새로고침 + seen-set 기반 중복 노출 방지"**
- 이슈 #848 클로즈 (코멘트로 본 spec 링크 + 폐기 사유 명시)

### 8.2 본 spec 범위 밖 (BE 별도 이슈)
- **"홈 피드 API에 셔플 seed/cursor 추가"** — 데이팅 앱식 진짜 다양화는 서버 측 셔플이 필수.
  - 요청에 `seed: String` 또는 `cursor: String` 필드 추가
  - 새로고침 시 새 seed 발급, 같은 seed면 같은 순서 보장 (페이지네이션 안정성)
  - FE 측 seen-set은 BE 시드 도입 후에도 보조 수단으로 유지 (정렬 안정화)

### 8.3 텔레메트리 (선택, 후속 PR)
- `refresh` 호출 횟수, throttle 차단 횟수, seen-set 평균 크기 로깅 → 30초 throttle 값 튜닝 근거 확보.

---

## 9. 파일 변경 요약

### 추가
- `lib/repositories/home_feed_repository.dart`
- `lib/states/home_feed_state.dart`
- `lib/providers/home_feed_provider.dart`
- `lib/enums/refresh_trigger.dart` (`tabReentry`, `foregroundResume`)
- `test/providers/home_feed_provider_test.dart`

### 수정
- `lib/screens/home_tab_screen.dart` — 로컬 상태 제거, provider 구독, 광고 슬롯만 로컬 유지, 상단 progress 바 추가, jumpToPage 처리
- `lib/screens/main_screen.dart` — 탭 인덱스 listen, lifecycle resumed 분기

### 삭제
- 없음 (메서드/필드 제거는 home_tab_screen.dart 수정 안에서 처리)
