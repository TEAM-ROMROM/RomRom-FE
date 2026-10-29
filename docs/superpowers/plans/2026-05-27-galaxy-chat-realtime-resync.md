# 갤럭시 채팅 실시간 미표시 수정 (재연결 동기화) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** WebSocket이 끊겨도 메시지 유실 없이 화면에 표시되도록, 재연결 동기화(Sync) 층을 프론트엔드에 추가한다.

**Architecture:** 싱글톤 `ChatWebSocketService`가 재연결을 감지해 `onReconnected` broadcast 스트림으로 알린다. 채팅방/채팅탭 화면이 이를 구독해 `getChatMessages`를 재조회하고 `chatMessageId` 기반으로 병합한다. 내 텍스트 메시지는 전송 즉시 낙관적 삽입하고, 시각 폴백 `DateTime.now()`를 제거해 가짜 시각을 방지한다.

**Tech Stack:** Flutter, Dart, stomp_dart_client (STOMP over WebSocket), flutter_test.

**제약:** 내부망 환경 — `flutter pub get`/`analyze`/`build` 불가. 코드 수정 후 `dart format --line-length=120 .`만 실행. 린트/빌드/테스트 실행은 사용자가 별도 환경에서 수행한다. 따라서 본 plan의 "테스트 실행" 단계는 **사용자 환경에서 실행할 명령**으로 기재하며, 에이전트는 테스트 코드 작성과 `dart format`까지만 수행한다.

**커밋 규칙:** 사용자 명시 승인 없이는 `git add`/`git commit` 금지 (CLAUDE.md). 각 Task의 커밋 단계는 **사용자 승인 후** 수행한다. 에이전트는 변경 후 diff를 보여주고 대기한다.

