# 상태관리 Riverpod 중앙화 — 전면 재설계 & 규칙 명세

- 작성일: 2026-05-28
- 성격: 별도 이슈로 등록 후 전체 수정·배포 (대규모 리팩토링)
- 동기: 공유 도메인 상태가 13+ 화면에 로컬 `setState`로 흩어져 정합성이 곳곳에서 깨짐.
  규칙이 없어 mutation 전파 누락·중복 store·GlobalKey 교차호출·수동 목록 제거가 누적됨.
- 목표: 모든 공유 도메인을 Riverpod 중앙 관리로 통일하고, **CLAUDE.md에 박을 표준 규칙**을 확정.
- 선행: `f0b66a9`(AppEventBus 도입), `582c3e7`(홈 등록 reload) — 이번 작업으로 이벤트 버스는 폐기.

---

## 1. 전수조사 요약 (현황)

### 인프라
- `MainScreen`은 `IndexedStack` (`main_screen.dart:145`) — 5개 탭 항상 생존. 탭 전환이
  `initState`를 재실행하지 않음 → 모든 stale 버그의 공통 뿌리.
- 이벤트 버스: `AppEventBus` 싱글톤 1개, 이벤트 타입 `TradeCompletedEvent` 1종.

### 공유 도메인이 화면마다 중복 보관됨

| 도메인 | 보관 화면 (필드) | 로드 API | 전파 |
|---|---|---|---|
| **내 물건 목록** | `register_tab`(`_myItems`), `home_tab`(`_myCards`), `my_register_item`(`_sellingItems`/`_completedItems`), `request_management`(`_itemCards`), `profile_exchange_section`(`_items`), `trade_request`(`_myItems`) | `getMyItems` | 일부만 `TradeCompletedEvent` 구독, register_tab·profile_exchange는 미구독 |
| **회원 프로필** | 8화면이 `getMemberInfo` 각자 호출 (main, chat_room, notification, search_range, member_profile, my_page_tab, my_category_settings, notification_settings) | `getMemberInfo` | provider 없음, 전부 독립 |
| **채팅방 목록** | `chat_tab`(`_chatRoomsDetail`) | `getChatRooms` | WS + 재연결 refresh |
| **알림 목록 / 미확인 수** | `notification_screen`, `home_tab`(`_hasUnreadNotification`) | notification API | 없음 (네비 복귀 시 재확인) |
| **요청 목록(받은/보낸)** | `request_management`(`_receivedRequests`/`_sentRequests`) | tradeRequest API | 이벤트 시 재조회 |
| **알림 mute 설정** | `notification_screen`(로컬 `_mutedNotificationTypes`) ↔ `notification_settings`(`notificationSettingProvider`) | `getMemberInfo` / 설정 API | **store 2개 분열** |
| 좋아요 | `itemLikeProvider` ✅ | - | 공유됨 |
| 차단 상태 | `memberBlockProvider` ✅ | - | 공유됨 |
| 알림 설정 토글 | `notificationSettingProvider` ✅ | - | 공유됨 |

### 규칙 위반 / 정합성 결함 (우선순위)
1. `register_tab._myItems`: initState 1회 로드 + 이벤트 미구독 → 거래완료/삭제/상태변경 후 stale.
2. 상태변경(`updateItemStatus`)·삭제(`deleteItem`)는 이벤트 미발행 → 직접 호출자만 갱신, 타 탭 stale.
   (`item_detail_description:270,300`, `register_tab:752,782`)
3. `register_tab._deleteItem`이 `_myItems.removeWhere`로 **수동 제거** (`:786`) — CLAUDE.md "재조회만" 위반.
4. 알림 mute 상태 **이중 보관** (`notification_screen:60` vs `notification_settings`) — 화면 간 불일치.
5. **GlobalKey 교차호출** — `register_tab:200-217`이 `MainScreen.globalKey.switchToTab` +
   `HomeTabScreen.globalKey.showCoachMark` 직접 호출. (CLAUDE.md 금지) 등록 후 홈 갱신이 GlobalKey에 결합.
6. `profile_exchange_section._items`, `my_page_tab` 프로필: 1회 로드 후 mutation 미반영.

---

## 2. 표준 규칙 (CLAUDE.md에 박을 핵심)

### 규칙 0 — 공유 상태의 단일 소유자
여러 화면이 보는 도메인 데이터는 **반드시 Riverpod provider 하나가 단일 소유**한다.
화면은 데이터를 로컬 `setState`로 들지 않고 `ref.watch(provider)`로 구독만 한다.
"이 데이터를 누가 소유하고 누가 구독하나"를 기능 작성 전에 먼저 정한다.

