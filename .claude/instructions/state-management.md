# 상태관리 가이드 (화면 간 공유 상태 갱신)

한 화면의 액션이 **다른 화면이 들고 있는 목록/상태**에 영향을 줄 때, 그 화면들이 stale해지지 않도록 갱신을 전파하는 규칙. 거래완료 카드 미갱신 버그(이슈 #875)에서 도입되었다.

설계 참고: `docs/superpowers/specs/2026-05-27-trade-completion-home-card-refresh-design.md`

## 왜 필요한가 — IndexedStack 함정

`MainScreen`은 `IndexedStack`으로 5개 탭을 렌더한다 (`lib/screens/main_screen.dart`).

- 탭 전환은 `_currentTabIndex`만 바꿀 뿐, 탭 위젯은 **계속 메모리에 살아있다**. `initState`는 다시 실행되지 않는다.
- 따라서 `initState`에서 1회만 데이터를 로드하는 탭은, 다른 탭/화면에서 일어난 변경을 **영원히 반영하지 못한다** (stale).
- 예) 채팅방에서 거래완료 → 내 물건이 `EXCHANGED`로 바뀌어도, 홈 탭의 `_myCards`는 `initState` 시점 그대로 → 거래완료된 물건이 카드 덱에 계속 노출.

> `initState` 1회 로드는 "이 데이터는 앱이 떠 있는 동안 절대 안 바뀐다"가 확실할 때만 쓴다. 바뀔 수 있으면 아래 이벤트 버스로 갱신을 구독한다.

## 구조 — 단일 버스 + 타입 기반 이벤트

도메인별 버스 클래스를 난립시키지 않는다. **단일 버스 1개 + 타입으로 구분되는 이벤트**를 쓴다. 이벤트가 늘어나도 버스는 수정하지 않는다.

| 파일 | 역할 |
|------|------|
| `lib/services/app_event_bus.dart` | 단일 버스 `AppEventBus` — `emit(event)` / `on<T>()` |
| `lib/events/app_event.dart` | 이벤트 베이스 `abstract class AppEvent` |
| `lib/events/<event_name>_event.dart` | 개별 이벤트 (`AppEvent` 하위 클래스, 1파일 1이벤트) |

```dart
// 발행 (상태를 바꾸는 지점 — API 성공 / WebSocket 수신 직후)
AppEventBus.instance.emit(const TradeCompletedEvent());

// 구독 (그 데이터를 보여주는 화면의 initState)
_sub = AppEventBus.instance.on<TradeCompletedEvent>().listen((event) {
  if (mounted) _loadXxx(); // 자신의 로드 함수 재호출
});

// 해제 (dispose) — 필수
@override
void dispose() {
  _sub?.cancel();
  super.dispose();
}
```

## 새 이벤트 추가 레시피 (4단계)

이벤트는 늘어난다. 추가할 때 **버스(`app_event_bus.dart`)는 절대 고치지 않는다.** 다음만 한다.

1. **이벤트 클래스 생성** — `lib/events/<event_name>_event.dart`에 `AppEvent` 하위 클래스 1개. payload가 필요하면 final 필드로 추가.
   ```dart
   import 'package:romrom_fe/events/app_event.dart';

   class ItemRegisteredEvent extends AppEvent {
     final String itemId;
     const ItemRegisteredEvent(this.itemId);
   }
   ```
   (enum을 `lib/enums/`에 개별 파일로 두는 컨벤션과 동일하게, 이벤트는 `lib/events/`에 개별 파일.)

2. **발행** — 상태를 바꾸는 지점(액션 성공 직후, 실패 시 발행 금지)에서 `emit`.
   ```dart
   await itemApi.registerItem(...);
   AppEventBus.instance.emit(ItemRegisteredEvent(newId));
   ```

3. **구독** — 그 변경을 반영해야 하는 모든 화면의 `initState`에서 `on<NewEvent>().listen(...)` → 자신의 로드 함수 재호출. 필드 타입은 `StreamSubscription<NewEvent>?`.

4. **해제** — 각 구독 화면 `dispose`에서 `_sub?.cancel()`.

## 추가 원칙

- **목록 필터는 서버에 맡기고, 변경 시 재조회한다.** 클라이언트에서 항목을 수동 제거하지 말 것. 예) `getMyItems(itemStatus: AVAILABLE)`는 `EXCHANGED` 물건을 서버가 제외하므로 **재조회만 하면** 정확히 갱신된다. (로컬 수동 조작은 서버 상태와 어긋날 위험.)

- **`GlobalKey`로 다른 화면의 메서드를 직접 호출하지 말 것** (예: `B.globalKey.currentState.someMethod()`). 화면 간 결합이 강해지고 깨지기 쉽다. 이벤트 버스 구독으로 대체한다.

- **새 기능 착수 전에 "이 데이터를 누가 소유하고, 누가 구독하나"를 먼저 정한다.** 공유 데이터를 화면 위젯의 state에 가둔 채 여러 화면이 각자 로드하면, 동기화가 깨진다.

## 현재 구독 현황

`TradeCompletedEvent` 구독 화면 (거래완료 시 내 물건 목록 갱신):

| 화면 | 재호출 함수 |
|------|------------|
| `lib/screens/home_tab_screen.dart` (홈 카드 덱) | `_loadMyCards()` |
| `lib/screens/request_management_tab_screen.dart` (요청관리) | `_loadInitialItems(isRefresh: true)` |
| `lib/screens/my_page/my_register_item_screen.dart` (마이페이지) | `_loadAllTabs(isRefresh: true)` |

발행 지점: `lib/screens/chat_room_screen.dart` — `_onConfirmTradeRequest`(확정자), WebSocket `tradeCompleted` 수신(요청자).
