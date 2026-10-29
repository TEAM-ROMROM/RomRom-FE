# 상태관리 Riverpod 중앙화 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 공유 도메인 상태(내 물건·프로필·채팅방·알림·요청)를 Riverpod provider로 중앙화하고, 이벤트 버스·GlobalKey 교차호출·중복 store·수동 목록 제거를 제거해 화면 간 상태 정합성을 보장한다.

**Architecture:** 4-레이어 표준(`repository` → `state` → `provider`(AsyncNotifier/Notifier) → Consumer 화면). 비동기 목록은 `AsyncNotifier`, optimistic 토글은 동기 `Notifier`. mutation은 화면이 아니라 notifier 메서드로만 수행하고 내부에서 서버 재조회. 화면은 `ref.watch`로 구독만 한다.

**Tech Stack:** Flutter, flutter_riverpod 2.6.1 (`AsyncNotifierProvider`, `ProviderContainer`), 기존 `ItemApi`/`ItemRepository` 패턴.

**참고 spec:** `docs/superpowers/specs/2026-05-28-event-bus-to-riverpod-migration-design.md`

**배포 전략:** Phase 단위 커밋(가능하면 PR 분리). Phase 1만으로 이번 stale 버그가 해결되어 단독 배포 가능. 내부망이라 빌드/린트/실기기 검증은 사용자 환경; 코드 수정 후 `dart format --line-length=120 .`만 실행. 단위 테스트(`flutter test`)도 사용자 환경에서 실행하되, 본 plan은 테스트 코드를 TDD 순서로 작성한다.

> **⚠️ 커밋 규칙:** 사용자 명시 허락 없이 `git commit`/`git add` 금지 (CLAUDE.md). 각 Task의 "Commit" 스텝은 **사용자가 커밋 컨벤션과 함께 승인했을 때만** 실행. 그 전까지는 diff를 사용자에게 보여주고 대기.

---

## File Structure

### Phase 1 — myItems 도메인 (이번 버그 직접 해결)

**생성:**
- `lib/states/my_items_state.dart` — `@immutable MyItemsState{available, exchanged}`
- `lib/providers/my_items_provider.dart` — `myItemsProvider` (`AsyncNotifierProvider`)
- `test/providers/my_items_provider_test.dart` — provider 단위 테스트

**수정:**
- `lib/repositories/item_repository.dart` — `getMyItems`/`postItem`/`deleteItem`/`updateItemStatus` 추가
- `lib/screens/home_tab_screen.dart` — Consumer 전환, `_myCards`/이벤트구독/GlobalKey 제거
- `lib/screens/register_tab_screen.dart` — Consumer 전환, 수동 removeWhere/GlobalKey 제거
- `lib/screens/my_page/my_register_item_screen.dart` — Consumer 전환, 이벤트구독 제거
- `lib/screens/request_management_tab_screen.dart` — Consumer 전환, 이벤트구독 제거
- `lib/widgets/profile/profile_exchange_section.dart` — Consumer 전환
- `lib/widgets/register_input_form.dart` — 등록을 notifier 경유로
- `lib/screens/item_detail_description_screen.dart` — 삭제/상태변경을 notifier 경유로
- `lib/screens/chat_room_screen.dart` — 거래완료 emit → notifier reload

**삭제 (Phase 1 끝):**
- `lib/services/app_event_bus.dart`, `lib/events/app_event.dart`, `lib/events/trade_completed_event.dart`

### Phase 2~6 — 동일 레시피 반복 (Phase 1 패턴 그대로)
- Phase 2 `memberProfileProvider` (프로필 8화면)
- Phase 3 `notificationsProvider` + mute 분열 정리
- Phase 4 `chatRoomsProvider` / `tradeRequestsProvider`
- Phase 5 기존 3 provider(좋아요·차단·알림설정) 위치/네이밍 규칙 정렬 (로직 불변)
- Phase 6 문서·규칙 박제 (CLAUDE.md / instructions / 메모리)

---

## Phase 1: myItems 도메인

### Task 1: ItemRepository에 물건 CRUD 메서드 추가

**Files:**
- Modify: `lib/repositories/item_repository.dart`