### 규칙 1 — 4-레이어 표준 구조
모든 도메인 provider는 동일 구조를 따른다:
```
lib/repositories/<domain>_repository.dart  ← API 래핑 (ItemApi 등 호출만, UI 모름)
lib/states/<domain>_state.dart             ← @immutable 상태 모델 (copyWith/==/hashCode)
lib/providers/<domain>_provider.dart       ← Notifier/AsyncNotifier + Provider 선언
```
- repository는 plain `Provider`로 주입 (`itemRepositoryProvider` 패턴) → 테스트 시 override 가능.
- 화면은 provider만 의존, API/repository 직접 호출 금지.

### 규칙 2 — Notifier 종류 선택 기준
| 상태 성격 | Notifier 종류 | 예 |
|---|---|---|
| 비동기 목록 로딩 (서버에서 fetch, 로딩/에러 상태 있음) | **`AsyncNotifier<T>`** (`AsyncValue`) | 내 물건, 프로필, 채팅방, 알림목록, 요청목록 |
| optimistic 토글 (즉시 반영 + 실패 롤백, 로딩 UI 불필요) | **동기 `Notifier<T>`** + `_inFlight` dedup | 좋아요, 차단, 알림설정 |

- AsyncNotifier `build()`에서 최초 1회 로드. `AsyncValue`로 로딩/데이터/에러를 UI에서 일관 처리
  (스켈레톤·에러 위젯·데이터 분기를 `.when`으로).

### 규칙 3 — mutation은 notifier 메서드로만 (호출처 누락 불가)
- mutation API는 화면에서 직접 호출하지 **않는다**. notifier 메서드를 호출한다.
  예: `ref.read(myItemsProvider.notifier).register(req)` / `.delete(id)` / `.changeStatus(id, status)`.
- notifier 메서드 내부에서 API 호출 + 상태 갱신까지 책임. 가능하면 optimistic(즉시 반영 후 실패 롤백).
- 목록 갱신은 **서버 재조회**가 원칙 (CLAUDE.md). 클라이언트 수동 `removeWhere` 금지.
  단 optimistic UX가 필요한 토글류는 즉시 반영 후 서버 응답으로 확정.

### 규칙 4 — 이벤트 버스 / GlobalKey 교차호출 금지
- `AppEventBus` 류 전역 이벤트 버스를 새로 만들지 않는다. 상태 전파는 provider 구독으로 한다.
- 한 화면이 다른 화면의 메서드를 `GlobalKey.currentState.x()`로 호출하지 않는다.
  화면 전환·갱신은 provider(상태) + 네비게이션(행위)으로 분리.

### 규칙 5 — 화면은 Consumer
공유 상태를 쓰는 화면은 `ConsumerStatefulWidget`/`ConsumerWidget`. `ref.watch`=구독,
`ref.read(...).method()`=행위. `StreamSubscription`/수동 dispose 보일러플레이트 불필요.

---

## 3. 아키텍처 (이번 이슈에서 만들 provider)

기존 3개(좋아요·차단·알림설정)는 규칙 2의 "토글 상태"에 이미 부합 → **로직 유지**,
파일 위치/네이밍/repository 분리만 규칙 1에 맞춰 통일. 신규는 전부 AsyncNotifier.

| 신규 provider | 상태 | mutation 메서드 | 구독 화면 |
|---|---|---|---|
| `myItemsProvider` | `MyItemsState{available, exchanged}` (`AsyncValue`) | `register`, `delete`, `changeStatus`, `reload` | home, register_tab, my_register_item, request_management, profile_exchange |
| `memberProfileProvider` | `MemberProfileState{nickname,profileUrl,location,accountStatus,…}` | `updateProfile`, `reload` | my_page_tab, main, chat_room, notification, search_range, member_profile, category_settings |
| `chatRoomsProvider` | `List<ChatRoomDetail>` (`AsyncValue`) | `reload`, WS 수신 시 갱신 | chat_tab |
| `notificationsProvider` | `NotificationState{activity, romrom, unreadCount}` | `markAllRead`, `reload` | notification_screen, home_tab(뱃지) |
| `tradeRequestsProvider` | `{received, sent}` | `reload` | request_management |

### 거래완료 전파 (이벤트 버스 대체)
- `chat_room_screen` 거래완료 2지점 → `ref.read(myItemsProvider.notifier).reload()`
  (+ 필요 시 `tradeRequestsProvider.reload()`). `TradeCompletedEvent` emit 제거.
- 직접 상태변경/삭제(`item_detail`, `register_tab`)도 동일하게 notifier 메서드 경유 →
  현재 누락된 타 탭 갱신이 자동 해결.

