# TripleToggleSwitch 3탭 전환 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `나의 등록된 물건` 화면의 2탭 토글(판매 중 / 교환 완료)을 `TripleToggleSwitch` 3탭(전체 / 등록 물건 / 교환 완료)으로 교체한다.

**Architecture:** API가 `itemStatus: null` 전체 조회를 미지원하므로 AVAILABLE + EXCHANGED 두 API를 `Future.wait`으로 병렬 호출 후 클라이언트에서 병합한다. 탭 전환 시에는 이미 로드된 데이터를 즉시 표시하며 추가 API 호출하지 않는다.

**Tech Stack:** Flutter, AnimationController(upperBound: 2.0), TripleToggleSwitch 위젯

---

### Task 1: MyItemToggleStatus enum 확장

**Files:**
- Modify: `lib/enums/my_item_toggle_status.dart`

- [ ] **Step 1: `all` 케이스 추가 및 `selling` 라벨 변경**

`lib/enums/my_item_toggle_status.dart` 전체를 다음으로 교체:

```dart
/// 내 물건 탭 토글 상태 enum
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

- [ ] **Step 2: 포맷 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/enums/my_item_toggle_status.dart
```

---

### Task 2: AnimationController 변경 + State 변수 교체

**Files:**
- Modify: `lib/screens/my_page/my_register_item_screen.dart`

현재 코드의 문제:
- `AnimationController`: `upperBound` 미설정(기본 1.0), `CurvedAnimation` 래핑 → 3탭에서 0~2.0 범위 필요
- State 변수: `_myItems`, `_currentPage`, `_hasMoreItems`, `_isLoading`, `_isLoadingMore` 단일 리스트 → 탭별 독립 변수 필요
- 초기 탭: `MyItemToggleStatus.selling` → `MyItemToggleStatus.all`

- [ ] **Step 1: State 필드 선언부 교체**

기존 코드(38~52줄 범위):
```dart
  bool _isScrolled = false; //
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMoreItems = true;
  Timer? _scrollTimer;

  // 내 물품 데이터
  final List<Item> _myItems = [];
  int _currentPage = 0;
  final int _pageSize = 20;

  // 토글 상태
  MyItemToggleStatus _currentTabStatus = MyItemToggleStatus.selling;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;
```

교체 후:
```dart
  bool _isScrolled = false;
  Timer? _scrollTimer;

  // 탭별 데이터
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

  final int _pageSize = 20;

  // 전체 탭 getter
  List<Item> get _allItems => [..._sellingItems, ..._completedItems];

  // 토글 상태
  MyItemToggleStatus _currentTabStatus = MyItemToggleStatus.all;
  late AnimationController _toggleAnimationController;
  late Animation<double> _toggleAnimation;
```

- [ ] **Step 2: `initState` AnimationController 초기화 변경**

기존:
```dart
    _toggleAnimationController = AnimationController(duration: AppMotion.normal, vsync: this);
    _toggleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _toggleAnimationController, curve: AppMotion.standard));

    _loadMyItems();
```

교체 후:
```dart
    _toggleAnimationController = AnimationController(
      duration: AppMotion.normal,
      vsync: this,
      upperBound: 2.0,
    );
    _toggleAnimation = _toggleAnimationController;

    _loadAllTabs();
```

---

### Task 3: 데이터 로딩 로직 교체

**Files:**
- Modify: `lib/screens/my_page/my_register_item_screen.dart`

기존 `_loadMyItems()`, `_loadMoreItems()` 제거 후 탭별 공통 로딩 함수로 교체.

- [ ] **Step 1: `_loadMyItems()` 및 `_loadMoreItems()` 전체 제거**

`my_register_item_screen.dart`에서 `_loadMyItems` 메서드(79~133줄)와 `_loadMoreItems` 메서드(136~175줄)를 모두 제거한다.

- [ ] **Step 2: `_loadTabItems()` + `_loadAllTabs()` 추가**

`_scrollListener()` 메서드 바로 앞에 다음 두 메서드를 삽입:

