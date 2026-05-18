# 홈 피드 당겨서 새로고침 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `PageView.builder` 기반 홈 피드에 SafeArea 탭으로 맨 위 슬롯 이동 + 당겨서 새로고침 기능 추가

**Architecture:** `PageScrollPhysics(parent: BouncingScrollPhysics())`로 overscroll notification을 활성화하여 표준 `RefreshIndicator`가 page 0에서의 pull-down을 감지하도록 함. `_isPullRefreshing` 플래그로 pull refresh 중 스켈레톤 표시를 방지하고 기존 피드를 유지함. SafeArea 탭 감지는 Stack에서 알림 아이콘 아래 z-order로 배치된 `GestureDetector`로 처리함.

**Tech Stack:** Flutter, Dart, flutter_screenutil

---

## 변경 파일

| 파일 | 변경 유형 | 변경 내용 |
|------|----------|----------|
| `lib/screens/home_tab_screen.dart` | Modify | 상태 변수, 메서드, UI 변경 전체 |

---

### Task 1: `_isPullRefreshing` 상태 변수 추가

**Files:**
- Modify: `lib/screens/home_tab_screen.dart` (상태 변수 선언부, 약 line 79)

- [ ] **Step 1: `_isLoadingUnreadNotification` 선언 바로 아래에 `_isPullRefreshing` 추가**

`lib/screens/home_tab_screen.dart`에서 아래 코드를 찾아:

```dart
  // 미확인 알림 조회 중복 요청 방지
  bool _isLoadingUnreadNotification = false;
  // 오버레이 엔트리
  OverlayEntry? _overlayEntry;
```

다음과 같이 수정:

```dart
  // 미확인 알림 조회 중복 요청 방지
  bool _isLoadingUnreadNotification = false;
  // 당겨서 새로고침 진행 중 여부 (스켈레톤 표시 방지용)
  bool _isPullRefreshing = false;
  // 오버레이 엔트리
  OverlayEntry? _overlayEntry;
```

- [ ] **Step 2: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/home_tab_screen.dart
```

Expected: No errors.

---

### Task 2: `_loadInitialItems()` 스켈레톤 & `onLoaded` 분기 처리

**Files:**
- Modify: `lib/screens/home_tab_screen.dart` (`_loadInitialItems()` 메서드, 약 line 284-336)

- [ ] **Step 1: `setState({ _isLoading = true })` 를 `_isPullRefreshing` 조건으로 분기**

아래 코드를 찾아:

```dart
    setState(() {
      _isLoading = true;
    });

    const fallbackOrder = [
```

다음과 같이 수정:

```dart
    if (!_isPullRefreshing) {
      setState(() {
        _isLoading = true;
      });
    }

    const fallbackOrder = [
```

- [ ] **Step 2: try 블록의 `widget.onLoaded?.call()` 분기 처리**

아래 코드를 찾아 (try 블록 내부):

```dart
        _hasMoreItems = items.isNotEmpty;
        _isLoading = false;
      });
      await widget.onLoaded?.call();
    } catch (e) {
```

다음과 같이 수정:

```dart
        _hasMoreItems = items.isNotEmpty;
        _isLoading = false;
      });
      if (!_isPullRefreshing) {
        await widget.onLoaded?.call();
      }
    } catch (e) {
```

- [ ] **Step 3: catch 블록의 `widget.onLoaded?.call()` 분기 처리**

아래 코드를 찾아 (catch 블록 내부):

```dart
      setState(() {
        _isLoading = false;
      });
      await widget.onLoaded?.call();

      if (!mounted) return;
      CommonSnackBar.show(
```

다음과 같이 수정:

```dart
      setState(() {
        _isLoading = false;
      });
      if (!_isPullRefreshing) {
        await widget.onLoaded?.call();
      }

      if (!mounted) return;
      CommonSnackBar.show(
```

- [ ] **Step 4: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/home_tab_screen.dart
```

Expected: No errors.

---

### Task 3: `_onPullRefresh()` 메서드 추가

**Files:**
- Modify: `lib/screens/home_tab_screen.dart` (`_loadInitialItems()` 끝과 `_loadMoreItems()` 사이)

- [ ] **Step 1: `_loadInitialItems()` 닫는 `}` 바로 다음, `_loadMoreItems()` 주석 바로 앞에 삽입**

아래 코드를 찾아:

```dart
  /// 추가 아이템 로드
  Future<void> _loadMoreItems() async {
```

그 **앞에** 다음 메서드를 삽입:

```dart
  /// 당겨서 새로고침 — RefreshIndicator onRefresh 콜백
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

  /// 추가 아이템 로드
  Future<void> _loadMoreItems() async {
```

- [ ] **Step 2: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/home_tab_screen.dart
```

Expected: No errors.

---

### Task 4: `_buildContent()` UI 변경

**Files:**
- Modify: `lib/screens/home_tab_screen.dart` (`_buildContent()` 메서드, 약 line 539-741)

#### Step 1: PageView physics 변경

- [ ] **PageView.builder의 `physics` 속성 수정**

아래 코드를 찾아:

```dart
              physics: _isBlurShown ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(),
```

다음과 같이 수정:

```dart
              physics: _isBlurShown ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(parent: BouncingScrollPhysics()),
```

#### Step 2: RefreshIndicator 추가

- [ ] **`return Stack(` 를 `return RefreshIndicator(` 로 감싸기**

아래 코드를 찾아:

```dart
    return Stack(
      children: [
        Positioned.fill(
```

다음과 같이 수정:

```dart
    return RefreshIndicator(
      onRefresh: _onPullRefresh,
      color: AppColors.primaryYellow,
      child: Stack(
        children: [
          Positioned.fill(
```

그리고 `_buildContent()` 메서드 끝부분에서 Stack을 닫는 `],` 와 `);` 를 찾아 RefreshIndicator의 닫는 `)` 를 추가:

```dart
      ],
    ), // Stack
  ); // RefreshIndicator
```

즉, 기존:

```dart
      ],
    );
  }
```

를 다음으로 수정:

```dart
        ],
      ), // Stack
    ); // RefreshIndicator
  }