### `myItemsProvider` 예시 (표준 형태)
```dart
final myItemsProvider = AsyncNotifierProvider<MyItemsNotifier, MyItemsState>(MyItemsNotifier.new);

class MyItemsNotifier extends AsyncNotifier<MyItemsState> {
  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  @override
  Future<MyItemsState> build() => _fetch();              // 최초 1회

  Future<MyItemsState> _fetch() async {
    final results = await Future.wait([
      _repo.getMyItems(ItemStatus.available),
      _repo.getMyItems(ItemStatus.exchanged),
    ]);
    return MyItemsState(available: results[0], exchanged: results[1]);
  }

  Future<void> reload() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> register(ItemRequest req) async {
    await _repo.postItem(req);
    await reload();                                       // 서버 재조회
  }

  Future<void> delete(String itemId) async {
    await _repo.deleteItem(itemId);
    await reload();
  }

  Future<void> changeStatus(ItemRequest req) async {
    await _repo.updateItemStatus(req);
    await reload();
  }
}
```

---

## 4. 화면별 변경 요지

- **home_tab**: `_myCards`/`_loadMyCards`/`_tradeCompletedSub`/GlobalKey 제거. `ref.watch(myItemsProvider)`
  → `cards = available`, `블러 = !isLoading && available.isEmpty`. 코치마크는 `memberProfile`의
  `isFirstItemPosted` 기반으로 분리(GlobalKey 호출 폐기). 등록은 notifier 경유.
- **register_tab**: `_myItems`/수동 removeWhere/GlobalKey 교차호출 전부 제거. provider 구독 + notifier mutation.
  등록 후 홈 전환은 네비게이션만, 갱신은 provider가.
- **my_register_item / request_management / profile_exchange**: 로컬 목록 → provider 파생. 이벤트 구독 제거.
- **my_page_tab + 프로필 8화면**: `getMemberInfo` 개별 호출 → `memberProfileProvider` 구독.
- **chat_tab**: `_chatRoomsDetail` → `chatRoomsProvider`. WS 수신 시 notifier 갱신.
- **notification_screen + home 뱃지**: 목록·미확인수 → `notificationsProvider`. mute 이중 store 제거,
  `notificationSettingProvider`로 일원화.
- **chat_room**: 거래완료 emit → notifier reload.

### 제거 대상
`lib/services/app_event_bus.dart`, `lib/events/app_event.dart`, `lib/events/trade_completed_event.dart`,
`HomeTabScreen.globalKey`/`MainScreen.globalKey`(교차호출 목적분), 각 화면 `StreamSubscription` 보일러플레이트.

---

## 5. 문서 / 규칙 박제

- **CLAUDE.md** "공유 상태 갱신" 섹션 전면 교체: 이벤트 버스 서술 삭제 → §2 규칙 0~5로 대체.
  4-레이어 구조, Notifier 선택 기준 표, mutation=notifier 메서드, 이벤트버스·GlobalKey 금지 명시.
- **`.claude/instructions/state-management.md`** 동일하게 재작성 (provider 추가 4단계 레시피 →
  "새 도메인 provider 추가 레시피"로 갱신: repository→state→provider→화면 구독).
- **메모리 `indexedstack-stale-state.md`**: TradeEventBus 언급 → Riverpod 중앙화로 갱신.

---

## 6. 단계적 전환 (안전 배포)

도메인 단위로 PR을 쪼개 점진 머지 (한 번에 13화면 변경은 회귀 위험 큼):

1. **myItemsProvider** (이번 stale 버그 직접 해결) — home/register_tab/my_register/request_mgmt/profile_exchange
   + chat_room 거래완료 reload + 이벤트 버스 제거 + GlobalKey 제거.
2. **memberProfileProvider** — 프로필 8화면.
3. **notificationsProvider** + mute 분열 정리.
4. **chatRoomsProvider** / **tradeRequestsProvider**.
5. 기존 3개 provider 위치·네이밍 규칙 정렬 (로직 불변).
6. CLAUDE.md / instructions / 메모리 갱신 (각 단계와 함께, 최종 정리).

각 단계 후 사용자 환경에서 시나리오 검증. 내부망이라 빌드/린트/테스트는 사용자.
코드 수정 후 `dart format --line-length=120 .`만 실행.

---

## 7. 검증 시나리오 (도메인 1 기준)

1. 신규 회원: 홈 블러 → 등록 → 즉시 블러 OFF + 카드 1개 (재시작 불필요)
2. 기존 회원 0개: 등록 → 홈 카드 노출
3. 마지막 물건 삭제 → 홈 블러 복귀
4. 마이페이지 직접 교환완료 → 홈 카드 덱 + 요청관리에서 제외
5. 채팅 거래완료 → 홈/내물건/요청관리 동시 갱신 (회귀 없음)
6. register_tab 거래완료 후 stale 해소 (기존 미구독 버그)
