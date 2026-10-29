# 채팅방 목록 최신순 정렬 회귀 수정 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 882 Riverpod 리팩토링에서 누락된 884의 채팅방 목록 `lastMessageTime` 최신순 정렬을 `ChatRoomsState`에 복원한다.

**Architecture:** 정렬 책임을 `ChatRoomsState` 생성자에 내장한다. 채팅방 목록의 단일 소유자가 State이므로, 어느 경로(초기 로드/새로고침/페이징/WS 수신)로 rooms가 들어와도 State를 거치며 자동 정렬된다. `onMessageReceived`의 수동 맨앞꽂기는 제거하고 정렬에 위임한다.

**Tech Stack:** Flutter, Riverpod (AsyncNotifier), flutter_test

**Spec:** `docs/superpowers/specs/2026-05-31-chat-rooms-sort-regression-design.md`
**이슈:** https://github.com/TEAM-ROMROM/RomRom-FE/issues/884

---

## File Structure

- **Modify** `lib/states/chat_rooms_state.dart` — 생성자에서 `rooms`를 `lastMessageTime` 내림차순 정렬해 보관. `const` 생성자 → 일반 생성자.
- **Modify** `lib/providers/chat_rooms_provider.dart` — `onMessageReceived`의 `[updated, ...나머지]` 맨앞꽂기 제거, 해당 방만 갱신 후 정렬 위임.
- **Create** `test/states/chat_rooms_state_test.dart` — State 정렬 동작 검증.
- **Create** `test/providers/chat_rooms_provider_sort_test.dart` — `onMessageReceived` 후 정렬 검증 (선택: provider 테스트가 repository mock을 요구하면 Task 3에서 결정).

> 정렬 비교 함수는 884 원본(`5246d72`)을 그대로 사용한다. 신규 정렬키(chatRoomId 2차 정렬 등)는 추가하지 않는다.

---

### Task 1: ChatRoomsState 생성자에 정렬 내장

**Files:**
- Modify: `lib/states/chat_rooms_state.dart`
- Test: `test/states/chat_rooms_state_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/states/chat_rooms_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';

ChatRoomDetailDto room(String id, DateTime? t) => ChatRoomDetailDto(chatRoomId: id, lastMessageTime: t);

void main() {
  group('ChatRoomsState 정렬', () {
    test('생성자는 rooms를 lastMessageTime 내림차순으로 정렬한다', () {
      final state = ChatRoomsState(rooms: [
        room('a', DateTime(2026, 1, 1)),
        room('b', DateTime(2026, 3, 1)),
        room('c', DateTime(2026, 2, 1)),
      ]);
      expect(state.rooms.map((r) => r.chatRoomId).toList(), ['b', 'c', 'a']);
    });

    test('lastMessageTime이 null인 방은 맨 뒤로 간다', () {
      final state = ChatRoomsState(rooms: [
        room('a', null),
        room('b', DateTime(2026, 1, 1)),
      ]);
      expect(state.rooms.map((r) => r.chatRoomId).toList(), ['b', 'a']);
    });

    test('copyWith로 rooms를 바꿔도 정렬이 유지된다', () {
      final state = ChatRoomsState(rooms: [room('a', DateTime(2026, 1, 1))]);
      final next = state.copyWith(rooms: [
        room('x', DateTime(2026, 1, 1)),
        room('y', DateTime(2026, 5, 1)),
      ]);
      expect(next.rooms.map((r) => r.chatRoomId).toList(), ['y', 'x']);
    });

    test('정렬은 원본 입력 리스트를 변형하지 않는다', () {
      final input = [room('a', DateTime(2026, 1, 1)), room('b', DateTime(2026, 5, 1))];
      ChatRoomsState(rooms: input);
      expect(input.map((r) => r.chatRoomId).toList(), ['a', 'b']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `source ~/.zshrc && flutter test test/states/chat_rooms_state_test.dart`
Expected: FAIL — 현재 State는 정렬하지 않으므로 첫 테스트가 `['a','b','c']` 등 입력 순서를 반환해 기대값과 불일치.

- [ ] **Step 3: Write minimal implementation**

`lib/states/chat_rooms_state.dart` 전체를 아래로 교체:

```dart
// lib/states/chat_rooms_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';

@immutable
class ChatRoomsState {
  /// 차단(blocked == true) 제외 + lastMessageTime 내림차순 정렬된 채팅방 목록.
  final List<ChatRoomDetailDto> rooms;

  /// 마지막으로 로드한 페이지 번호 (0-based).
  final int currentPage;

  /// 다음 페이지가 존재하는지 여부.
  final bool hasMore;

  /// rooms는 생성 시점에 항상 최신순 정렬되어 보관된다.
  /// 채팅방 목록의 단일 소유자이므로, 모든 갱신 경로(초기 로드/새로고침/페이징/WS 수신)가
  /// 이 생성자를 거치며 정렬이 보장된다 (이슈 #884).
  ChatRoomsState({List<ChatRoomDetailDto> rooms = const [], this.currentPage = 0, this.hasMore = true})
      : rooms = _sortByRecent(rooms);

