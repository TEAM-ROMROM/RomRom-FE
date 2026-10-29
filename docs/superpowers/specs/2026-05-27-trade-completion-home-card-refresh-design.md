# 거래완료 후 홈 카드 덱 미갱신 버그 설계

작성일: 2026-05-27
관련 이슈: (작성 예정 — 홈 탭에서 거래완료된 내 물건이 카드 덱에 계속 노출)

## 문제

거래가 완료(EXCHANGED)되어도 홈 화면 하단 카드 덱(`HomeTabCardHand`)에 해당 물건이 계속 표시된다.
사용자(조민영)는 거래완료 후 앱을 껐다 켜야 카드가 사라졌다.

## 진단 (근거: `romrom (1).log`, 2026-05-27 14:51)

- `14:51:17.884` `ChatTradeCompletionService` — BE가 거래완료 처리하며 item을 `EXCHANGED`로 변경 (`exchangedItemId=c9df0bab...`). **BE는 정상.**
- 거래완료 직후 `getMyItems`(`/api/item/get/my`) 재조회 없음.
- `getMyItems`는 `itemStatus: AVAILABLE` 필터로 요청한다 (`item_api.dart:155`). **즉 재조회만 하면 EXCHANGED 물건은 응답에서 자동으로 빠진다.**

근본 원인 (FE 상태관리 누락):

1. `home_tab_screen.dart:96` — `_loadMyCards()`가 `initState`에서 **딱 1회**만 호출된다.
2. `main_screen.dart:133` — `MainScreen`이 `IndexedStack`을 쓴다 → 탭 전환해도 홈 탭 state가 메모리에 살아있어 stale한 `_myCards`가 유지된다.
3. `main_screen.dart:107-140` — `switchToTab` / 바텀 네비 `onTap` 어디에도 reload 트리거가 없다.
4. 카드가 우연히 갱신되는 유일한 경로는 후기 작성 완료 후 `trade_review_screen.dart:59`의 `pushAndRemoveUntil(MainScreen)` — 새 `MainScreen`이 생성되며 새 `initState`가 도는 경우뿐이다. 후기를 스킵하거나, **상대방이 완료**하거나, 앱을 끄지 않으면 카드가 빠지지 않는다.

거래완료가 일어나는 두 경로 (둘 다 `chat_room_screen.dart`를 지난다):

- **확정자**: `_onConfirmTradeRequest()` → `ChatApi().confirmTradeCompletion()` 성공 (`chat_room_screen.dart:715`)
- **요청자(상대방)**: WebSocket `MessageType.tradeCompleted` 메시지 수신 (`chat_room_screen.dart:288`)

## 결정 사항

- **갱신 트리거**: 전역 이벤트 브로드캐스트. 거래완료 시 전역 이벤트를 발행하고, 내 물건 목록을 보여주는 화면들(홈 카드 덱·요청관리·마이페이지)이 구독해 각자의 로드 함수를 재호출한다. 두 경로(확정자/요청자) + 향후 다른 거래완료 진입점을 모두 한 곳에서 커버한다.
- **버스 구조**: 도메인별 버스 클래스 난립을 피해 **단일 버스 `AppEventBus` + 타입 기반 이벤트(`AppEvent` 하위 클래스)**로 설계한다. 이벤트가 거래완료 외에도 늘어날 것이 예상되기 때문 — 새 이벤트는 버스 무수정, `lib/events/`에 클래스 파일만 추가.
- **카드 처리**: 목록에서 제외 (현행 유지). `_loadMyCards`가 `AVAILABLE`만 조회하므로 재조회만 하면 EXCHANGED는 자동으로 빠진다. 별도 UI 작업 없음.

## 설계

### 1. 신규 — 단일 전역 이벤트 버스 + 타입 기반 이벤트

이벤트가 거래완료 외에도 늘어날 것이 예상되므로, 도메인별 버스 클래스를 난립시키지 않고 **단일 버스 + 타입으로 구분되는 이벤트**로 설계한다. 새 이벤트는 버스를 고치지 않고 `lib/events/`에 `AppEvent` 하위 클래스 파일만 추가하면 된다 (enum을 `lib/enums/`에 개별 파일로 두는 컨벤션과 동일).

`lib/events/app_event.dart` (신규) — 이벤트 베이스 타입
```dart
abstract class AppEvent {
  const AppEvent();
}
```

`lib/events/trade_completed_event.dart` (신규) — 거래완료 이벤트
```dart
import 'package:romrom_fe/events/app_event.dart';

class TradeCompletedEvent extends AppEvent {
  const TradeCompletedEvent();
}
```

`lib/services/app_event_bus.dart` (신규) — 단일 버스 (`HeartbeatManager.instance` 같은 싱글톤 컨벤션)
```dart
import 'dart:async';
import 'package:romrom_fe/events/app_event.dart';

class AppEventBus {
  AppEventBus._internal();
  static final AppEventBus instance = AppEventBus._internal();

  final StreamController<AppEvent> _controller = StreamController<AppEvent>.broadcast();

  void emit(AppEvent event) => _controller.add(event);

  /// 타입 [T]의 이벤트만 필터링한 스트림.
  Stream<T> on<T extends AppEvent>() => _controller.stream.where((e) => e is T).cast<T>();

  void dispose() => _controller.close();
}
```

- `broadcast()` 스트림이라 다중 구독 허용.
- `on<T>()` 제네릭 필터로 타입 안전하게 특정 이벤트만 구독.
- 이벤트에 payload(itemId 등)가 필요해지면 해당 이벤트 클래스에 필드만 추가 (버스 무수정).
- 앱 전역 싱글톤이라 `dispose`는 실제로는 호출되지 않지만, 인터페이스 완결성을 위해 둔다.