```

> **주의**: RefreshIndicator 추가로 들여쓰기가 한 단계 증가함. `dart format`이 자동 정리해 줌.

#### Step 3: SafeArea 탭 GestureDetector 추가

- [ ] **notification icon Positioned 위젯 바로 앞에 SafeArea GestureDetector 삽입**

아래 코드를 찾아:

```dart
        // 알림 아이콘 및 메뉴 버튼 - 광고 슬롯에서는 숨김
        if (!_isBlurShown && !_isAdAtVirtualIndex(_currentVirtualIndex))
          Positioned(
            right: 16.w,
            top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 16.h : 8.h),
```

그 **앞에** 다음을 삽입:

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

        // 알림 아이콘 및 메뉴 버튼 - 광고 슬롯에서는 숨김
        if (!_isBlurShown && !_isAdAtVirtualIndex(_currentVirtualIndex))
          Positioned(
            right: 16.w,
            top: MediaQuery.of(context).padding.top + (Platform.isAndroid ? 16.h : 8.h),
```

---

### Task 5: 포맷팅 & 린트 최종 검사

**Files:**
- Modify: `lib/screens/home_tab_screen.dart` (자동 포맷)

- [ ] **Step 1: 코드 포맷팅 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/home_tab_screen.dart
```

Expected: `Formatted lib/screens/home_tab_screen.dart`

- [ ] **Step 2: 전체 린트 분석**

```bash
source ~/.zshrc && flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: 동작 확인 체크리스트**

수동으로 다음 시나리오를 확인:

| 시나리오 | 기대 동작 |
|---------|----------|
| page 0에서 아래로 당기기 | RefreshIndicator 스피너 표시 → 손 뗌 → 피드 새로고침 |
| 새로고침 중 기존 피드 | 기존 피드 유지 (스켈레톤 표시 안 됨) |
| page 3 이상에서 상태바 탭 | 400ms 애니메이션으로 page 0으로 이동 |
| page 0에서 상태바 탭 | 아무 동작 없음 |
| blur 활성화 상태 | pull refresh 불가 (NeverScrollableScrollPhysics 유지) |
| 새로고침 완료 | 피드 목록 최신 데이터로 교체, 스피너 사라짐 |
