# 앱 사용 중 푸시 수신 시 상태 갱신 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱 사용 중(포그라운드) 푸시를 받으면 알림 목록·미확인 배지·요청관리 받은 요청을 서버 재조회로 갱신한다.

**Architecture:** `MainScreen`(로그인 세션 동안만 존재)이 `FirebaseService().onForegroundMessage`를 구독하고, 푸시 종류별 갱신 대상을 정하는 `ForegroundPushRefresher`(콜백 3개 주입, 순수 로직)에 넘긴다. 갱신은 기존 notifier 메서드 호출뿐이며 이벤트 버스·GlobalKey는 쓰지 않는다. 요청 provider에는 "마지막으로 본 카드 기준 받은 요청 재조회" 메서드를 추가한다.

**Tech Stack:** Flutter, Riverpod(AsyncNotifier), firebase_messaging, flutter_test

**Spec:** 별도 spec 문서 없음. 이슈 https://github.com/TEAM-ROMROM/RomRom-FE/issues/964 + 채팅에서 확정한 설계(아래 "승인된 설계")

## 승인된 설계 (채팅 확정)

- 푸시 수신 지점 한 곳에서 `notificationType`별로 서버 재조회
- 알림 목록 화면을 보는 중에도 바로 반영 (목록 맨 위에 끼워 넣기, 승인됨)

| 푸시 종류 (`NotificationType`) | 갱신 대상 |
|---|---|
| `tradeRequestReceived` | 알림 목록·배지 + 요청관리 받은 요청 |
| `itemDeletedByAdmin` | 알림 목록·배지 + 내 물품 목록 (구현자 추측, 인수 시 확인) |
| `itemLiked`, `announcement` | 알림 목록·배지 |
| `chatMessageReceived` | 미확인 개수만 재조회 (메시지 자체는 웹소켓 담당, 최종 검토 후 변경: 채팅 알림이 이력에 쌓이면 배지가 어긋나므로 API 1회로 개수만 갱신) |
| 알 수 없는 값, null | 알림 목록·배지 |

## Global Constraints

- 모든 CLI 명령 앞에 `source ~/.zshrc &&` 필수
- 작업 폴더: `/Users/suhsaechan/Desktop/Programming/project/RomRom-FE-Worktree/20261101_964_버그_알림_앱_사용_중_푸시_수신_시_알림_목록_배지_미갱신` (처음 한 번 `source ~/.zshrc && flutter pub get`)
- **커밋·`git add` 금지** (사용자 허락 전까지, 서브에이전트 포함). 각 Task 끝은 "변경 파일 확인"에서 멈춘다
- 이벤트 버스·GlobalKey 교차호출 신설 금지, 공유 상태 갱신은 notifier 메서드 호출로만
- 새 enum 만들지 않음 (만들면 `lib/enums/`에 개별 파일)
- 이름: boolean은 `is/has/can/should` 접두사, 약어 금지. 주석은 간결한 한국어(한 줄 요약·`>` 흐름·`(성공·실패 공통)` 식), 로그는 영어 + `[기능 접두사]`
- 코드 수정 후 `source ~/.zshrc && dart format --line-length=120 .` > `source ~/.zshrc && flutter analyze` 둘 다 통과
- 서버 변경·디자인 변경 없음

## Review Focus

- 알 수 없는 `notificationType`(오타·신규 타입)·null → 앱이 죽지 않고 알림 목록만 갱신
- 갱신 호출 하나가 예외를 던져도 나머지 갱신은 진행되고, 스트림 리스너가 죽지 않음
- 요청관리 탭을 한 번도 안 연 상태(카드 미선택)에서 교환 요청 푸시 → 요청 상태를 비우지 않고 아무 일도 안 함
- 푸시가 연달아 와도 마지막 응답이 반영됨 (기존 generation 가드 유지)
- 화면 종료(`dispose`) 뒤에는 구독이 취소되어 해제된 `ref`를 쓰지 않음

---

### Task 1: 요청 provider에 "현재 카드 받은 요청 재조회" 추가

