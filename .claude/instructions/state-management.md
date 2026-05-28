# 상태관리 가이드 (Riverpod 중앙화)

공유 도메인 상태는 **전부 Riverpod provider가 단일 소유**한다. 한 화면의 액션이 다른 화면이 보는 목록/상태에 영향을 줄 때, provider 구독으로 자동 전파되어 stale을 막는다.

이슈 #882에서 이벤트 버스(`AppEventBus`/`TradeCompletedEvent`)·`GlobalKey` 교차호출·중복 store·수동 목록 제거를 전면 폐기하고 Riverpod로 통일했다. **이벤트 버스를 다시 만들지 말 것.**

설계 참고: `docs/superpowers/specs/2026-05-28-event-bus-to-riverpod-migration-design.md`

## 왜 필요한가 — IndexedStack 함정

`MainScreen`은 `IndexedStack`으로 5개 탭을 렌더한다 (`lib/screens/main_screen.dart`).

- 탭 전환은 `_currentTabIndex`만 바꿀 뿐, 탭 위젯은 **계속 메모리에 살아있다**. `initState`는 다시 실행되지 않는다.
- 따라서 `initState`에서 1회만 데이터를 로드하는 탭은, 다른 탭/화면에서 일어난 변경을 **영원히 반영하지 못한다** (stale).
- 예) 채팅방에서 거래완료 → 내 물건이 `EXCHANGED`로 바뀌어도, 홈 탭이 로컬 `_myCards`를 `initState`에 1회 로드했다면 거래완료된 물건이 카드 덱에 계속 노출.

> 공유 데이터는 화면 로컬 `setState`에 가두지 말고 provider가 소유한다. 화면은 `ref.watch`로 구독한다.

## 표준 규칙 (요약 — 상세는 CLAUDE.md §UI 패턴 규칙 / 공유 상태 갱신)

- **규칙 0**: 공유 도메인 데이터는 provider 하나가 단일 소유. 화면은 `ref.watch`로 구독만.
- **규칙 1**: 4-레이어 표준 구조 (아래).
- **규칙 2**: 비동기 목록 = `AsyncNotifier`, optimistic 토글 = 동기 `Notifier` + `_inFlight`.
- **규칙 3**: mutation은 notifier 메서드로만. 목록은 서버 재조회(수동 제거 금지).
- **규칙 4**: 이벤트 버스·`GlobalKey` 교차호출 금지. 전파는 provider 구독으로.
- **규칙 5**: 화면은 `ConsumerStatefulWidget`/`ConsumerWidget`. `watch`=구독, `read(...).method()`=행위, `listen`=외부 변경 시 로컬 로드함수 재호출.

## 4-레이어 구조

| 레이어 | 파일 | 역할 |
|------|------|------|
| Repository | `lib/repositories/<domain>_repository.dart` | API(`ItemApi` 등) 래핑. UI 모름. |
| Repository Provider | `lib/providers/<domain>_repository_provider.dart` (또는 공용 `item_repository_provider.dart`) | plain `Provider`로 repository 주입 → 테스트 override 가능 |
| State | `lib/states/<domain>_state.dart` | `@immutable` 상태 모델. `copyWith`/`==`/`hashCode`/`toString` |
| Provider | `lib/providers/<domain>_provider.dart` | `AsyncNotifier`(목록) 또는 `Notifier`(토글) + Provider 선언 |

## 새 도메인 provider 추가 레시피 (4단계)

기준 예시: `myItemsProvider`(`lib/providers/my_items_provider.dart`), `MyItemsState`(`lib/states/my_items_state.dart`).

### 1. Repository — API 래핑
```dart
// lib/repositories/<domain>_repository.dart
class FooRepository {
  final FooApi _api;
  FooRepository(this._api);
  Future<List<Foo>> getFoos() async => (await _api.getFoos()).content ?? const [];
  Future<void> deleteFoo(String id) => _api.deleteFoo(id);
}
// lib/providers/foo_repository_provider.dart
final fooRepositoryProvider = Provider<FooRepository>((ref) => FooRepository(FooApi()));
```

