# 설계: 나의 등록된 물건 화면 — TripleToggleSwitch 3탭 전환

**날짜:** 2026-05-09  
**대상 파일:** `lib/screens/my_page/my_register_item_screen.dart`, `lib/enums/my_item_toggle_status.dart`

---

## 개요

현재 2탭(판매 중 / 교환 완료) 토글을 TripleToggleSwitch 기반 3탭(전체 / 등록 물건 / 교환 완료)으로 확장한다.  
API가 `itemStatus: null` 전체 조회를 미지원하므로 AVAILABLE + EXCHANGED를 병렬 호출 후 병합하는 A방식을 채택한다.

---

## 섹션 1: 상태 구조

### MyItemToggleStatus enum 확장

```dart
enum MyItemToggleStatus {
  all(id: 0, label: '전체', serverName: ''),
  selling(id: 1, label: '등록 물건', serverName: 'AVAILABLE'),
  completed(id: 2, label: '교환 완료', serverName: 'EXCHANGED');

  final int id;
  final String label;
  final String serverName;

  const MyItemToggleStatus({required this.id, required this.label, required this.serverName});

  static MyItemToggleStatus? fromServerName(String serverName) {
    try {
      return MyItemToggleStatus.values.firstWhere((s) => s.serverName == serverName);
    } catch (_) {
      return null;
    }
  }
}
```

### State 변수

기존 `_myItems`, `_currentPage`, `_hasMoreItems` 단일 리스트 제거 후 탭별 독립 변수로 교체:

```dart
final List<Item> _sellingItems = [];
final List<Item> _completedItems = [];

int _sellingPage = 0;
int _completedPage = 0;
bool _hasMoreSelling = true;
bool _hasMoreCompleted = true;

bool _isLoadingSelling = false;
bool _isLoadingCompleted = false;
bool _isLoadingMoreSelling = false;
bool _isLoadingMoreCompleted = false;

// 전체 탭 getter
List<Item> get _allItems => [..._sellingItems, ..._completedItems];
```

### AnimationController 변경

- `upperBound: 2.0` (3탭이므로)
- `CurvedAnimation` 제거, 컨트롤러를 animation으로 직접 사용 (chat_tab_screen 패턴)

---

## 섹션 2: 데이터 로딩 로직

### 초기 로딩

진입 시 selling + completed 두 API를 `Future.wait`으로 병렬 호출:

```dart
Future<void> _loadAllTabs({bool isRefresh = false}) async {
  await Future.wait([
    _loadTabItems(MyItemToggleStatus.selling, isRefresh: isRefresh),
    _loadTabItems(MyItemToggleStatus.completed, isRefresh: isRefresh),
  ]);
}
```

### 탭별 공통 로딩 함수

```dart
Future<void> _loadTabItems(MyItemToggleStatus tab, {bool isRefresh = false}) async {
  // tab == selling → _sellingItems, _sellingPage, _hasMoreSelling, _isLoadingSelling 분기
  // tab == completed → _completedItems, _completedPage, _hasMoreCompleted, _isLoadingCompleted 분기
  // tab == all → 호출하지 않음 (selling/completed 각각 호출)
}
```

### 탭 전환

이미 로드된 데이터 즉시 표시. 추가 API 호출 없음.

### 무한 스크롤

- `all` 탭: selling/completed 각각 `hasMore` 확인 후 필요한 쪽 페이징
- `selling`/`completed` 탭: 해당 탭만 페이징

### 새로고침

`_loadAllTabs(isRefresh: true)` 호출로 두 리스트 동시 리셋 + 병렬 재로딩.

---

## 섹션 3: UI 변경

### GlassHeaderDelegate toggle 교체

`GlassHeaderToggleBuilder.buildDefaultToggle` → `TripleToggleSwitch` 직접 전달:

```dart
toggle: TripleToggleSwitch(
  animation: _toggleAnimation,
  selectedIndex: _currentTabStatus.id,
  onFirstTap: () => _onToggleChanged(MyItemToggleStatus.all),
  onSecondTap: () => _onToggleChanged(MyItemToggleStatus.selling),
  onThirdTap: () => _onToggleChanged(MyItemToggleStatus.completed),
  firstText: '전체',
  secondText: '등록 물건',
  thirdText: '교환 완료',
),
```

### _buildItemSlivers() 변경

```dart
final displayItems = switch (_currentTabStatus) {
  MyItemToggleStatus.all => _allItems,
  MyItemToggleStatus.selling => _sellingItems,
  MyItemToggleStatus.completed => _completedItems,
};
```

로딩 상태 판별:
```dart
final isLoading = _isLoadingSelling || _isLoadingCompleted;
```

아이템 수 텍스트:
- `selling` → `${_sellingItems.length}/10개`
- `all` / `completed` → `${displayItems.length}개`

hasMore 판별:
- `all` → `_hasMoreSelling || _hasMoreCompleted`
- `selling` → `_hasMoreSelling`
- `completed` → `_hasMoreCompleted`

### _onToggleChanged() 변경

```dart
void _onToggleChanged(MyItemToggleStatus newStatus) {
  if (_currentTabStatus == newStatus) return;
  setState(() => _currentTabStatus = newStatus);
  _toggleAnimationController.animateTo(
    newStatus.id.toDouble(),
    duration: AppMotion.normal,
    curve: Curves.easeInOut,
  );
  // API 재호출 없음 — 이미 로드된 데이터 즉시 표시
}
```

---

## 변경 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `lib/enums/my_item_toggle_status.dart` | `all` 케이스 추가 |
| `lib/screens/my_page/my_register_item_screen.dart` | 전체 State/로딩/UI 로직 교체 |