### 2. 발행 — `chat_room_screen.dart`

두 거래완료 경로에서 이벤트 발행.

(a) 확정자 — `_onConfirmTradeRequest` (`chat_room_screen.dart:715`)
```dart
await ChatApi().confirmTradeCompletion(chatRoomId: widget.chatRoomId);
AppEventBus.instance.emit(const TradeCompletedEvent()); // 추가
if (!mounted) return;
...
```

(b) 요청자 — WebSocket `tradeCompleted` 수신 (`chat_room_screen.dart:288`)
```dart
if (newMessage.type == MessageType.tradeCompleted && !_reviewNavigated) {
  AppEventBus.instance.emit(const TradeCompletedEvent()); // 추가
  final tradeRequestHistoryId = chatRoom.tradeRequestHistory?.tradeRequestHistoryId;
  ...
}
```

발행 위치는 API 성공/메시지 수신 확정 직후. 실패 시(catch) 발행하지 않는다.

### 3. 구독 — 내 물건 목록을 보여주는 화면들

`home_tab_screen.dart`(홈 카드 덱), `request_management_tab_screen.dart`(요청관리), `my_page/my_register_item_screen.dart`(마이페이지)가 모두 동일 패턴으로 구독한다. `initState`에서 구독, `dispose`에서 해제. 아래는 홈 탭 예시.

```dart
StreamSubscription<TradeCompletedEvent>? _tradeCompletedSub;

@override
void initState() {
  super.initState();
  _loadInitialItems();
  _loadMyCards();
  _checkFirstMainScreen();
  unawaited(_loadUnreadNotificationStatus());
  // 거래완료 시 내 카드 목록 재조회 (거래완료된 물건은 AVAILABLE 필터에서 자동 제외됨)
  _tradeCompletedSub = AppEventBus.instance.on<TradeCompletedEvent>().listen((_) {
    if (mounted) _loadMyCards();
  });
}

@override
void dispose() {
  _tradeCompletedSub?.cancel();
  _removeCoachMarkOverlay();
  _pageController.dispose();
  super.dispose();
}
```

요청관리 탭은 `_loadInitialItems(isRefresh: true)`, 마이페이지는 `_loadAllTabs(isRefresh: true)`를 같은 방식으로 재호출한다.

`_loadMyCards()`는 이미 `mounted` 체크와 `setState`로 `_myCards` 및 `_isBlurShown`을 갱신하므로 추가 변경 불필요. 거래완료로 내 물건이 0개가 되면 블러도 자동으로 켜진다.

## 데이터 흐름

```
[채팅방]
  확정자: confirmTradeCompletion() 성공 ─┐
  요청자: WS tradeCompleted 수신 ────────┤
                                         ▼
                  AppEventBus.emit(const TradeCompletedEvent())
                                         │ (broadcast stream, 타입 필터)
                          ┌──────────────┼──────────────┐
                          ▼              ▼              ▼
                     [홈 카드 덱]    [요청관리 탭]   [마이페이지]
                  on<TradeCompletedEvent>().listen
                          ▼              ▼              ▼
                  _loadMyCards()  _loadInitialItems  _loadAllTabs
                                         ▼
                          BE가 EXCHANGED 물건 제외하고 응답 (itemStatus: AVAILABLE)
                                         ▼
                          setState → 거래완료 물건 사라짐 / 거래완료 탭으로 이동
```

## 영향 범위

| 파일 | 변경 |
|------|------|
| `lib/events/app_event.dart` | 신규 — 이벤트 베이스 `AppEvent` |
| `lib/events/trade_completed_event.dart` | 신규 — `TradeCompletedEvent` |
| `lib/services/app_event_bus.dart` | 신규 — 단일 이벤트 버스 `AppEventBus` (타입 기반 `on<T>()`) |
| `lib/screens/chat_room_screen.dart` | 거래완료 2개 지점에서 `emit(const TradeCompletedEvent())` 발행 |
| `lib/screens/home_tab_screen.dart` | `initState` 구독 / `dispose` 해제 → `_loadMyCards()` |
| `lib/screens/request_management_tab_screen.dart` | `initState` 구독 / `dispose` 해제 → `_loadInitialItems(isRefresh: true)` |
| `lib/screens/my_page/my_register_item_screen.dart` | `initState` 구독 / `dispose` 해제 → `_loadAllTabs(isRefresh: true)` |

## 테스트 관점

- 채팅방에서 거래완료 확정 → 홈 탭 복귀 시 해당 물건이 카드 덱에서 사라지는지.
- 상대방이 거래완료 확정 → (내 화면 WS 수신) → 홈 카드 덱 갱신되는지.
- 내 물건이 거래완료로 0개가 되면 홈 블러/등록 안내가 다시 뜨는지.
- 후기 작성을 스킵해도 카드가 빠지는지 (기존엔 후기 완료 후에만 우연히 갱신됐음).

## YAGNI / 비범위

- 이벤트 페이로드에 itemId 등 세부 정보 포함 — 현재 불필요.
- 마이페이지/프로필 등 다른 화면의 동일 구독 — 그쪽은 자체 reload 경로(탭 진입 시 로드 등)가 있어 이번 범위 밖. 필요해지면 동일 버스 구독으로 확장.
- 거래완료 외 다른 상태 변경(취소/거절) 전파 — 현재 버그와 무관.