- [ ] **Step 1: repository 확장**

기존 `postLike`는 그대로 두고 메서드 추가. `getMyItems`는 status를 받아 `List<Item>` 반환(화면이 raw Item을 변환하므로 목록만 노출).

```dart
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

class ItemRepository {
  final ItemApi _api;

  ItemRepository(this._api);

  Future<ItemResponse> postLike(String itemId) => _api.postLike(ItemRequest(itemId: itemId));

  /// 내 물건 목록 (status별). 1페이지(기본 100개)만 단일 소스로 관리.
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    final res = await _api.getMyItems(
      ItemRequest(pageNumber: 0, pageSize: pageSize, itemStatus: status.serverName),
    );
    return res.itemPage?.content ?? const <Item>[];
  }

  Future<ItemResponse> postItem(ItemRequest request) => _api.postItem(request);

  Future<void> deleteItem(String itemId) => _api.deleteItem(itemId);

  Future<ItemResponse> updateItemStatus(ItemRequest request) => _api.updateItemStatus(request);
}
```

- [ ] **Step 2: 기존 Fake 깨짐 보완**

`test/providers/item_like_provider_test.dart:9`의 `FakeItemRepository implements ItemRepository`가
새 메서드 미구현으로 컴파일 에러난다. 해당 Fake에 stub 추가(좋아요 테스트엔 미사용이므로 throw 무방):

```dart
@override
Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async => const [];
@override
Future<ItemResponse> postItem(ItemRequest request) async => throw UnimplementedError();
@override
Future<void> deleteItem(String itemId) async => throw UnimplementedError();
@override
Future<ItemResponse> updateItemStatus(ItemRequest request) async => throw UnimplementedError();
```
import 추가: `package:romrom_fe/enums/item_status.dart`, `package:romrom_fe/models/apis/requests/item_request.dart`.

- [ ] **Step 3: 기존 테스트 회귀 확인**

Run: `flutter test test/providers/item_like_provider_test.dart`
Expected: PASS (기존 5 tests 그대로).

- [ ] **Step 4: 포맷**

Run: `dart format --line-length=120 lib/repositories/item_repository.dart test/providers/item_like_provider_test.dart`
Expected: 변경 없음 또는 정상 포맷.

- [ ] **Step 5: Commit (사용자 승인 시)**

```
git add lib/repositories/item_repository.dart test/providers/item_like_provider_test.dart
# 커밋 메시지는 사용자 컨벤션 따름
```

---

### Task 2: MyItemsState 상태 모델

**Files:**
- Create: `lib/states/my_items_state.dart`

- [ ] **Step 1: 상태 클래스 작성** (`item_like_state.dart` 패턴)

```dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

@immutable
class MyItemsState {
  final List<Item> available;  // 판매중
  final List<Item> exchanged;  // 교환완료

  const MyItemsState({this.available = const [], this.exchanged = const []});

  bool get hasAvailable => available.isNotEmpty;

  MyItemsState copyWith({List<Item>? available, List<Item>? exchanged}) =>
      MyItemsState(available: available ?? this.available, exchanged: exchanged ?? this.exchanged);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MyItemsState &&
          runtimeType == other.runtimeType &&
          listEquals(available, other.available) &&
          listEquals(exchanged, other.exchanged);

  @override
  int get hashCode => Object.hash(Object.hashAll(available), Object.hashAll(exchanged));
}
```

- [ ] **Step 2: 포맷 + Commit (승인 시)**

Run: `dart format --line-length=120 lib/states/my_items_state.dart`

---

### Task 3: myItemsProvider (AsyncNotifier) — TDD

**Files:**
- Create: `lib/providers/my_items_provider.dart`
- Create: `test/providers/my_items_provider_test.dart`

- [ ] **Step 1: 실패 테스트 작성** (`item_like_provider_test.dart` 패턴, `FakeItemRepository`로 override)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/item_like_provider.dart' show itemRepositoryProvider;
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';

class FakeItemRepository implements ItemRepository {
  List<Item> available = [];
  List<Item> exchanged = [];
  int deleteCount = 0;
  int postCount = 0;
  int statusCount = 0;

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async =>
      status == ItemStatus.available ? available : exchanged;