### 2. State — 불변 모델
```dart
// lib/states/<domain>_state.dart
@immutable
class FooState {
  final List<Foo> items;
  const FooState({this.items = const []});
  FooState copyWith({List<Foo>? items}) => FooState(items: items ?? this.items);
  @override bool operator ==(Object o) => identical(this, o) ||
      o is FooState && runtimeType == o.runtimeType && listEquals(items, o.items);
  @override int get hashCode => Object.hashAll(items);
  @override String toString() => 'FooState(items: ${items.length})';
}
```

### 3. Provider — AsyncNotifier (비동기 목록 기준)
```dart
// lib/providers/<domain>_provider.dart
final fooProvider = AsyncNotifierProvider<FooNotifier, FooState>(FooNotifier.new);

class FooNotifier extends AsyncNotifier<FooState> {
  FooRepository get _repo => ref.read(fooRepositoryProvider);

  @override
  Future<FooState> build() => _fetch();

  Future<FooState> _fetch() async => FooState(items: await _repo.getFoos());

  /// mutation 후 서버 재조회. 실패 시 이전 데이터 유지(화면 blank 방지).
  Future<void> reload() async {
    final next = await AsyncValue.guard(_fetch);
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  Future<void> delete(String id) async {
    await _repo.deleteFoo(id);   // mutation은 notifier가 책임
    await reload();              // 서버 재조회 (수동 제거 금지)
  }
}
```
> optimistic 토글(좋아요·차단류)은 동기 `Notifier<T>` + `_inFlight` dedup + 즉시 반영 후 서버 응답으로 확정 + 실패 시 prev 롤백. 기준 예시: `lib/providers/item_like_provider.dart`.

### 4. 화면 — Consumer로 구독
```dart
class FooScreen extends ConsumerStatefulWidget { ... }
class _FooScreenState extends ConsumerState<FooScreen> {
  @override
  Widget build(BuildContext context) {
    // (A) 단순 표시: watch로 직접 파생
    final foos = ref.watch(fooProvider).value?.items ?? const <Foo>[];

    // (B) 자체 페이징/변환을 가진 화면: listen으로 외부 변경 시 로컬 재조회
    ref.listen(fooProvider, (prev, next) {
      if (mounted && next.hasValue) _loadLocal(isRefresh: true);
    });
    ...
  }
}
// mutation은 화면에서 직접 API 호출 금지 — notifier로:
//   await ref.read(fooProvider.notifier).delete(id);
```

## 현재 provider 현황

| Provider | 파일 | 종류 | 상태 |
|---|---|---|---|
| `myItemsProvider` | `providers/my_items_provider.dart` | AsyncNotifier | 내 물건 `{available, exchanged}` |
| `itemLikeProvider` | `providers/item_like_provider.dart` | Notifier(토글) | 좋아요 `Map<itemId, ItemLikeState>` |
| `memberBlockProvider` | `providers/member_block_provider.dart` | Notifier(토글) | 차단 `Set<memberId>` |
| `notificationSettingProvider` | `providers/notification_setting_provider.dart` | Notifier(토글) | 알림설정 `Map<type, bool>` |
| `itemRepositoryProvider` | `providers/item_repository_provider.dart` | Provider | ItemRepository 주입 (공용) |
| `coachMarkTriggerProvider` | `providers/coach_mark_trigger_provider.dart` | Notifier(bool) | 첫 등록 후 코치마크 일회성 신호 |

### myItems 구독/사용 현황 (내 물건 도메인)
| 화면 | 방식 |
|---|---|
| `home_tab_screen` | `ref.watch` → 카드덱·블러 파생 |
| `register_tab_screen` | `ref.listen` → `_loadMyItems(isRefresh:true)` |
| `my_register_item_screen` | `ref.listen` → `_loadAllTabs(isRefresh:true)` |
| `request_management_tab_screen` | `ref.listen` → `_loadInitialItems(isRefresh:true)` |
| `profile_exchange_section` | 본인 프로필일 때만 `ref.listen` |
| mutation: `register_input_form`(등록), `item_detail_description_screen`·`register_tab_screen`(삭제/상태변경), `chat_room_screen`(거래완료) | `ref.read(myItemsProvider.notifier).register/delete/changeStatus/reload` |

> Phase 2~5에서 memberProfile·notifications·chatRooms·tradeRequests provider가 추가되면 이 표를 갱신한다.