```dart
  /// selling/completed 두 탭을 병렬 로드
  Future<void> _loadAllTabs({bool isRefresh = false}) async {
    await Future.wait([
      _loadTabItems(MyItemToggleStatus.selling, isRefresh: isRefresh),
      _loadTabItems(MyItemToggleStatus.completed, isRefresh: isRefresh),
    ]);
  }

  /// 탭별 공통 로딩 함수
  Future<void> _loadTabItems(MyItemToggleStatus tab, {bool isRefresh = false}) async {
    assert(tab != MyItemToggleStatus.all, '_loadTabItems은 all 탭을 직접 호출하지 않음');

    final isSelling = tab == MyItemToggleStatus.selling;
    final isLoading = isSelling ? _isLoadingSelling : _isLoadingCompleted;
    final isLoadingMore = isSelling ? _isLoadingMoreSelling : _isLoadingMoreCompleted;
    final hasMore = isSelling ? _hasMoreSelling : _hasMoreCompleted;
    final items = isSelling ? _sellingItems : _completedItems;

    if (!isRefresh && isLoading && items.isNotEmpty) return;
    if (!isRefresh && isLoadingMore) return;

    setState(() {
      if (isRefresh) {
        if (isSelling) {
          _sellingPage = 0;
          _hasMoreSelling = true;
          _sellingItems.clear();
          _isLoadingSelling = true;
        } else {
          _completedPage = 0;
          _hasMoreCompleted = true;
          _completedItems.clear();
          _isLoadingCompleted = true;
        }
      } else {
        if (isSelling) {
          _isLoadingSelling = true;
        } else {
          _isLoadingCompleted = true;
        }
      }
    });

    try {
      final itemApi = ItemApi();
      final currentPage = isSelling ? _sellingPage : _completedPage;
      final request = ItemRequest(
        pageNumber: isRefresh ? 0 : currentPage,
        pageSize: _pageSize,
        itemStatus: tab.serverName,
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemPage?.content ?? [];

      if (mounted) {
        setState(() {
          if (isSelling) {
            _sellingItems.addAll(newItems);
            _hasMoreSelling = newItems.length == _pageSize;
            _isLoadingSelling = false;
          } else {
            _completedItems.addAll(newItems);
            _hasMoreCompleted = newItems.length == _pageSize;
            _isLoadingCompleted = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isSelling) {
            _isLoadingSelling = false;
          } else {
            _isLoadingCompleted = false;
          }
        });

        CommonSnackBar.show(
          context: context,
          message: '물품 목록 로드 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }

  /// 더 많은 물품 로드 (페이징)
  Future<void> _loadMoreItems() async {
    switch (_currentTabStatus) {
      case MyItemToggleStatus.all:
        if (_hasMoreSelling && !_isLoadingMoreSelling) {
          await _loadMoreTab(MyItemToggleStatus.selling);
        }
        if (_hasMoreCompleted && !_isLoadingMoreCompleted) {
          await _loadMoreTab(MyItemToggleStatus.completed);
        }
      case MyItemToggleStatus.selling:
        if (_hasMoreSelling && !_isLoadingMoreSelling) {
          await _loadMoreTab(MyItemToggleStatus.selling);
        }
      case MyItemToggleStatus.completed:
        if (_hasMoreCompleted && !_isLoadingMoreCompleted) {
          await _loadMoreTab(MyItemToggleStatus.completed);
        }
    }
  }

  Future<void> _loadMoreTab(MyItemToggleStatus tab) async {
    final isSelling = tab == MyItemToggleStatus.selling;

    setState(() {
      if (isSelling) _isLoadingMoreSelling = true;
      else _isLoadingMoreCompleted = true;
    });

    try {
      final itemApi = ItemApi();
      final nextPage = (isSelling ? _sellingPage : _completedPage) + 1;
      final request = ItemRequest(
        pageNumber: nextPage,
        pageSize: _pageSize,
        itemStatus: tab.serverName,
      );

      final response = await itemApi.getMyItems(request);
      final newItems = response.itemPage?.content ?? [];

      if (mounted) {
        setState(() {
          if (isSelling) {
            _sellingItems.addAll(newItems);
            _sellingPage = nextPage;
            _hasMoreSelling = newItems.length == _pageSize;
            _isLoadingMoreSelling = false;
          } else {
            _completedItems.addAll(newItems);
            _completedPage = nextPage;
            _hasMoreCompleted = newItems.length == _pageSize;
            _isLoadingMoreCompleted = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isSelling) _isLoadingMoreSelling = false;
          else _isLoadingMoreCompleted = false;
        });

        CommonSnackBar.show(
          context: context,
          message: '추가 물품 로드 실패: ${ErrorUtils.getErrorMessage(e)}',
          type: SnackBarType.error,
        );
      }
    }
  }
```

- [ ] **Step 3: `RefreshIndicator.onRefresh` 콜백 수정**

기존:
```dart
                onRefresh: () async {
                  try {
                    await _loadMyItems(isRefresh: true);
                  } finally {
```

교체 후:
```dart
                onRefresh: () async {
                  try {
                    await _loadAllTabs(isRefresh: true);
                  } finally {
```

- [ ] **Step 4: `_navigateToItemDetail` 결과 처리 수정**

기존:
```dart
    if (result == true) {
      _loadMyItems(isRefresh: true);
    }
```

교체 후:
```dart
    if (result == true) {
      _loadAllTabs(isRefresh: true);
    }
```

---

### Task 4: UI 변경 — 토글 + 아이템 슬리버

**Files:**
- Modify: `lib/screens/my_page/my_register_item_screen.dart`

- [ ] **Step 1: 임포트 추가**

파일 상단 임포트 목록에 다음 추가:
```dart
import 'package:romrom_fe/widgets/common/triple_toggle_switch.dart';
```

- [ ] **Step 2: GlassHeaderDelegate toggle 교체**

기존:
```dart
                        toggle: GlassHeaderToggleBuilder.buildDefaultToggle(
                          animation: _toggleAnimation,
                          isRightSelected: _currentTabStatus == MyItemToggleStatus.completed,
                          onLeftTap: () => _onToggleChanged(MyItemToggleStatus.selling),
                          onRightTap: () => _onToggleChanged(MyItemToggleStatus.completed),
                          leftText: '판매 중',
                          rightText: '교환 완료',
                        ),
```

