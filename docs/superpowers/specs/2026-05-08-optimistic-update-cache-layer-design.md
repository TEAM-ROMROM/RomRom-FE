# Optimistic Update + Riverpod 캐시 레이어 도입 설계

- 일자: 2026-05-08
- 관련 이슈: [#835](https://github.com/TEAM-ROMROM/RomRom-FE/issues/835)
- 대상 도메인: 좋아요(Like), 회원 차단(MemberBlock), 알림 설정(NotificationSetting)

## 1. 배경 / 문제

토글성 액션(좋아요·차단·알림 on/off)이 현재 모두 "API 응답 대기 후 setState" 방식으로 구현되어 있다. 사용자가 버튼을 눌러도 네트워크 왕복(수백 ms~수 초) 동안 UI 변화가 없어 즉각 반응이 없다고 인지한다.

물품 상세 화면(`item_detail_description_screen.dart`)에만 인라인 Optimistic Update가 적용돼 있고, 같은 좋아요 상태가 home_feed / my_like_list에서 따로 관리되어 화면 간 동기화가 `Navigator.pop` 결과 전달이라는 수동 패턴에 의존한다.

## 2. 목표

1. 토글성 액션은 누른 즉시 UI 반영(Optimistic Update), 실패 시 자동 롤백 + 사용자 안내
2. 같은 데이터(좋아요 상태 등)가 여러 화면에 노출되어 있으면, 한 곳의 변경이 모든 화면에 자동 전파되어야 한다 (수동 pop result 동기화 제거)
3. Riverpod NotifierProvider 기반 캐시 레이어를 도입하되, 영향 범위는 본 이슈 3개 도메인으로 한정. 앱 전체 상태관리 마이그레이션은 별도 백로그.

## 3. 비목표

- 앱 전체 Riverpod 마이그레이션 (별도 이슈)
- Item 전체 필드 캐시화 (좋아요 관련 필드만 우선)
- Undo 토스트 / 5초 되돌리기 UI (별도 백로그)
- 새로운 외부 패키지 추가(freezed 등). 내부망 환경 제약상 기존 의존성만 사용.

## 4. 아키텍처

```
┌────────────────────────────────────┐
│ Widget (ConsumerWidget)            │
│   ref.watch(provider.select(...))  │  ← UI 표시
│   ref.read(provider.notifier).x()  │  ← 액션 트리거
└──────────────┬─────────────────────┘
               │
┌──────────────▼─────────────────────┐
│ Notifier (Riverpod)                │
│   - state: 캐시(Map/Set)           │
│   - Optimistic apply               │
│   - try → Repository, catch 롤백   │
│   - SnackBar via ScaffoldMessenger │
└──────────────┬─────────────────────┘
               │
┌──────────────▼─────────────────────┐
│ Repository                         │
│   - API 호출 + 도메인 변환         │
└──────────────┬─────────────────────┘
               │
┌──────────────▼─────────────────────┐
│ Api (lib/services/apis/*)          │  ← 기존 유지
└────────────────────────────────────┘
```

3계층(Widget · Notifier · Repository · Api)으로 분리한다. 위젯은 캐시만 구독하고 직접 Api를 호출하지 않는다.

### 4-1. SnackBar 전역 노출

기존 프로젝트 `lib/utils/common_utils.dart`에 정의된 `final GlobalKey<NavigatorState> navigatorKey`를 재사용한다. 이미 `MaterialApp.navigatorKey`로 연결되어 있다.

Notifier 실패 분기에서:
```dart
final ctx = navigatorKey.currentContext;
if (ctx != null) {
  CommonSnackBar.show(context: ctx, message: '...', type: SnackBarType.error);
}
```

`CommonSnackBar`는 Overlay 기반(`Overlay.of(context)`)이므로 `BuildContext`만 있으면 동작. `ScaffoldMessenger`/Scaffold 의존 없음.

## 5. 도메인별 설계

### 5-1. 좋아요(Like)

**상태 모델** — 신규 `lib/states/item_like_state.dart`

```dart
class ItemLikeState {
  final bool isLiked;
  final int likeCount;
  const ItemLikeState({required this.isLiked, required this.likeCount});

  ItemLikeState copyWith({bool? isLiked, int? likeCount}) =>
      ItemLikeState(
        isLiked: isLiked ?? this.isLiked,
        likeCount: likeCount ?? this.likeCount,
      );
}
```

**Repository** — 신규 `lib/repositories/item_repository.dart`

```dart
class ItemRepository {
  final ItemApi _api;
  ItemRepository(this._api);

  Future<ItemResponse> postLike(String itemId) =>
      _api.postLike(ItemRequest(itemId: itemId));

  Future<ItemResponse> getDetail(String itemId) =>
      _api.getItemDetail(ItemRequest(itemId: itemId));
}
```

**Repository Provider** — `lib/providers/item_like_provider.dart` 내부에 함께 정의

```dart
final itemRepositoryProvider = Provider<ItemRepository>(
  (ref) => ItemRepository(ItemApi()),
);
```

(테스트에서 `overrides: [itemRepositoryProvider.overrideWithValue(FakeItemRepository())]` 형태로 주입 가능)

**Notifier + Provider** — 신규 `lib/providers/item_like_provider.dart`

- 상태 타입: `Map<String itemId, ItemLikeState>`
- 메서드:
  - `void seed({required String itemId, required bool isLiked, required int likeCount})` — 페이지 로드 시 캐시 시드
  - `Future<void> toggle(String itemId)` — Optimistic 토글
- 내부 `Set<String> _inFlight`로 중복 호출 방지

**toggle 흐름**

```
1. _inFlight.contains(itemId) → return
2. _inFlight.add(itemId)
3. prev = state[itemId] ?? throw (시드 안된 경우 fail-fast)
4. optimistic = prev.copyWith(
     isLiked: !prev.isLiked,
     likeCount: prev.isLiked ? max(prev.likeCount-1, 0) : prev.likeCount+1,
   )
5. state = {...state, itemId: optimistic}
6. try:
     res = await repo.postLike(itemId)
     state = {...state, itemId: ItemLikeState(
       isLiked: res.isLiked == true,
       likeCount: res.item?.likeCount ?? optimistic.likeCount,
     )}
   catch (e):
     state = {...state, itemId: prev}
     final ctx = navigatorKey.currentContext;
     if (ctx != null) {
       CommonSnackBar.show(context: ctx, message: '좋아요 처리에 실패했어요', type: SnackBarType.error);
     }
   finally:
     _inFlight.remove(itemId)
```

**위젯 구독 패턴**

```dart
class HomeFeedItemWidget extends ConsumerStatefulWidget { ... }
class _HomeFeedItemWidgetState extends ConsumerState<HomeFeedItemWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = widget.item.itemUuid;
      if (id != null && id.isNotEmpty) {
        ref.read(itemLikeProvider.notifier).seed(
          itemId: id,
          isLiked: widget.item.isLiked,
          likeCount: widget.item.likeCount,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.item.itemUuid;
    final liked = ref.watch(itemLikeProvider.select((s) => s[id]?.isLiked ?? widget.item.isLiked));
    final count = ref.watch(itemLikeProvider.select((s) => s[id]?.likeCount ?? widget.item.likeCount));
    // ... onTap: ref.read(itemLikeProvider.notifier).toggle(id)
  }
}
```

`select`로 좁게 구독해서 다른 itemId 변경 시 리렌더 안 되도록.

**기존 `_isLiked`/`_likeCount`/`_isLiking` 로컬 state 모두 제거.** `widget.item.isLiked`는 시드 초기값으로만 사용.

`item_detail_description_screen.dart`의 `isLikedVN` ValueNotifier도 제거하고 동일 패턴으로 전환. pop result로 좋아요 상태 전달하던 로직(`Navigator.pop({...isLiked})` + `my_like_list_screen`의 result 분기)은 **불필요해지므로 삭제**. 단, my_like_list 화면에서 좋아요 취소 시 목록에서 제거하는 동작은 별도 처리:

- `my_like_list_screen`은 `itemLikeProvider`의 변화를 `ref.listen`으로 감시
- 자기 화면이 보유 중인 itemId가 `isLiked == false`로 바뀌면 `_items.removeWhere(...)`

### 5-2. 회원 차단(MemberBlock)

**상태 모델**: `Set<String memberId>` (차단된 회원 ID 집합)

**Repository** — 신규 `lib/repositories/member_block_repository.dart`

```dart
class MemberBlockRepository {
  final MemberApi _api;
  MemberBlockRepository(this._api);
  Future<bool> block(String memberId) => _api.blockMember(memberId);
  Future<bool> unblock(String memberId) => _api.unblockMember(memberId);
}
```

**Provider** — 신규 `lib/providers/member_block_provider.dart`

- 상태: `Set<String>` (차단된 ID)
- `void seed(Set<String> ids)` — 차단 목록 화면 진입 시 시드
- `Future<void> setBlocked(String memberId, bool block)` — Optimistic 토글

**토글 흐름**

```
prev = state.contains(id)
state = block ? {...state, id} : (state.toSet()..remove(id))
try:
  ok = await (block ? repo.block(id) : repo.unblock(id))
  if (!ok) throw Exception('서버 응답 실패')
catch:
  state = prev ? {...state, id} : (state.toSet()..remove(id))
  final ctx = navigatorKey.currentContext;
  if (ctx != null) {
    CommonSnackBar.show(context: ctx, message: block ? '차단에 실패했어요' : '차단 해제에 실패했어요', type: SnackBarType.error);
  }
```

**`block_management_screen` 변경**

기존 `_unblockedMemberIds` 로컬 Set 제거. 화면 진입 시 차단 목록 fetch → `seed` → `ref.watch`로 표시. 차단 해제 후에도 화면에 항목은 남기지만, 버튼 라벨/색상은 캐시 기반 즉시 반영(현재 동작 유지).

### 5-3. 알림 설정(NotificationSetting)

**상태 모델**: `Map<NotificationSettingType, bool>`

**Repository** — 신규 `lib/repositories/notification_setting_repository.dart`

```dart
class NotificationSettingRepository {
  final MemberApi _api;
  NotificationSettingRepository(this._api);
  Future<void> update({bool? isMarketingInfoAgreed, bool? isActivityNotificationAgreed, ...}) =>
      _api.updateNotificationSetting(...);
}
```

**Provider** — 신규 `lib/providers/notification_setting_provider.dart`

- 상태: `Map<NotificationSettingType, bool>`
- `void seed(Map<NotificationSettingType, bool>)` — 화면 진입 시 시드
- `Future<void> setEnabled(NotificationSettingType type, bool value)` — Optimistic + 권한 체크 분기

**권한 분기**: `value == true`로 켜는 경우 `NotificationPermissionService().isPermissionGranted()` 먼저 확인. 미허용이면 권한 요청 모달 띄우고 토글 변경하지 않음(Optimistic 적용 X). 허용 상태에서만 Optimistic + API 호출.

`notification_settings_screen` 기존 `_settings` Map / `_pendingRequests` Set 모두 제거하고 ConsumerStatefulWidget으로 전환.

## 6. 시드(seed) 정책

캐시는 lazy 시드. 즉, 화면이 데이터 노출 시점에 캐시에 값이 없으면 위젯에서 `seed`를 호출해 채운다. 시드 후 Notifier의 toggle만 호출되도록 한다.

이미 시드된 itemId에 대해 다시 시드 호출 시 **덮어쓰지 않는다**(서버 응답으로 보정된 최신 값을 보존). 단, 페이지 새로고침(pull-to-refresh) 등 명시적 갱신 시점에는 `forceSeed`로 덮어쓰기 가능하게 한다.

```dart
void seed({..., bool force = false}) {
  if (!force && state.containsKey(itemId)) return;
  state = {...state, itemId: ItemLikeState(...)};
}
```

## 7. 에러 처리

- API 실패 → 캐시 상태 prev로 롤백
- 사용자 안내: `navigatorKey.currentContext`를 통해 `CommonSnackBar.show(context: ctx, message: ..., type: SnackBarType.error)`
- 401(인증 만료) 등 공통 에러는 기존 `ApiClient` 인터셉터에서 처리. Notifier는 `try/catch` 후 도메인별 사용자 메시지만 띄움.
- 네트워크 미연결 등 식별 가능한 케이스는 도메인 메시지에 포함 가능(향후).

## 8. 테스트 전략

- **단위 테스트** (`test/providers/`): `ProviderContainer` + 모킹된 Repository로 Notifier 검증
  - 시나리오:
    1. seed 후 toggle → state 즉시 변경
    2. API 성공 → 서버 응답값으로 보정
    3. API 실패 → prev로 롤백, SnackBar 메서드 호출 여부는 별도 검증 어려움(전역 key 의존)
    4. in-flight 중 추가 toggle 호출 → 무시
- **위젯 통합 테스트**: 사용자 환경에서 별도 실행. PR에서 디바이스 검증 권장.
- 외부망 막힌 환경에서 `pub get` 불가하므로 의존성 추가 X. 기존 `flutter_test`만 사용.
- mocking 라이브러리 없이 **수동 테스트 더블**로 Repository 대체. Dart는 private 멤버(`_api`)에 대한 `implements`를 허용하지 않으므로 Repository 클래스를 그대로 `implements`하여 public 메서드만 오버라이드한다(컴파일러는 미선언 private 멤버 접근을 컴파일 타임 외부 호출이 없는 한 허용). ProviderScope의 `overrides`로 `itemRepositoryProvider`에 Fake 주입:

```dart
class FakeItemRepository implements ItemRepository {
  @override
  Future<ItemResponse> postLike(String itemId) async { ... }
}
```

## 9. 마이그레이션 / 분할 PR

스코프가 크므로 **PR 4개로 분할** 권장:

| PR | 내용 |
|----|------|
| 1 | 인프라(`scaffoldMessengerKey` + 도메인 1개의 Repository/Provider 골격) + 좋아요 마이그레이션 |
| 2 | 차단 마이그레이션 |
| 3 | 알림 설정 마이그레이션 |
| 4 | (옵션) `Navigator.pop` result 기반 좋아요 동기화 코드 제거, 모델 정리 |

각 PR은 자체적으로 머지 가능하도록 design한다(이전 PR 머지 안 돼도 동작 보존). PR 1 머지 후 좋아요는 캐시 기반으로 동작, PR 2~3은 다른 도메인이라 독립적.

## 10. 향후 작업(out of scope)

- Item 전체 필드 캐시화 (`itemRepositoryProvider`로 확장)
- Undo 토스트 (Gmail "삭제됨 [실행 취소]" 패턴)
- 앱 전체 Riverpod 마이그레이션
- AsyncValue 기반 로딩 상태 1급 시민화

---

## 의존성 / 호환성 메모

- `flutter_riverpod ^2.6.1` 이미 설치, `ProviderScope` `main.dart`에 셋업됨. 추가 패키지 불필요.
- `provider ^6.1.5`도 함께 사용 중이지만 본 작업에서 변경 없음.
- 기존 `ItemApi`/`MemberApi` 시그니처 변경 없음.
- `HomeFeedItem.isLiked` / `likeCount` 필드는 시드 용도로 유지. 추후 caching 진실원천화 후 deprecated 처리 가능.
