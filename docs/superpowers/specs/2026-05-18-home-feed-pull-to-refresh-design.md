# 홈 피드 당겨서 새로고침 설계 문서

- **이슈**: [#848](https://github.com/TEAM-ROMROM/RomRom-FE/issues/848)
- **작성일**: 2026-05-18
- **대상 파일**: `lib/screens/home_tab_screen.dart`

---

## 요구사항

1. SafeArea(top) 영역 탭 → 현재 피드를 첫 번째 슬롯으로 자동 스크롤
2. page 0에서 아래로 더 당기면 RefreshIndicator 노출 → 손을 떼면 `_loadInitialItems()` 호출
3. 새로고침 완료 시 피드 목록 초기화 후 재로드 (기존 피드 유지하며 로딩, 완료 후 교체)

---

## 기술 결정

### RefreshIndicator 호환성

`PageView.builder`는 기본 `PageScrollPhysics()`를 사용하며 overscroll notification을 emit하지 않아 표준 `RefreshIndicator`가 동작하지 않음.

**해결**: physics를 `PageScrollPhysics(parent: BouncingScrollPhysics())`로 변경.  
page 0에서 아래로 당기면 고무줄 효과 + `OverscrollNotification` emit → `RefreshIndicator` 감지.

### 스켈레톤 방지

pull refresh 중 `_isLoading = true` 설정 시 `HomeFeedSkeleton`이 덮어 RefreshIndicator 애니메이션이 가려짐.  
`_isPullRefreshing` 플래그로 이 경로를 분기 처리.

### SafeArea 탭 영역

상태바 높이(`MediaQuery.of(context).padding.top`)만 탭 감지 영역으로 설정.  
알림 아이콘 영역과 겹치지 않아 충돌 없음.  
Stack에서 notification icon Positioned **이전**에 배치하여 z-order 상 icon이 위에 있음.

---

## 구현 설계

### 1. 추가 상태 변수

```dart
// _isLoadingUnreadNotification 아래에 추가
bool _isPullRefreshing = false;
```

### 2. 새 메서드: `_onPullRefresh()`

`_loadInitialItems()`와 `_loadMoreItems()` 사이에 추가.

```dart
Future<void> _onPullRefresh() async {
  if (_isLoading) return;
  setState(() {
    _isPullRefreshing = true;
    _currentPage = 0;
    _currentFeedIndex = 0;
    _currentVirtualIndex = 0;
    _aiHighlightedItemIds = [];
    _hasMoreItems = true;
  });
  _pageController.jumpToPage(0);
  await _loadInitialItems();
  if (mounted) {
    setState(() => _isPullRefreshing = false);
  }
}
```

**동작 순서:**
1. `_isLoading` 중이면 중복 호출 차단
2. `_currentPage = 0` reset (이전 `_loadMoreItems()` 호출로 증가한 값 초기화)
3. UI 인덱스 및 AI 하이라이트 초기화
4. `_pageController.jumpToPage(0)` — 애니메이션 없이 즉시 이동
5. `_loadInitialItems()` 완료 후 `_isPullRefreshing = false`

### 3. `_loadInitialItems()` 수정

**a) 스켈레톤 분기 처리:**
```dart
// 변경 전
setState(() {
  _isLoading = true;
});

// 변경 후
if (!_isPullRefreshing) {
  setState(() {
    _isLoading = true;
  });
}
```

**b) `onLoaded` 콜백 분기 처리 (try 블록):**
```dart
// 변경 전
await widget.onLoaded?.call();

// 변경 후
if (!_isPullRefreshing) {
  await widget.onLoaded?.call();
}
```

**c) `onLoaded` 콜백 분기 처리 (catch 블록):**
```dart
// 변경 전
await widget.onLoaded?.call();

// 변경 후
if (!_isPullRefreshing) {
  await widget.onLoaded?.call();
}
```

### 4. `_buildContent()` UI 변경

**a) RefreshIndicator 추가:**

`return Stack(...)` → `return RefreshIndicator(onRefresh: _onPullRefresh, child: Stack(...))` 로 감쌈.

```dart
return RefreshIndicator(
  onRefresh: _onPullRefresh,
  color: AppColors.primaryYellow,
  child: Stack(
    children: [
      // 기존 Stack children 그대로
    ],
  ),
);
```

**b) PageView physics 변경:**

```dart
// 변경 전
physics: _isBlurShown ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),

// 변경 후
physics: _isBlurShown
    ? const NeverScrollableScrollPhysics()
    : const PageScrollPhysics(parent: BouncingScrollPhysics()),
```

**c) SafeArea 탭 GestureDetector 추가:**

Stack children 목록에서 **notification icon Positioned 이전**에 삽입.

```dart
// SafeArea(top) 탭 → 첫 번째 슬롯으로 스크롤
Positioned(
  top: 0,
  left: 0,
  right: 0,
  height: MediaQuery.of(context).padding.top,
  child: GestureDetector(
    onTap: () {
      if (_currentVirtualIndex != 0) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    },
    child: const SizedBox.expand(),
  ),
),
```

---

## 데이터 흐름

```
[user swipes down at page 0]
  → PageScrollPhysics(BouncingScrollPhysics) → OverscrollNotification
  → RefreshIndicator 감지 → 스피너 표시
  → threshold 초과 후 손 뗌 → _onPullRefresh() 호출

[_onPullRefresh()]
  → _isPullRefreshing = true (스켈레톤 방지)
  → _currentPage = 0, indices reset
  → _pageController.jumpToPage(0)
  → _loadInitialItems() (API 호출)
  → _feedItems clear & addAll (피드 교체)
  → _isPullRefreshing = false
  → RefreshIndicator 스피너 사라짐

[user taps SafeArea top]
  → GestureDetector.onTap
  → _currentVirtualIndex != 0 이면 animateToPage(0)
```

---

## 엣지 케이스

| 상황 | 처리 |
|------|------|
| pull refresh 중 추가 pull | `_isLoading` 체크로 차단 |
| pull refresh 중 알림 아이콘 탭 | SafeArea GestureDetector가 notification icon Positioned 아래 → 충돌 없음 |
| `_feedItems.isEmpty` 상태에서 pull | RefreshIndicator는 Scrollable 필요 → empty state는 기존 버튼 방식 유지 |
| blur 활성화 상태 | `NeverScrollableScrollPhysics` 유지 → pull 불가 (의도된 동작) |
| `_currentVirtualIndex == 0` 에서 SafeArea 탭 | 조건 불충족 → animateToPage 호출 안 함 |

---

## 변경 범위

- 변경 파일: `lib/screens/home_tab_screen.dart` 1개
- 신규 파일: 없음
- 신규 의존성: 없음
