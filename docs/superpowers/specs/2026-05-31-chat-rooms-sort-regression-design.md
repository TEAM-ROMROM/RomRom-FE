# 채팅방 목록 최신순 정렬 회귀 수정 (이슈 #884)

- **이슈**: https://github.com/TEAM-ROMROM/RomRom-FE/issues/884
- **작성일**: 2026-05-31
- **유형**: 버그 수정 (회귀 복원)

## 배경

이슈 #884는 "채팅방 목록이 마지막 메시지 시각(`lastMessageTime`) 최신순으로 정렬되지 않는다"는 버그다. 원인은 백엔드 `getRooms`가 채팅방 생성일(`createdDate`) 내림차순으로만 정렬하고, `ChatRoom`(PostgreSQL)과 `ChatMessage`(MongoDB)가 분리되어 있어 백엔드에서 `lastMessageTime` 기준 SQL 정렬이 불가능하기 때문이다. 따라서 **정렬은 프론트가 책임진다.**

884는 커밋 `5246d72`에서 `chat_tab_screen.dart`에 `_sortRoomsByRecent()`를 추가해 **모든 갱신 경로(초기 로드/페이징/WS 수신)에서 `lastMessageTime` 내림차순 정렬**을 보장하는 것으로 해결됐고 main에 머지됐다.

## 회귀(Regression) 발생 경위

884(`5246d72`) **이후**, 이슈 #882 Riverpod 중앙화 리팩토링(`afb9dc2`, `63ca9de`)이 채팅방 목록을 `chatRoomsProvider`(AsyncNotifier) + `ChatRoomsState`로 전면 교체했다. 이 과정에서 **884의 `_sortRoomsByRecent()` 정렬 로직이 새 provider/state로 이관되지 않고 누락**됐다.

현재(main 기준) `chat_rooms_provider.dart` 상태:

| 경로 | 884 fix (이관 전) | 현재 (882 후) | 정렬 보장 |
|------|------------------|--------------|----------|
| 초기 로드 `_fetchPage0` | `_sortRoomsByRecent()` | 정렬 없음 | ❌ |
| 새로고침 `reload` | `_sortRoomsByRecent()` | 정렬 없음 | ❌ |
| 페이징 `loadMore` | `_sortRoomsByRecent()` | 정렬 없음 | ❌ |
| WS 수신 `onMessageReceived` | `_sortRoomsByRecent()` | `[updated, ...나머지]` 맨앞 이동만 | ⚠️ (정렬 아님) |

결과적으로 이슈 #884가 명시한 "WebSocket 미수신 경로(초기 로드, 재연결 직후 재조회)에서 최신순이 보장되지 않는다" 문제가 그대로 다시 발생한 상태다.

## 목표

884가 한때 보장했던 정렬 동작을 882 구조(Riverpod 단일 소유)에 맞게 **복원**한다. 새 동작을 추가하지 않고, 검증된 884 원본 로직을 그대로 이관하는 것이 원칙이다.

## 설계

### 핵심 결정: 정렬을 `ChatRoomsState` 생성자에 내장

882 구조에서 채팅방 목록의 **단일 소유자는 `ChatRoomsState.rooms`**다. 정렬 책임을 State 생성자에 내장하면:

- `_fetchPage0`, `reload`, `loadMore`, `onMessageReceived` 등 **어느 경로로 rooms가 들어와도** State를 거치며 자동 정렬된다.
- `copyWith`도 같은 생성자를 통하므로 정렬이 깨질 수 없다 (누락 불가능).
- 향후 새 mutation 메서드가 추가돼도 정렬 호출을 깜빡할 위험이 없다.

이는 CLAUDE.md의 "공유 도메인 상태는 Riverpod provider 하나가 단일 소유" 원칙과도 일치한다.

### 정렬 로직: 884 원본 그대로

884가 main에서 검증한 비교 함수를 그대로 사용한다. 새로운 2차 정렬키 등은 추가하지 않는다.

```dart
// lastMessageTime 내림차순 (최신 메시지가 위), null은 맨 뒤
rooms.sort((a, b) {
  final ta = a.lastMessageTime;
  final tb = b.lastMessageTime;
  if (ta == null && tb == null) return 0;
  if (ta == null) return 1;
  if (tb == null) return -1;
  return tb.compareTo(ta);
});
```

> null 방은 이슈 본문에 따르면 "BE가 `createdDate`로 채워줘서 사실상 거의 없음". 동률 처리는 884 원본대로 `return 0`을 유지한다.

### 변경 1 — `lib/states/chat_rooms_state.dart`

생성자에서 받은 `rooms`를 정렬해 보관한다. `const` 생성자는 정렬(런타임 연산)과 양립할 수 없으므로 `const`를 제거하고 일반 생성자로 바꾼다.

- 정렬은 원본 리스트를 변형하지 않도록 복사본(`[...rooms]`)에 적용한다.
- 정렬 로직은 `static` 헬퍼로 분리해 가독성을 확보한다.
- 빈 리스트 기본값(`const []`)은 그대로 두되, 생성자가 비-const가 되므로 필드 기본값 처리만 조정한다.

### 변경 2 — `lib/providers/chat_rooms_provider.dart`

`onMessageReceived`의 `[updated, ...나머지]` 맨앞 꽂기를 제거한다. 해당 방의 `lastMessageTime`/`unreadCount`만 갱신한 새 리스트를 State에 넘기면, State 생성자가 자동으로 최신순 정렬한다.

```dart
// 변경 후 (맨앞 꽂기 제거, 정렬 위임)
final newRooms = [...cur.rooms];
newRooms[idx] = updated;
state = AsyncData(cur.copyWith(rooms: newRooms));
```

`_fetchPage0`, `reload`, `loadMore`는 코드 변경 없이 State 자동 정렬의 혜택을 받는다 (별도 수정 불필요).

## 영향 범위

- 화면(`chat_tab_screen.dart`)은 `chatRoomsProvider`를 구독만 하므로 **변경 없음**.
- State `==`/`hashCode`는 `rooms` 내용 기반이라 정렬 후에도 정상 동작. 정렬로 순서가 바뀐 리스트는 다른 State로 간주되어 의도대로 리빌드된다.

## 테스트 / 검증

- `dart format --line-length=120 .` + `flutter analyze` 통과.
- 수동 검증(QA 테스트케이스):
  1. 채팅방 2개 이상, 가장 오래전 생성된 방에 새 메시지 수신 → 최상단으로 이동 확인
  2. 앱 재진입(초기 로드) 시 최신 메시지 방이 맨 위 확인
  3. 당겨서 새로고침(reload) 후 정렬 유지 확인
  4. WebSocket 재연결 후 재조회 시 정렬 유지 확인

## 비목표 (YAGNI)

- 백엔드 정렬 변경 (구조상 불가, 프론트 정렬이 정답)
- chatRoomId 2차 정렬키 등 884에 없던 신규 동작 추가
- repository/화면 레이어 수정