  @override
  Future<ItemResponse> postItem(ItemRequest request) async {
    postCount++;
    available = [...available, Item(itemId: 'new', itemName: request.itemName)];
    return ItemResponse(item: Item(itemId: 'new'), isFirstItemPosted: available.length == 1);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    deleteCount++;
    available = available.where((e) => e.itemId != itemId).toList();
  }

  @override
  Future<ItemResponse> updateItemStatus(ItemRequest request) async {
    statusCount++;
    return ItemResponse();
  }

  @override
  Future<ItemResponse> postLike(String itemId) async => ItemResponse();
}

void main() {
  group('myItemsProvider', () {
    late FakeItemRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeItemRepository();
      container = ProviderContainer(overrides: [itemRepositoryProvider.overrideWithValue(fake)]);
    });
    tearDown(() => container.dispose());

    test('build는 available/exchanged를 병렬 로드한다', () async {
      fake.available = [Item(itemId: 'a')];
      fake.exchanged = [Item(itemId: 'x')];
      final state = await container.read(myItemsProvider.future);
      expect(state.available.length, 1);
      expect(state.exchanged.length, 1);
    });

    test('register 후 available가 재조회된다', () async {
      await container.read(myItemsProvider.future);
      await container.read(myItemsProvider.notifier).register(ItemRequest(itemName: 'n'));
      expect(fake.postCount, 1);
      expect(container.read(myItemsProvider).value!.available.length, 1);
    });

    test('delete 후 목록에서 빠진다', () async {
      fake.available = [Item(itemId: 'a'), Item(itemId: 'b')];
      await container.read(myItemsProvider.future);
      await container.read(myItemsProvider.notifier).delete('a');
      expect(fake.deleteCount, 1);
      expect(container.read(myItemsProvider).value!.available.any((e) => e.itemId == 'a'), isFalse);
    });
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/providers/my_items_provider_test.dart`
Expected: FAIL — `my_items_provider.dart` 없음 / `myItemsProvider` 미정의.

- [ ] **Step 3: provider 구현**

`itemRepositoryProvider`는 기존 `item_like_provider.dart:12`에 이미 있으므로 재사용(중복 선언 금지).

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/providers/item_like_provider.dart' show itemRepositoryProvider;
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/states/my_items_state.dart';

final myItemsProvider = AsyncNotifierProvider<MyItemsNotifier, MyItemsState>(MyItemsNotifier.new);

class MyItemsNotifier extends AsyncNotifier<MyItemsState> {
  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  @override
  Future<MyItemsState> build() => _fetch();

  Future<MyItemsState> _fetch() async {
    final results = await Future.wait([
      _repo.getMyItems(ItemStatus.available),
      _repo.getMyItems(ItemStatus.exchanged),
    ]);
    return MyItemsState(available: results[0], exchanged: results[1]);
  }

  /// mutation 후 서버 재조회 (CLAUDE.md: 수동 제거 금지, 재조회만).
  Future<void> reload() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// 등록. 반환값으로 isFirstItemPosted를 전달(코치마크 게이트용).
  Future<bool> register(ItemRequest request) async {
    final res = await _repo.postItem(request);
    await reload();
    return res.isFirstItemPosted ?? false;
  }

  Future<void> delete(String itemId) async {
    await _repo.deleteItem(itemId);
    await reload();
  }

  Future<void> changeStatus(ItemRequest request) async {
    await _repo.updateItemStatus(request);
    await reload();
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/providers/my_items_provider_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: 포맷 + Commit (승인 시)**

Run: `dart format --line-length=120 lib/providers/my_items_provider.dart test/providers/my_items_provider_test.dart`

---

### Task 4: home_tab_screen Consumer 전환

**Files:**
- Modify: `lib/screens/home_tab_screen.dart`

- [ ] **Step 1: ConsumerStatefulWidget 전환**

`StatefulWidget`→`ConsumerStatefulWidget`, `State<HomeTabScreen>`→`ConsumerState<HomeTabScreen>`.
import 추가: `import 'package:flutter_riverpod/flutter_riverpod.dart';`,
`import 'package:romrom_fe/providers/my_items_provider.dart';`.

```dart
class HomeTabScreen extends ConsumerStatefulWidget {
  const HomeTabScreen({super.key, this.onLoaded});
  final Future<void> Function()? onLoaded;
  @override
  ConsumerState<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends ConsumerState<HomeTabScreen> {
```

- [ ] **Step 2: 로컬 myCards / 이벤트구독 / GlobalKey 제거**

제거 대상:
- 필드 `List<Item> _myCards = [];` (line 92)
- 필드 `StreamSubscription<TradeCompletedEvent>? _tradeCompletedSub;` (line 95)
- `initState`의 `_loadMyCards();`(line 101) 및 `_tradeCompletedSub = ...listen(...)`(line 105-107)
- `dispose`의 `_tradeCompletedSub?.cancel();` (line 112)
- 메서드 `_loadMyCards()` 전체 (line 471-495)
- `static final GlobalKey<State<HomeTabScreen>> globalKey` (line 52) — 교차호출 폐기
- import `app_event_bus.dart`, `events/trade_completed_event.dart` (line 20-21)

`_checkFirstMainScreen`(line 151)의 `_myCards.isEmpty` 기반 블러 계산은 build의 watch로 대체되므로 메서드 단순화(또는 제거). 블러 초기값 계산은 build에서 수행.

- [ ] **Step 3: build에서 provider watch + 블러/카드 파생**

`build` 최상단에서 watch. 로딩 중에는 스켈레톤, 데이터면 `available`로 카드·블러 결정.

```dart
@override
Widget build(BuildContext context) {
  final myItemsAsync = ref.watch(myItemsProvider);
  final myCards = myItemsAsync.value?.available ?? const <Item>[];
  // 최초 로드 전(value==null)에는 블러 판정 보류 → 깜빡임 방지
  final isBlurShown = myItemsAsync.hasValue && myCards.isEmpty;

  if (_isLoading) {
    return const HomeFeedSkeleton();
  }
  return _buildContent(myCards: myCards, isBlurShown: isBlurShown);
}
```

`_buildContent`/하위 위젯에서 쓰던 `_myCards`→`myCards`, `_isBlurShown`→`isBlurShown` 파라미터로 치환.
`cards: _myCards`(line 696)→`cards: myCards`. PageView physics(line 590)·알림아이콘 분기(line 629)·카드덱/등록버튼 분기(line 689,702) 모두 `isBlurShown` 사용.
필드 `bool _isBlurShown = false;`(line 77) 제거.

- [ ] **Step 4: 블러 화면 등록 버튼을 notifier 경유로**

블러 화면 등록 버튼(line 710-726)의 복귀 처리에서 `_loadMyCards()` 제거. 등록 자체는
`register_input_form`이 notifier로 수행(Task 8)하므로 여기선 코치마크만 판단.

```dart
onTap: () async {
  final result = await context.navigateTo<Map<String, dynamic>>(
    screen: ItemRegisterScreen(onClose: () => Navigator.pop(context)),
  );
  if (!mounted) return;
  if (result is Map<String, dynamic> && result['isFirstItemPosted'] == true) {
    showCoachMark();   // 목록 갱신은 provider가 자동 처리
  }
},
```

- [ ] **Step 5: 포맷 + 사용자 수동 검증**

Run: `dart format --line-length=120 lib/screens/home_tab_screen.dart`
사용자 검증: 등록→홈 즉시 블러 OFF, 삭제→블러 ON, 거래완료→카드 제외.

- [ ] **Step 6: Commit (승인 시)**

---

### Task 5: register_tab_screen Consumer 전환 (수동 제거·GlobalKey 폐기)

**Files:**
- Modify: `lib/screens/register_tab_screen.dart`

- [ ] **Step 1: ConsumerStatefulWidget 전환**

`StatefulWidget`→`ConsumerStatefulWidget`, `State`→`ConsumerState`. riverpod + provider import 추가.

- [ ] **Step 2: 로컬 목록·수동 제거·로드 제거**

- `_myItems`(line 56), `_loadMyItems`(line 122,168 호출부) 로컬 보관 제거 → build에서 watch.
- `_deleteItem`의 `_myItems.removeWhere`(line 786) 제거 → `ref.read(myItemsProvider.notifier).delete(item.itemId!)`.
- 상태변경(line 752 `updateItemStatus`) → `ref.read(myItemsProvider.notifier).changeStatus(req)`.
- FAB 등록 후(line 589) `_loadMyItems(isRefresh:true)` 제거(provider 자동).

- [ ] **Step 3: GlobalKey 교차호출 제거 (line 200-217)**

`MainScreen.globalKey.currentState.switchToTab(0)` + `HomeTabScreen.globalKey.currentState.showCoachMark()` 패턴 제거.
탭 전환은 `MainScreen`의 탭 인덱스 provider/콜백으로 대체(Phase 1 범위에선 최소: 탭 전환만 유지하되 `showCoachMark` GlobalKey 호출은 제거하고, 코치마크는 home_tab이 자체 게이트(`isFirstItemPosted`)로 표시).

> 탭 전환 자체를 provider로 옮기는 건 Phase 4(또는 별도)에서. Phase 1에선 `showCoachMark` GlobalKey 호출만 제거하고 홈의 코치마크 자체 판정에 위임.

- [ ] **Step 4: build에서 watch**

```dart
final myCards = ref.watch(myItemsProvider).value?.available ?? const <Item>[];
```
기존 `_myItems` 참조(line 319,327,541 등)를 `myCards`로 치환. FAB의 개수 제한 체크(line 541 별도 count 쿼리)는 `myCards.length`로 대체해 중복 API 제거.

- [ ] **Step 5: 포맷 + Commit (승인 시)**

Run: `dart format --line-length=120 lib/screens/register_tab_screen.dart`

---

### Task 6: my_register_item_screen Consumer 전환

**Files:**
- Modify: `lib/screens/my_page/my_register_item_screen.dart`

- [ ] **Step 1: ConsumerStatefulWidget 전환 + 이벤트구독 제거**

- `StreamSubscription _tradeCompletedSub`(line 68), initState listen(line 81-83), dispose cancel(line 88) 제거.
- import `app_event_bus`/`trade_completed_event`(line 18-19) 제거.

- [ ] **Step 2: 목록 파생**

1페이지 `_sellingItems`/`_completedItems` → `ref.watch(myItemsProvider)`의 `available`/`exchanged`.
추가 페이지(무한스크롤)는 로컬 누적 유지(YAGNI). 상세 복귀(line 508 `result==true`)는
`ref.read(myItemsProvider.notifier).reload()`로 대체.

```dart
final my = ref.watch(myItemsProvider).value;
final selling = my?.available ?? const <Item>[];
final completed = my?.exchanged ?? const <Item>[];
```
주소 변환(`resolveAndCacheAddress`)은 화면 책임 유지.

- [ ] **Step 3: 포맷 + Commit (승인 시)**

---

### Task 7: request_management + profile_exchange_section Consumer 전환

**Files:**
- Modify: `lib/screens/request_management_tab_screen.dart`
- Modify: `lib/widgets/profile/profile_exchange_section.dart`

- [ ] **Step 1: request_management 전환**

- `_tradeCompletedSub`(line 88), listen(line 104), dispose cancel(line 461) 제거.
- import 이벤트 2종 제거.
- `_itemCards`의 1페이지 소스를 `ref.watch(myItemsProvider).value?.available`에서 받아
  `_convertToRequestManagementItemCard`로 변환. 받은/보낸 요청 연쇄 로드는 화면 책임 유지.
- ConsumerStatefulWidget 전환.

- [ ] **Step 2: profile_exchange_section 전환**

`_items`(line 27) 로컬 1회 로드(line 52-53) → `ref.watch(myItemsProvider)`. 단 타인 프로필은
`getMemberItems`(line 48)로 별도 — 본인 프로필일 때만 myItemsProvider 사용, 타인은 기존 유지.
ConsumerStatefulWidget/ConsumerWidget 전환.

- [ ] **Step 3: 포맷 + Commit (승인 시)**

---

### Task 8: mutation 진입점을 notifier 경유로 (register_input_form / item_detail / chat_room)

**Files:**
- Modify: `lib/widgets/register_input_form.dart`
- Modify: `lib/screens/item_detail_description_screen.dart`
- Modify: `lib/screens/chat_room_screen.dart`

- [ ] **Step 1: register_input_form 등록을 notifier로**

`register_input_form`을 `ConsumerStatefulWidget`로(또는 `ref` 접근 가능 구조). 등록 모드(line 869
`ItemApi().postItem`) 직접 호출 → `ref.read(myItemsProvider.notifier).register(itemRequest)`로 교체.
`isFirstItemPosted` 반환값을 기존 `Navigator.pop(resultData)`(line 900) 결과에 그대로 사용.
UserInfo 저장 로직(line 879-890)은 유지. 직접 `postItem` 제거로 provider가 단일 경로가 됨.

- [ ] **Step 2: item_detail 삭제/상태변경을 notifier로**

- `_deleteItem`(line 300 `itemApi.deleteItem`) → `ref.read(myItemsProvider.notifier).delete(item.itemId!)`.
- 상태변경(line 270 `updateItemStatus`) → `ref.read(myItemsProvider.notifier).changeStatus(request)`.
- ConsumerStatefulWidget 전환. 기존 `Navigator.pop(true)` 흐름 유지(호출 화면 호환).

- [ ] **Step 3: chat_room 거래완료 emit → reload**

- import `app_event_bus`/`trade_completed_event`(line 25-26) 제거.
- line 361, 837의 `AppEventBus.instance.emit(const TradeCompletedEvent())` →
  `ref.read(myItemsProvider.notifier).reload()`.
- ConsumerStatefulWidget 전환(이미 WidgetsBindingObserver mixin 있음 — Consumer 병행 가능).
- 리뷰 네비게이션 등 나머지 로직 불변.

- [ ] **Step 4: 포맷 + Commit (승인 시)**

---

### Task 9: 이벤트 버스 인프라 삭제 + 전역 검증

**Files:**
- Delete: `lib/services/app_event_bus.dart`, `lib/events/app_event.dart`, `lib/events/trade_completed_event.dart`

- [ ] **Step 1: 잔존 참조 확인**

Run (참조 0 확인): `grep -rn "AppEventBus\|TradeCompletedEvent\|app_event_bus\|events/trade_completed" lib/`
Expected: 매치 없음 (Task 4·6·7·8에서 전부 제거됨).

- [ ] **Step 2: 파일 삭제**

```
git rm lib/services/app_event_bus.dart lib/events/app_event.dart lib/events/trade_completed_event.dart
```
(`lib/events/`가 비면 폴더도 제거.)

- [ ] **Step 3: 전역 분석 (사용자 환경)**

사용자 환경: `flutter analyze` — 에러 0. GlobalKey 제거로 인한 미사용 import/심볼 정리.

- [ ] **Step 4: 포맷 + Commit (승인 시)**

Run: `dart format --line-length=120 .`

---

## Phase 2: memberProfileProvider (프로필 8화면)

### Task 10~: Phase 1 레시피 그대로 반복

**패턴 (Task 1~3과 동일 구조, 도메인만 교체):**
- `lib/repositories/member_repository.dart` 생성 — `getMemberInfo`/`updateMemberProfile` 래핑
- `lib/states/member_profile_state.dart` — `{nickname, profileUrl, location, accountStatus, isFirstItemPosted, ...}`
- `lib/providers/member_profile_provider.dart` — `AsyncNotifierProvider`, `reload`/`updateProfile`
- `test/providers/member_profile_provider_test.dart` — build/updateProfile/실패 롤백 (Task 3 테스트 패턴)
- 구독 전환: `my_page_tab_screen`, `main_screen`, `chat_room_screen`, `notification_screen`, `search_range`, `member_profile_screen`, `my_category_settings`, `notification_settings_screen`
  — 각 화면 `getMemberInfo` 직접 호출 → `ref.watch(memberProfileProvider)`.
- 프로필 편집(`member_profile_screen.dart:153`) → `ref.read(memberProfileProvider.notifier).updateProfile(...)`.
- 코치마크 게이트(`isFirstItemPosted`)를 이 provider에서 노출 → home_tab 코치마크 GlobalKey 의존 완전 제거.

> 각 화면 변경은 Task 4 스텝(Consumer 전환 → 로컬 제거 → build watch → 포맷 → 검증)을 그대로 따른다.

---

## Phase 3: notificationsProvider + mute 분열 정리

### Task: Phase 1 레시피 반복

- `lib/repositories/notification_repository.dart` (또는 기존 `notification_setting_repository.dart` 확장)
- `lib/states/notification_state.dart` — `{activity, romrom, unreadCount}`
- `lib/providers/notifications_provider.dart` — `AsyncNotifierProvider`, `reload`/`markAllRead`
- 구독: `notification_screen`(목록), `home_tab`(뱃지 `_hasUnreadNotification` → watch).
- **mute 분열 해소**: `notification_screen.dart:60`의 로컬 `_mutedNotificationTypes` 제거 →
  기존 `notificationSettingProvider`(이미 있음) 단일 소스로 일원화. 두 화면이 같은 provider 구독.
- 알림 읽음(`notification_screen.dart:112` dispose 내 `markAllRead`) → notifier 메서드로, 뱃지 자동 갱신.

---

## Phase 4: chatRoomsProvider / tradeRequestsProvider

### Task: Phase 1 레시피 반복

- `chatRoomsProvider`: `chat_tab_screen._chatRoomsDetail` → provider. WS 수신/재연결 refresh 시
  notifier 갱신. 거래완료 reload와 정합.
- `tradeRequestsProvider`: `request_management`의 `_receivedRequests`/`_sentRequests` → provider.
- (선택) `MainScreen` 탭 인덱스를 provider로 → register_tab의 탭 전환 GlobalKey 완전 제거.

---

## Phase 5: 기존 3 provider 규칙 정렬 (로직 불변)

### Task: 위치/네이밍 통일

- `itemLikeProvider`/`memberBlockProvider`/`notificationSettingProvider`는 규칙2 "optimistic 토글=동기 Notifier"에 이미 부합 → **로직 변경 없음**.
- `itemRepositoryProvider`가 `item_like_provider.dart`에 선언된 것을 공용 위치로 이동 고려
  (`lib/providers/repository_providers.dart` 등). 이동 시 import 경로 일괄 수정.
- 각 provider 파일 헤더 주석에 규칙2 분류(토글/목록) 명시.

---

## Phase 6: 문서·규칙 박제

### Task: CLAUDE.md / instructions / 메모리 갱신

- **CLAUDE.md** "공유 상태 갱신" 섹션: 이벤트 버스 서술 전면 삭제 → spec §2 규칙 0~5로 교체.
  4-레이어 구조, Notifier 선택 기준 표, mutation=notifier 메서드, 이벤트버스·GlobalKey 금지 명시.
- **`.claude/instructions/state-management.md`**: "새 도메인 provider 추가 4단계 레시피"로 재작성
  (repository → state → provider(+test) → 화면 Consumer 구독).
- **메모리 `indexedstack-stale-state.md`**: TradeEventBus 언급 → myItemsProvider 중앙화로 갱신.
- 문서 변경은 앱 동작 무관(메타성) → 빌드/QA 불필요(CLAUDE.md Phase 5 예외).

---

## 검증 (Phase 1 기준 — 사용자 수동)

1. 신규 회원: 홈 블러 → 등록 → 즉시 블러 OFF + 카드 1개 (재시작 불필요)
2. 기존 회원 0개: 등록 → 홈 카드 노출
3. 마지막 물건 삭제 → 홈 블러 복귀
4. 마이페이지 직접 교환완료 → 홈 카드 덱 + 요청관리에서 제외
5. 채팅 거래완료 → 홈/내물건/요청관리 동시 갱신 (회귀 없음)
6. register_tab 거래완료 후 stale 해소 (기존 미구독 버그)
7. 코치마크: 첫 물건 등록 시에만 표시 (GlobalKey 제거 후에도 동작)