**Files:**
- Modify: `lib/providers/trade_requests_provider.dart` (`reject` 아래, 약 115행 근처)
- Test: `test/providers/trade_requests_provider_test.dart`

**Interfaces:**
- Consumes: 기존 `_loadReceived(String? takeItemId)`, `_requestedTakeItemId`
- Produces: `Future<void> TradeRequestsNotifier.reloadReceivedOfRequestedCard()`
  - `_requestedTakeItemId`가 null 또는 빈 문자열이면 아무것도 하지 않고 반환 (상태 변경 없음)
  - 그 외에는 `_loadReceived(_requestedTakeItemId)` 호출

- [ ] **Step 1: 실패하는 테스트 작성** — 기존 파일의 `FakeTradeRepository`/컨테이너 생성 패턴을 그대로 사용해 아래 두 테스트를 추가한다.
  - `reloadReceivedOfRequestedCard는 카드 선택 전이면 조회하지 않고 상태를 유지한다`: 컨테이너 생성 직후 호출 > `receivedRequestedTakeItemIds`가 비어 있고 `state.value.received`가 그대로 빈 목록, `currentTakeItemId`가 null
  - `reloadReceivedOfRequestedCard는 마지막으로 선택한 카드로 받은 요청을 다시 조회한다`: `receivedByTakeItemId['item-1'] = [buildTradeRequestHistory('r1')]` 상태에서 `selectItem('item-1')` 후, 서버 응답을 `[r1, r2]`로 바꾸고 호출 > `receivedRequestedTakeItemIds`가 `['item-1', 'item-1']`, `state.value.received.length == 2`

- [ ] **Step 2: 실패 확인**

Run: `source ~/.zshrc && flutter test test/providers/trade_requests_provider_test.dart`
Expected: FAIL (`reloadReceivedOfRequestedCard` 메서드 없음)

- [ ] **Step 3: 구현** — `Future<void> reloadReceivedOfRequestedCard()`를 `TradeRequestsNotifier`에 추가. 문서 주석 한 줄: `푸시 수신 등 외부 신호 시 현재 카드 받은 요청 재조회 (카드 선택 전이면 무시)`.

- [ ] **Step 4: 통과 확인**

Run: `source ~/.zshrc && flutter test test/providers/trade_requests_provider_test.dart`
Expected: 전체 PASS

- [ ] **Step 5: 멈춤** — `git status`로 변경 파일 2개만 확인. 커밋하지 않는다.

---

### Task 2: 푸시 종류별 갱신 분배기 `ForegroundPushRefresher`

**Files:**
- Create: `lib/services/foreground_push_refresher.dart`
- Test: `test/services/foreground_push_refresher_test.dart`

**Interfaces:**
- Consumes: `NotificationType.fromServerName(String?)` (`lib/enums/notification_type.dart`)
- Produces:
  ```dart
  class ForegroundPushRefresher {
    ForegroundPushRefresher({
      required Future<void> Function() reloadNotificationList,
      required Future<void> Function() reloadReceivedTradeRequests,
      required Future<void> Function() reloadMyItems,
    });
    /// FCM data 페이로드 > 종류 판정 > 해당 갱신 병렬 실행 (하나가 실패해도 나머지 진행, 예외는 밖으로 던지지 않음)
    Future<void> onForegroundPush(Map<String, dynamic> data);
  }
  ```
  - 종류는 `data['notificationType']`(String?)을 `NotificationType.fromServerName`으로 판정
  - 갱신 대상은 위 "승인된 설계" 표 그대로
  - 각 갱신 실패는 `debugPrint('[foreground push refresh] <대상> failed : $error')`