**관련 이슈:** [#872](https://github.com/TEAM-ROMROM/RomRom-FE/issues/872)
**Spec:** `docs/superpowers/specs/2026-05-27-galaxy-chat-realtime-resync-design.md`

---

## File Structure

| 파일 | 책임 | 변경 |
|------|------|------|
| `lib/services/chat_websocket_service.dart` | STOMP 연결·구독·재연결 감지 | `onReconnected` 스트림, `_hasConnectedBefore` 플래그, `_onConnect` 분기, 시각 폴백 제거 |
| `lib/screens/chat_room_screen.dart` | 채팅방 화면 상태·메시지 목록 | `onReconnected` 구독, `_mergeServerMessages` 헬퍼, `_isResyncing` 플래그, `_sendMessage` 낙관적 삽입 |
| `lib/screens/chat_tab_screen.dart` | 채팅방 목록 화면 | `onReconnected` 구독 → 목록 refresh |
| `test/services/chat_message_merge_test.dart` | 병합 로직 단위 테스트 | 신규 (순수 함수 추출분 검증) |

---

## Task 1: WebSocket 재연결 이벤트 스트림 추가

**Files:**
- Modify: `lib/services/chat_websocket_service.dart`

- [ ] **Step 1: 재연결 상태 필드와 공개 스트림 선언**

`chat_websocket_service.dart`의 필드 영역(기존 `bool _isRefreshingToken = false;` 아래, line 32 근처)에 추가:

```dart
  // 최초 연결 이후 재연결 여부 판단 (true면 _onConnect가 재연결로 간주)
  bool _hasConnectedBefore = false;

  // 재연결 시 화면이 메시지 재동기화를 트리거하도록 알리는 브로드캐스트 스트림
  final StreamController<void> _reconnectController = StreamController<void>.broadcast();

  /// 재연결 이벤트 스트림. 화면은 이를 구독해 getChatMessages 재조회를 수행한다.
  Stream<void> get onReconnected => _reconnectController.stream;
```

- [ ] **Step 2: `_onConnect`에서 재연결 분기 추가**

기존 `_onConnect`(line 97-104):

```dart
  void _onConnect(StompFrame frame) {
    debugPrint('[WebSocket] ✅ STOMP Connected');
    debugPrint('[WebSocket] Frame: ${frame.headers}');
    _isConnected = true;

    // 기존 구독 재연결
    _resubscribeAll();
  }
```

를 다음으로 교체:

```dart
  void _onConnect(StompFrame frame) {
    debugPrint('[WebSocket] ✅ STOMP Connected');
    debugPrint('[WebSocket] Frame: ${frame.headers}');
    _isConnected = true;

    // 기존 구독 재연결
    _resubscribeAll();

    // 최초 연결이 아니라면(= 재연결) 화면에 재동기화 신호를 보낸다.
    // 단절 구간에 브로드캐스트되어 유실된 메시지를 REST 재조회로 복구하기 위함.
    if (_hasConnectedBefore) {
      debugPrint('[WebSocket] 🔁 재연결 감지 → onReconnected 방송');
      if (!_reconnectController.isClosed) {
        _reconnectController.add(null);
      }
    }
    _hasConnectedBefore = true;
  }
```

- [ ] **Step 3: `dart format` 실행**

Run (에이전트 수행): `dart format --line-length=120 lib/services/chat_websocket_service.dart`
Expected: 포맷 적용 완료, 에러 없음.

- [ ] **Step 4: 변경 확인 후 커밋 (사용자 승인 후)**

diff를 사용자에게 보여주고 승인 대기. 승인 시:

```bash
git add lib/services/chat_websocket_service.dart
git commit -m "갤럭시 채팅 실시간 미표시 : feat : WS 재연결 이벤트 스트림(onReconnected) 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/872"
```

---

## Task 2: 시각 폴백 `DateTime.now()` 제거

**Files:**
- Modify: `lib/services/chat_websocket_service.dart:313`

- [ ] **Step 1: 폴백에서 `DateTime.now()` 제거**

기존(line 312-313):

```dart
          // 3) 최종 시간 확정: 헤더 → 페이로드 → 지금
          final finalCreated = headerTs ?? payloadTs ?? DateTime.now();
```

를 다음으로 교체:

```dart
          // 3) 최종 시간 확정: 헤더 → 페이로드 (둘 다 없으면 null 유지)
          // DateTime.now() 폴백을 쓰면 지연 수신 메시지가 '수신 시각'으로 밀려 표시되므로 제거.
          // 시각 출처가 없으면 null로 두고, 재연결 동기화 시 서버 createdDate로 교정된다.
          final finalCreated = headerTs ?? payloadTs;
```

- [ ] **Step 2: `copyWith(createdDate: finalCreated)`가 null을 허용하는지 확인**

`chat_message.dart`의 `copyWith` 시그니처는 `DateTime? createdDate`이고 `createdDate: createdDate ?? this.createdDate` 패턴이다(line 53, 66 확인됨). `finalCreated`가 null이면 `copyWith`가 기존 값(또는 null)을 유지하므로 안전. 추가 변경 불필요.

확인만 수행 — 코드 변경 없음.

- [ ] **Step 3: `dart format` 실행**

Run (에이전트 수행): `dart format --line-length=120 lib/services/chat_websocket_service.dart`
Expected: 포맷 적용 완료.

- [ ] **Step 4: 커밋 (사용자 승인 후)**

```bash
git add lib/services/chat_websocket_service.dart
git commit -m "갤럭시 채팅 실시간 미표시 : fix : 메시지 시각 폴백 DateTime.now() 제거로 시각 밀림 방지 https://github.com/TEAM-ROMROM/RomRom-FE/issues/872"
```

---

## Task 3: 메시지 병합 순수 함수 추출 + 단위 테스트

목적: 재동기화 시 서버 메시지와 현재 목록을 합치는 로직을 테스트 가능한 순수 함수로 만든다.

**Files:**
- Modify: `lib/screens/chat_room_screen.dart` (병합 로직을 top-level 순수 함수로 추가)
- Test: `test/services/chat_message_merge_test.dart` (신규)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/services/chat_message_merge_test.dart` 생성:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';

void main() {
  // mergeServerMessages: reverse 정렬(index 0 = 최신) 목록 기준.
  // - 서버 메시지 중 현재 목록에 없는 것만 추가
  // - 이미 있으면 서버 버전으로 교체
  // - 낙관적 로컬 메시지(id가 'local_'/'uploading_' 접두)는 보존
  group('mergeServerMessages', () {
    ChatMessage msg(String? id, String content, int epochMs, {String? sender}) => ChatMessage(
          chatRoomId: 'room1',
          chatMessageId: id,
          senderId: sender ?? 'me',
          content: content,
          type: MessageType.text,
          createdDate: DateTime.fromMillisecondsSinceEpoch(epochMs),
        );

    test('현재 목록에 없는 서버 메시지를 병합한다', () {
      final current = [msg('s2', 'b', 2000)];
      final server = [msg('s2', 'b', 2000), msg('s1', 'a', 1000)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.map((m) => m.chatMessageId).toList(), ['s2', 's1']);
    });

    test('중복 ID는 추가하지 않고 서버 버전으로 교체한다', () {
      final current = [msg('s1', 'old', 1000)];
      final server = [msg('s1', 'new', 1500)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.length, 1);
      expect(result.first.content, 'new');
      expect(result.first.createdDate, DateTime.fromMillisecondsSinceEpoch(1500));
    });

    test('낙관적 로컬 메시지는 보존한다', () {
      final current = [msg('local_123', '보내는중', 3000), msg('s1', 'a', 1000)];
      final server = [msg('s1', 'a', 1000)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.any((m) => m.chatMessageId == 'local_123'), isTrue);
    });

    test('결과는 createdDate 내림차순(최신 먼저)으로 정렬한다', () {
      final current = <ChatMessage>[];
      final server = [msg('s1', 'a', 1000), msg('s3', 'c', 3000), msg('s2', 'b', 2000)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.map((m) => m.chatMessageId).toList(), ['s3', 's2', 's1']);
    });

    test('createdDate가 null인 메시지는 맨 뒤로 정렬한다', () {
      final current = <ChatMessage>[];
      final server = [
        msg('s1', 'a', 1000),
        ChatMessage(chatRoomId: 'room1', chatMessageId: 'sNull', senderId: 'me', content: 'x', type: MessageType.text),
      ];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.last.chatMessageId, 'sNull');
    });
  });
}
```

- [ ] **Step 2: 테스트 실행해 실패 확인 (사용자 환경)**

Run (사용자 환경): `flutter test test/services/chat_message_merge_test.dart`
Expected: FAIL — `mergeServerMessages` 미정의 컴파일 에러.

(에이전트는 내부망이라 실행 불가 — 이 단계는 사용자가 수행하거나, 에이전트는 코드 정합성만 검토하고 다음 단계로 진행.)

- [ ] **Step 3: `mergeServerMessages` 순수 함수 구현**

`chat_room_screen.dart` 최상단 import 아래, `class ChatRoomScreen` 선언 위에 top-level 함수로 추가:

```dart
/// 재연결 동기화용 메시지 병합 (순수 함수, 테스트 대상).
///
/// [current]는 화면의 현재 목록(reverse 정렬: index 0 = 최신).
/// [serverMessages]는 getChatMessages 재조회 결과.
///
/// 규칙:
/// - 서버 메시지 중 [current]에 chatMessageId가 없는 것만 추가
/// - 이미 있으면 서버 버전으로 교체 (시각 등 교정)
/// - 낙관적 로컬 메시지(id가 'local_'/'uploading_'/'ws_img_'/'local_trade_request_' 접두)는 서버에 없어도 보존
/// - 결과는 createdDate 내림차순(최신 먼저), null은 맨 뒤
List<ChatMessage> mergeServerMessages({
  required List<ChatMessage> current,
  required List<ChatMessage> serverMessages,
}) {
  bool isLocalOptimistic(String? id) =>
      id != null &&
      (id.startsWith('local_') ||
          id.startsWith('uploading_') ||
          id.startsWith('ws_img_') ||
          id.startsWith('local_trade_request_'));

  final serverById = <String, ChatMessage>{
    for (final m in serverMessages)
      if (m.chatMessageId != null) m.chatMessageId!: m,
  };

  final merged = <ChatMessage>[];

  // 1) 현재 목록 순회: 서버에 있으면 서버 버전으로 교체, 낙관적 로컬은 보존, 그 외 유지
  final keptIds = <String>{};
  for (final m in current) {
    final id = m.chatMessageId;
    if (id != null && serverById.containsKey(id)) {
      merged.add(serverById[id]!);
      keptIds.add(id);
    } else if (isLocalOptimistic(id)) {
      merged.add(m);
    } else if (id != null) {
      merged.add(m);
      keptIds.add(id);
    } else {
      merged.add(m);
    }
  }

  // 2) 서버 메시지 중 아직 추가되지 않은 것 추가
  for (final m in serverMessages) {
    final id = m.chatMessageId;
    if (id != null && !keptIds.contains(id)) {
      merged.add(m);
      keptIds.add(id);
    }
  }

  // 3) createdDate 내림차순 정렬, null은 맨 뒤
  merged.sort((a, b) {
    final da = a.createdDate;
    final db = b.createdDate;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });

  return merged;
}
```

- [ ] **Step 4: 테스트 실행해 통과 확인 (사용자 환경)**

Run (사용자 환경): `flutter test test/services/chat_message_merge_test.dart`
Expected: PASS (5 tests).

- [ ] **Step 5: `dart format` 실행**

Run (에이전트 수행): `dart format --line-length=120 lib/screens/chat_room_screen.dart test/services/chat_message_merge_test.dart`
Expected: 포맷 적용 완료.

- [ ] **Step 6: 커밋 (사용자 승인 후)**

```bash
git add lib/screens/chat_room_screen.dart test/services/chat_message_merge_test.dart
git commit -m "갤럭시 채팅 실시간 미표시 : feat : 메시지 병합 순수함수 mergeServerMessages 추가 및 단위테스트 https://github.com/TEAM-ROMROM/RomRom-FE/issues/872"
```

---

## Task 4: 채팅방 화면 재연결 구독 + 재동기화

**Files:**
- Modify: `lib/screens/chat_room_screen.dart`

- [ ] **Step 1: 재동기화 상태 필드 추가**

`_ChatRoomScreenState`의 필드 영역(기존 `StreamSubscription<ChatMessage>? _messageSubscription;`, line 57 근처)에 추가:

```dart
  // 재연결 동기화 중복 실행 방지
  bool _isResyncing = false;
  // 재연결 이벤트 구독
  StreamSubscription<void>? _reconnectSubscription;
```

- [ ] **Step 2: 재동기화 메서드 추가**

`_handleIncomingMessage`(line 371) 위에 메서드 추가:

```dart
  /// 재연결 시 호출: 서버에서 최신 메시지를 재조회해 유실분을 병합한다.
  Future<void> _resyncMessages() async {
    if (_isResyncing || !mounted) return;
    _isResyncing = true;
    try {
      final response = await ChatApi().getChatMessages(chatRoomId: widget.chatRoomId, pageNumber: 0, pageSize: 50);
      if (!mounted) return;
      final serverMessages = response.messages?.content ?? [];
      setState(() {
        _messages = mergeServerMessages(current: _messages, serverMessages: serverMessages);
      });
      debugPrint('[ChatRoom] 🔁 재연결 동기화 완료: 서버 ${serverMessages.length}건 병합');
    } catch (e) {
      // 백그라운드 동기화이므로 사용자에게 노출하지 않음. 다음 재연결 때 재시도.
      debugPrint('[ChatRoom] 재연결 동기화 실패(무시): $e');
    } finally {
      _isResyncing = false;
    }
  }
```

- [ ] **Step 3: `_loadInitialData`에서 재연결 스트림 구독**

`_loadInitialData` 내 읽음 이벤트 구독(line 322-327) 바로 아래에 추가:

```dart
      // WebSocket 재연결 시 메시지 재동기화 (단절 구간 유실 복구)
      _reconnectSubscription = _wsService.onReconnected.listen((_) {
        _resyncMessages();
      });
```

- [ ] **Step 4: `dispose`에서 구독 취소**

기존 `dispose`(line 753-768)의 `_readEventSubscription?.cancel();` 아래에 추가:

```dart
    _reconnectSubscription?.cancel();
```

- [ ] **Step 5: `dart format` 실행**

Run (에이전트 수행): `dart format --line-length=120 lib/screens/chat_room_screen.dart`
Expected: 포맷 적용 완료.

- [ ] **Step 6: 커밋 (사용자 승인 후)**

```bash
git add lib/screens/chat_room_screen.dart
git commit -m "갤럭시 채팅 실시간 미표시 : feat : 채팅방 화면 재연결 시 메시지 재동기화 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/872"
```

---

## Task 5: 내 텍스트 메시지 낙관적 삽입

**Files:**
- Modify: `lib/screens/chat_room_screen.dart:444-460` (`_sendMessage`)

- [ ] **Step 1: `_sendMessage`에 낙관적 삽입 추가**

기존 `_sendMessage`(line 444-460):

```dart
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSendingMessage || _isInputDisabled) return;

    setState(() => _isSendingMessage = true);
    _messageController.clear();

    _sendMessageTimeoutTimer?.cancel();
    _sendMessageTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isSendingMessage) {
        setState(() => _isSendingMessage = false);
        CommonSnackBar.show(context: context, message: '메시지 전송에 실패했습니다.', type: SnackBarType.error);
      }
    });

    _wsService.sendMessage(chatRoomId: widget.chatRoomId, content: content, type: MessageType.text);
  }
```

를 다음으로 교체:

```dart
  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSendingMessage || _isInputDisabled) return;

    // 낙관적 삽입: WS 에코를 기다리지 않고 즉시 화면에 표시한다.
    // 연결이 끊긴 상태에서도 내 메시지는 바로 보이고, WS 에코 도착 시
    // _handleIncomingMessage의 매칭 로직이 실제 서버 메시지로 교체한다.
    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final localMsg = ChatMessage(
      chatRoomId: widget.chatRoomId,
      chatMessageId: localId,
      senderId: _myMemberId,
      createdDate: DateTime.now(),
      content: content,
      type: MessageType.text,
    );

    setState(() {
      _isSendingMessage = true;
      _messages.insert(0, localMsg);
      _pendingLocalMessages[localId] = localMsg;
    });
    _messageController.clear();
    _scrollToBottom();

    _sendMessageTimeoutTimer?.cancel();
    _sendMessageTimeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted && _isSendingMessage) {
        setState(() => _isSendingMessage = false);
        CommonSnackBar.show(context: context, message: '메시지 전송에 실패했습니다.', type: SnackBarType.error);
      }
    });

    _wsService.sendMessage(chatRoomId: widget.chatRoomId, content: content, type: MessageType.text);
  }
```

- [ ] **Step 2: 텍스트 에코 매칭이 로컬 메시지를 교체하는지 확인**

`_handleIncomingMessage`(line 387-419)는 이미 `_pendingLocalMessages`를 순회해 `senderId`·`content` 일치 + 10초 이내 메시지를 찾아 교체한다. 텍스트 메시지도 `content`가 동일하므로 매칭된다. 추가 변경 불필요 — 확인만 수행.

단, 기존 line 380-383의 텍스트 에코 처리(`_isSendingMessage = false` + 타이머 취소)는 매칭 분기(line 398)보다 먼저 실행되므로 그대로 동작한다. 충돌 없음.

- [ ] **Step 3: `dart format` 실행**

Run (에이전트 수행): `dart format --line-length=120 lib/screens/chat_room_screen.dart`
Expected: 포맷 적용 완료.

- [ ] **Step 4: 커밋 (사용자 승인 후)**

```bash
git add lib/screens/chat_room_screen.dart
git commit -m "갤럭시 채팅 실시간 미표시 : feat : 내 텍스트 메시지 낙관적 삽입으로 즉시 표시 https://github.com/TEAM-ROMROM/RomRom-FE/issues/872"
```

---

## Task 6: 채팅 탭(목록) 화면 재연결 구독

**Files:**
- Modify: `lib/screens/chat_tab_screen.dart`

- [ ] **Step 1: 재연결 구독 필드 추가**

`_ChatTabScreenState`의 필드 영역(기존 `String? _myMemberId;`, line 69 근처)에 추가:

```dart
  // 재연결 이벤트 구독
  StreamSubscription<void>? _reconnectSubscription;
```

- [ ] **Step 2: `_initializeWebSocket`에서 재연결 스트림 구독**

기존 `_initializeWebSocket`(line 95-111)의 `await _wsService.connect();` 아래에 추가:

```dart
      // 재연결 시 목록 갱신 (단절 동안 변경된 lastMessage/unreadCount 복구)
      _reconnectSubscription = _wsService.onReconnected.listen((_) {
        if (!mounted) return;
        _loadChatRooms(mode: LoadMode.refresh);
      });
```

- [ ] **Step 3: `dispose`에서 구독 취소**

기존 `dispose`(line 444-459)의 `_roomSubscriptions.clear();` 아래에 추가:

```dart
    _reconnectSubscription?.cancel();
```

- [ ] **Step 4: `dart format` 실행**

Run (에이전트 수행): `dart format --line-length=120 lib/screens/chat_tab_screen.dart`
Expected: 포맷 적용 완료.

- [ ] **Step 5: 커밋 (사용자 승인 후)**

```bash
git add lib/screens/chat_tab_screen.dart
git commit -m "갤럭시 채팅 실시간 미표시 : feat : 채팅 목록 화면 재연결 시 목록 갱신 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/872"
```

---

## Task 7: 통합 수동 검증

**Files:** 없음 (검증만)

- [ ] **Step 1: 사용자 환경에서 린트 통과 확인**

Run (사용자 환경): `flutter analyze`
Expected: No issues found (또는 기존과 동일, 신규 이슈 없음).

- [ ] **Step 2: 단위 테스트 통과 확인**

Run (사용자 환경): `flutter test test/services/chat_message_merge_test.dart`
Expected: PASS.

- [ ] **Step 3: 갤럭시 실기기 수동 시나리오**

1. 갤럭시 기기로 채팅방 진입
2. 비행기 모드 ON (WS 강제 단절)
3. 다른 기기/계정에서 해당 방에 메시지 전송
4. 비행기 모드 OFF (재연결 유도)
5. **기대**: 재연결 후 단절 중 받은 메시지가 화면에 누락 없이 표시됨. 시각이 원본대로 표시됨(밀림 없음).
6. 메시지 전송 시: 연결 상태와 무관하게 즉시 화면에 표시됨(낙관적 삽입).

- [ ] **Step 4: 검증 결과를 #872에 댓글로 기록 (선택)**

`/cassiiopeia:github`로 검증 결과 댓글 게시.

---

## Self-Review 결과

**1. Spec coverage:**
- 스펙 §3 재연결 이벤트 스트림 → Task 1 ✅
- 스펙 §4 재동기화 + ID 병합 → Task 3(병합 함수) + Task 4(재동기화 호출) ✅
- 스펙 §5 낙관적 삽입 → Task 5 ✅
- 스펙 §6 시각 폴백 제거 → Task 2 ✅
- 스펙 §7 에러처리/엣지(`_isResyncing`, mounted, tab 동기화) → Task 4(_isResyncing/mounted) + Task 6(tab) ✅
- 스펙 §8 테스트 → Task 3(단위) + Task 7(수동) ✅

**2. Placeholder scan:** 모든 코드 단계에 실제 코드 포함. "적절히 처리" 류 없음. ✅

**3. Type consistency:** `mergeServerMessages({required current, required serverMessages})` 시그니처가 Task 3 정의·테스트·Task 4 호출에서 동일. `onReconnected`/`_reconnectController`/`_hasConnectedBefore`/`_isResyncing`/`_reconnectSubscription` 명칭 전 Task 일관. ✅