  /// lastMessageTime 내림차순(최신이 위), null은 맨 뒤. 884 원본 로직 그대로.
  static List<ChatRoomDetailDto> _sortByRecent(List<ChatRoomDetailDto> rooms) {
    final sorted = [...rooms];
    sorted.sort((a, b) {
      final ta = a.lastMessageTime;
      final tb = b.lastMessageTime;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return sorted;
  }

  ChatRoomsState copyWith({List<ChatRoomDetailDto>? rooms, int? currentPage, bool? hasMore}) => ChatRoomsState(
        rooms: rooms ?? this.rooms,
        currentPage: currentPage ?? this.currentPage,
        hasMore: hasMore ?? this.hasMore,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomsState &&
          runtimeType == other.runtimeType &&
          listEquals(rooms, other.rooms) &&
          currentPage == other.currentPage &&
          hasMore == other.hasMore;

  @override
  int get hashCode => Object.hash(Object.hashAll(rooms), currentPage, hasMore);

  @override
  String toString() => 'ChatRoomsState(rooms: ${rooms.length}, page: $currentPage, hasMore: $hasMore)';
}
```

> 주의: 정렬이 런타임 연산이므로 `const` 생성자를 제거했다. 외부에 `const ChatRoomsState()` 호출처는 없음(확인 완료).

- [ ] **Step 4: Run test to verify it passes**

Run: `source ~/.zshrc && flutter test test/states/chat_rooms_state_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Format & analyze**

Run: `source ~/.zshrc && dart format --line-length=120 lib/states/chat_rooms_state.dart test/states/chat_rooms_state_test.dart && flutter analyze lib/states/chat_rooms_state.dart`
Expected: 포맷 적용됨, analyze 에러 없음.

- [ ] **Step 6: Commit (사용자 승인 후에만)**

> ⚠️ CLAUDE.md 규칙: 사용자가 명시적으로 "커밋해줘"라고 요청하기 전에는 `git add`/`git commit`을 실행하지 않는다. 이 단계는 사용자 승인 시에만 수행한다.

```bash
git add lib/states/chat_rooms_state.dart test/states/chat_rooms_state_test.dart
git commit -m "채팅방 목록이 마지막 메시지 최신순으로 정렬되지 않음 : fix : ChatRoomsState 생성자에 lastMessageTime 내림차순 정렬 내장 https://github.com/TEAM-ROMROM/RomRom-FE/issues/884"
```

---

### Task 2: onMessageReceived 맨앞꽂기 제거 → 정렬 위임

**Files:**
- Modify: `lib/providers/chat_rooms_provider.dart:50-71` (`onMessageReceived` 메서드)

- [ ] **Step 1: 현재 onMessageReceived 끝부분 확인**

현재 코드(`lib/providers/chat_rooms_provider.dart`)의 `onMessageReceived` 마지막 부분:

```dart
    final updated = room.copyWith(
      lastMessageContent: message.content ?? '',
      lastMessageTime: message.createdDate ?? DateTime.now(),
      unreadCount: newUnreadCount,
    );

    final reordered = [updated, ...cur.rooms.where((r) => r.chatRoomId != roomId)];
    state = AsyncData(cur.copyWith(rooms: reordered));
  }
```

- [ ] **Step 2: 맨앞꽂기를 인덱스 갱신으로 교체**

위 블록의 마지막 두 줄(`final reordered ...` ~ `state = AsyncData(...)`)을 아래로 교체:

```dart
    final updated = room.copyWith(
      lastMessageContent: message.content ?? '',
      lastMessageTime: message.createdDate ?? DateTime.now(),
      unreadCount: newUnreadCount,
    );

    // 해당 방만 갱신한다. 목록 순서는 ChatRoomsState 생성자가
    // lastMessageTime 내림차순으로 자동 정렬하므로 수동 맨앞 이동은 불필요 (이슈 #884).
    final newRooms = [...cur.rooms];
    newRooms[idx] = updated;
    state = AsyncData(cur.copyWith(rooms: newRooms));
  }
```

> `idx`는 같은 메서드 앞부분에서 `cur.rooms.indexWhere((r) => r.chatRoomId == roomId)`로 이미 계산되어 있고 `idx == -1`이면 early return 처리됨. 그대로 재사용한다.

- [ ] **Step 3: Format & analyze**

Run: `source ~/.zshrc && dart format --line-length=120 lib/providers/chat_rooms_provider.dart && flutter analyze lib/providers/chat_rooms_provider.dart`
Expected: analyze 에러 없음. (사용 안 하게 된 변수/import 경고 없는지 확인 — `message.content` 등은 여전히 사용됨)

- [ ] **Step 4: 전체 테스트 + 전체 analyze**

Run: `source ~/.zshrc && flutter test test/states/chat_rooms_state_test.dart && flutter analyze`
Expected: 테스트 PASS, analyze 에러 0.

- [ ] **Step 5: Commit (사용자 승인 후에만)**

> ⚠️ 사용자 명시 요청 시에만.

```bash
git add lib/providers/chat_rooms_provider.dart
git commit -m "채팅방 목록이 마지막 메시지 최신순으로 정렬되지 않음 : refactor : onMessageReceived 수동 맨앞이동 제거하고 State 자동정렬에 위임 https://github.com/TEAM-ROMROM/RomRom-FE/issues/884"
```

---

### Task 3: onMessageReceived 정렬 동작 검증 테스트

**Files:**
- Test: `test/providers/chat_rooms_provider_sort_test.dart`

> 목적: WS 수신 시 갱신된 방이 State 정렬을 거쳐 최상단으로 가는지 검증. `ChatRoomsState`를 직접 구성해 정렬 결과만 확인하는 방식으로, repository mock 없이 순수 State 레벨에서 검증한다 (Task 1 테스트로 이미 핵심은 커버되나, "갱신 후 재정렬" 시나리오를 명시적으로 추가).

- [ ] **Step 1: Write the test**

Create `test/providers/chat_rooms_provider_sort_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';

ChatRoomDetailDto room(String id, DateTime t) => ChatRoomDetailDto(chatRoomId: id, lastMessageTime: t);

void main() {
  group('WS 수신 후 정렬 시나리오', () {
    test('오래된 방의 lastMessageTime을 최신으로 갱신하면 맨 위로 올라온다', () {
      // 초기: b(최신) > c > a(가장 오래됨)
      final state = ChatRoomsState(rooms: [
        room('a', DateTime(2026, 1, 1)),
        room('b', DateTime(2026, 3, 1)),
        room('c', DateTime(2026, 2, 1)),
      ]);
      expect(state.rooms.map((r) => r.chatRoomId).toList(), ['b', 'c', 'a']);

      // onMessageReceived와 동일하게 a 방의 시각만 갱신 (맨앞 이동 안 함)
      final idx = state.rooms.indexWhere((r) => r.chatRoomId == 'a');
      final newRooms = [...state.rooms];
      newRooms[idx] = state.rooms[idx].copyWith(lastMessageTime: DateTime(2026, 4, 1));
      final next = state.copyWith(rooms: newRooms);

      // State 자동 정렬로 a가 최상단
      expect(next.rooms.map((r) => r.chatRoomId).toList(), ['a', 'b', 'c']);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

Run: `source ~/.zshrc && flutter test test/providers/chat_rooms_provider_sort_test.dart`
Expected: PASS (1 test). (Task 1 구현으로 이미 동작하므로 이 테스트는 회귀 방지용 — 실패하면 Task 1/2 구현 누락.)

- [ ] **Step 3: 전체 테스트 + format + analyze**

Run: `source ~/.zshrc && dart format --line-length=120 . && flutter test test/states/chat_rooms_state_test.dart test/providers/chat_rooms_provider_sort_test.dart && flutter analyze`
Expected: 전체 PASS, analyze 에러 0.

- [ ] **Step 4: Commit (사용자 승인 후에만)**

> ⚠️ 사용자 명시 요청 시에만.

```bash
git add test/providers/chat_rooms_provider_sort_test.dart
git commit -m "채팅방 목록이 마지막 메시지 최신순으로 정렬되지 않음 : test : WS 수신 후 State 자동정렬 시나리오 검증 추가 https://github.com/TEAM-ROMROM/RomRom-FE/issues/884"
```

---

## Self-Review

**1. Spec coverage:**
- spec "정렬을 ChatRoomsState 생성자에 내장" → Task 1 ✅
- spec "884 원본 비교 함수 그대로" → Task 1 Step 3의 `_sortByRecent` ✅
- spec "const 생성자 제거" → Task 1 Step 3 주석 + 구현 ✅
- spec "onMessageReceived 맨앞꽂기 제거, 정렬 위임" → Task 2 ✅
- spec "_fetchPage0/reload/loadMore는 변경 불필요" → 변경 없음 (State 통과로 자동 정렬), Task 1 테스트의 copyWith 케이스로 간접 검증 ✅
- spec "화면 변경 없음" → 계획에 화면 수정 태스크 없음 ✅
- spec 테스트 검증 1~4 → Task 1·3 자동화 테스트로 1·2·3 커버, 4(WS 재연결 재조회)는 reload 경로 = copyWith 정렬과 동일 메커니즘이라 Task 1 copyWith 테스트로 커버 ✅
- spec 비목표(chatRoomId 2차키 등) → 추가 안 함 ✅

**2. Placeholder scan:** "TBD"/"TODO"/"적절히 처리" 없음. 모든 코드 블록 완전. ✅

**3. Type consistency:**
- `_sortByRecent(List<ChatRoomDetailDto>) → List<ChatRoomDetailDto>` 일관 ✅
- `ChatRoomDetailDto.lastMessageTime`(DateTime?), `chatRoomId`(String?), `copyWith` — 실제 DTO와 일치 확인 ✅
- `ChatRoomsState({rooms, currentPage, hasMore})` 시그니처 — provider 호출부(`ChatRoomsState(rooms:..., currentPage:..., hasMore:...)`)와 일치 ✅
- `copyWith`/`cur.copyWith(rooms:...)` — provider 호출과 일치 ✅