- [ ] **Step 1: 실패하는 테스트 작성** — 호출 횟수를 세는 3개 콜백으로 `ForegroundPushRefresher`를 만든다. 테스트 이름과 단언:
  - `교환 요청 수신은 알림 목록과 받은 요청을 갱신한다`: `{'notificationType': 'TRADE_REQUEST_RECEIVED'}` > 목록 1, 받은 요청 1, 내 물품 0
  - `게시글 삭제는 알림 목록과 내 물품을 갱신한다`: `ITEM_DELETED_BY_ADMIN` > 목록 1, 받은 요청 0, 내 물품 1
  - `좋아요와 공지는 알림 목록만 갱신한다`: `ITEM_LIKED`, `ANNOUNCEMENT` 각각 > 목록 1, 나머지 0
  - `채팅 메시지는 아무것도 갱신하지 않는다`: `CHAT_MESSAGE_RECEIVED` > 전부 0
  - `알 수 없는 종류와 null은 알림 목록만 갱신한다`: `{'notificationType': 'NEW_UNKNOWN'}`, `{}` > 각각 목록 1, 나머지 0
  - `갱신 하나가 실패해도 나머지는 실행되고 예외가 밖으로 나가지 않는다`: 받은 요청 콜백이 예외를 던지게 하고 `TRADE_REQUEST_RECEIVED` > 목록 1, 내 물품 0, `onForegroundPush` 자체는 예외 없이 완료

- [ ] **Step 2: 실패 확인**

Run: `source ~/.zshrc && flutter test test/services/foreground_push_refresher_test.dart`
Expected: FAIL (파일/클래스 없음)

- [ ] **Step 3: 구현** — 위 시그니처대로 `lib/services/foreground_push_refresher.dart` 작성. 종류 > 실행할 콜백 목록을 정하는 private 메서드와, 콜백마다 try/catch 후 `Future.wait`하는 부분으로 나눈다. 클래스 문서 주석은 두 줄 이내(`대상: 책임`, 동작 구조).

- [ ] **Step 4: 통과 확인**

Run: `source ~/.zshrc && flutter test test/services/foreground_push_refresher_test.dart`
Expected: 6개 테스트 PASS

- [ ] **Step 5: 멈춤** — `git status`로 변경 파일 확인, 커밋하지 않는다.

---

### Task 3: MainScreen 구독 연결과 전체 검증

**Files:**
- Modify: `lib/screens/main_screen.dart` (`initState` 36행 근처, `dispose` 약 150행 근처, import 추가)

**Interfaces:**
- Consumes: `FirebaseService().onForegroundMessage` (`Stream<RemoteMessage>`), `ForegroundPushRefresher.onForegroundPush(Map<String, dynamic>)`, `notificationListProvider.notifier.reload()`, `tradeRequestsProvider.notifier.reloadReceivedOfRequestedCard()`, `myItemsProvider.notifier.reload()`
- Produces: 없음 (화면 연결)

- [ ] **Step 1: 구현** — `_MainScreenState`에 `StreamSubscription<RemoteMessage>? _foregroundPushSubscription` 필드를 추가한다. `initState`에서 `ForegroundPushRefresher`를 위 콜백 3개(`ref.read(...notifier)` 메서드 참조)로 만들고 `FirebaseService().onForegroundMessage.listen((message) => refresher.onForegroundPush(message.data))`로 구독한다. `dispose`에서 `cancel()`. 구독 주석 한 줄: `앱 사용 중 푸시 > 종류별 상태 재조회 (#964)`.

- [ ] **Step 2: 포맷·분석**

Run: `source ~/.zshrc && dart format --line-length=120 . && flutter analyze`
Expected: 포맷 변경은 내 파일만, analyze `No issues found`

- [ ] **Step 3: 전체 테스트**

Run: `source ~/.zshrc && flutter test`
Expected: 전체 PASS (특히 `test/architecture/*`, `test/providers/*`)

- [ ] **Step 4: 실기기 확인 안내 작성** — 코드로 검증 못 하는 부분(두 기기 시나리오: 홈 배지 증가, 알림 화면 맨 위 삽입, 요청관리 받은 요청 증가, iOS/Android 각각)을 사용자에게 전달할 확인 목록으로 정리한다. 이 단계는 실행하지 않고 보고에만 포함한다.

- [ ] **Step 5: 멈춤** — `git status`로 변경 파일 확인(총 6개: provider, 분배기, main_screen, 테스트 2개 + 계획 문서), 커밋하지 않고 사용자 diff 확인을 기다린다.