교체 후:
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

- [ ] **Step 3: `_buildItemSlivers()` 전체 교체**

기존 `_buildItemSlivers()` 메서드 전체를 다음으로 교체:

```dart
  List<Widget> _buildItemSlivers() {
    final isLoading = _isLoadingSelling || _isLoadingCompleted;

    if (isLoading && _sellingItems.isEmpty && _completedItems.isEmpty) {
      return const [RegisterTabSkeletonSliver()];
    }

    final displayItems = switch (_currentTabStatus) {
      MyItemToggleStatus.all => _allItems,
      MyItemToggleStatus.selling => _sellingItems,
      MyItemToggleStatus.completed => _completedItems,
    };

    if (displayItems.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(),
        ),
      ];
    }

    final hasMore = switch (_currentTabStatus) {
      MyItemToggleStatus.all => _hasMoreSelling || _hasMoreCompleted,
      MyItemToggleStatus.selling => _hasMoreSelling,
      MyItemToggleStatus.completed => _hasMoreCompleted,
    };

    final itemCountText = _currentTabStatus == MyItemToggleStatus.selling
        ? '${displayItems.length}/10개'
        : '${displayItems.length}개';

    final itemCountWithSeparators = displayItems.length * 2 - 1;

    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.only(right: 24.w, bottom: 16.h),
          child: Text(
            itemCountText,
            textAlign: TextAlign.right,
            style: CustomTextStyles.p1.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w400),
          ),
        ),
      ),
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index.isOdd) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0.w),
              child: Divider(thickness: 1.5, color: AppColors.opacity10White, height: 32.h),
            );
          }
          final item = displayItems[index ~/ 2];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.0.w),
            child: _buildItemTile(item, index ~/ 2),
          );
        }, childCount: itemCountWithSeparators),
      ),
      if (hasMore)
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: const Center(child: CommonLoadingIndicator()),
          ),
        ),
      SliverToBoxAdapter(child: SizedBox(height: 24.h)),
    ];
  }
```

- [ ] **Step 4: `_onToggleChanged()` 교체**

기존:
```dart
  void _onToggleChanged(MyItemToggleStatus newStatus) {
    if (_currentTabStatus != newStatus) {
      if (newStatus == MyItemToggleStatus.completed) {
        _toggleAnimationController.forward();
      } else {
        _toggleAnimationController.reverse();
      }

      setState(() {
        _currentTabStatus = newStatus;
      });

      _loadMyItems(isRefresh: true);
    }
  }
```

교체 후:
```dart
  void _onToggleChanged(MyItemToggleStatus newStatus) {
    if (_currentTabStatus == newStatus) return;
    setState(() => _currentTabStatus = newStatus);
    _toggleAnimationController.animateTo(
      newStatus.id.toDouble(),
      duration: AppMotion.normal,
      curve: Curves.easeInOut,
    );
  }
```

---

### Task 5: 포맷 및 린트 검증

**Files:**
- `lib/enums/my_item_toggle_status.dart`
- `lib/screens/my_page/my_register_item_screen.dart`

- [ ] **Step 1: 전체 포맷 적용**

```bash
source ~/.zshrc && dart format --line-length=120 .
```

- [ ] **Step 2: 린트 분석 실행 및 에러 수정**

```bash
source ~/.zshrc && flutter analyze
```

Expected: `No issues found!` 또는 info 레벨만 존재. error/warning 발생 시 수정 후 재실행.

---

## Self-Review 체크리스트

### Spec Coverage
| Spec 요구사항 | 커버하는 Task |
|---|---|
| `all` enum 케이스 추가, `selling` 라벨 `'등록 물건'`으로 변경 | Task 1 |
| `AnimationController upperBound: 2.0`, CurvedAnimation 제거 | Task 2 |
| 탭별 독립 State 변수 (`_sellingItems`, `_completedItems` 등) | Task 2 |
| `Future.wait` 병렬 초기 로딩 | Task 3 |
| `all` 탭 무한스크롤: 양쪽 hasMore 확인 | Task 3 |
| 새로고침 시 `_loadAllTabs(isRefresh: true)` | Task 3 |
| TripleToggleSwitch 사용, 3탭 텍스트 | Task 4 |
| 탭 전환 시 API 재호출 없음 | Task 4 |
| `displayItems` switch, 아이템 수 텍스트, hasMore switch | Task 4 |

### 주요 타입/메서드 일관성
- `_loadAllTabs` → Task 2 initState, Task 3 refresh, Task 3 navigate result에서 호출 ✓
- `_loadTabItems(MyItemToggleStatus.selling/completed)` → Task 3 `_loadAllTabs` 내부에서만 호출 ✓
- `_loadMoreItems()` → `_scrollListener`에서 호출 (기존 코드 유지됨) ✓
- `_toggleAnimation` → `Animation<double>` 타입 유지 (`_toggleAnimationController` 직접 할당) ✓
- `selectedIndex: _currentTabStatus.id` → `all=0, selling=1, completed=2` ✓
