# 갤럭시 채팅 실시간 미표시 수정 — 재연결 동기화 설계

- **이슈**: [#872](https://github.com/TEAM-ROMROM/RomRom-FE/issues/872)
- **작성일**: 2026-05-27
- **범위**: 프론트엔드 (Flutter)

---

## 1. 배경 & 근본 원인

갤럭시(Android)에서 채팅 메시지가 실시간으로 표시되지 않는다. FCM 푸시는 즉시 오지만 채팅방 화면에는 메시지가 지연/누락된다. iOS는 정상.

**서버 로그 분석 (2026-05-27 14:31~14:34)**로 확정된 근본 원인:

- 서버는 정상 (저장 → 브로커 송출 → FCM 발행 모두 성공)
- **Android STOMP WebSocket 연결이 idle 구간마다 9~25초 주기로 단절·재연결 반복**
- 단절 구간에 브로드캐스트된 메시지는 STOMP가 재전송하지 않아 **유실**
- 재연결 후 `getChatMessages` 재조회를 하지 않아 화면 미갱신 → "재접속하면 보임"
- FCM은 별개 경로 → "푸시는 오는데 채팅엔 안 뜸"

**업계 표준 관점**: 모바일 실시간 채팅은 연결 단절을 정상 상황으로 가정하고, 3개 층으로 구성한다.

| 층 | 역할 | 본 앱 현황 |
|----|------|-----------|
| 1. 실시간 채널 (WebSocket) | 연결 시 즉시 push | ✅ 있음 (Android에서 자주 끊김) |
| 2. 재연결 동기화 (Sync) | 끊김 구간 메시지 복구 | ❌ **없음 — 본 작업으로 추가** |
| 3. 푸시 (FCM/APNs) | 앱 비활성 시 알림 | ✅ 있음 |

본 앱은 **2층(동기화)이 통째로 빠져** 있다. 본 설계는 이 동기화 층을 추가한다.

## 2. 목표 & 범위

**목표**: WebSocket 단절 시에도 메시지 유실 없이 화면에 표시 (defense-in-depth).

**범위 (프론트엔드)**:
- 재연결 시 메시지 재조회 + ID 기반 병합
- 내 텍스트 메시지 낙관적 삽입 (WS 에코 대기 제거)
- 시각 폴백 `DateTime.now()` 제거 (가짜 시각 방지)

**범위 밖**:
- heartbeat/프록시 단절 트리거 확정 (logcat 필요, 별도 후속)
- 백엔드 sequence number 기반 정밀 동기화 (백엔드 변경 필요)

단절 트리거가 heartbeat 미스든 프록시 idle timeout이든, 본 수정은 **유실을 복구**하므로 트리거와 무관하게 증상을 제거한다.

## 3. 아키텍처 — 재연결 이벤트 스트림

```
ChatWebSocketService (싱글톤)
  ├─ bool _hasConnectedBefore          ← 신규 플래그
  ├─ StreamController<void> _reconnectController (broadcast)  ← 신규
  ├─ Stream<void> get onReconnected     ← 신규 공개 스트림
  └─ _onConnect 콜백
       ├─ 최초 연결: 기존 _resubscribeAll() 만 수행
       └─ 재연결(_hasConnectedBefore==true): _resubscribeAll() + _reconnectController.add(null)

ChatRoomScreen / ChatTabScreen
  └─ onReconnected.listen( → 재조회 → ID 병합 )   ← 신규 구독
```

**최초/재연결 구분**: `_onConnect`에서 `_hasConnectedBefore`가 이미 `true`면 재연결로 판단해 `onReconnected` 방송. 첫 연결은 화면이 `_loadInitialData`에서 이미 초기 조회하므로 방송 불필요. `_onConnect` 진입 시 항상 `_hasConnectedBefore = true`로 설정.

**디스포즈**: `disconnect()`에서 `_reconnectController`를 닫지 않는다(싱글톤이라 앱 생애 유지). 화면은 자신의 `StreamSubscription`만 `dispose`에서 취소.

## 4. 데이터 흐름 — 재동기화 + ID 병합

재연결 이벤트 수신 시 화면 동작:

1. `getChatMessages(pageNumber: 0, pageSize: 50)` 재조회 (최신 50개)
2. 받은 서버 메시지를 현재 `_messages`와 `chatMessageId`로 대조
3. 목록에 없는 서버 메시지만 삽입, 이미 있으면 서버 버전으로 교정 (시각 포함)
4. **낙관적 로컬 메시지(`_pendingLocalMessages`)·업로드 중 이미지(`_uploadingLocalIds`)는 보존** — 서버에 아직 없으므로 건드리지 않음
5. 서버 `createdDate` 기준 재정렬 (`_messages`는 reverse 정렬: index 0 = 최신)

기존 `_handleIncomingMessage`(chat_room_screen.dart:371)의 중복 제거와 동일한 ID 키를 사용해 일관성 유지. 재사용 가능한 `_mergeServerMessages(List<ChatMessage> serverMessages)` 헬퍼로 추출하여 단위 테스트 가능하게 한다.

## 5. 내 메시지 낙관적 삽입

현재 `_sendMessage`(chat_room_screen.dart:444)는 로컬 삽입 없이 WS 에코만 기다린다 → 연결이 끊기면 본인 메시지조차 표시되지 않는다.

**변경**: 전송 즉시 로컬 메시지를 삽입한다 (이미지 전송 `_sendImage`와 동일 패턴).
- `local_{microsecondsSinceEpoch}` 임시 `chatMessageId` 부여
- `_pendingLocalMessages`에 등록
- WS 에코 도착 시 기존 `_handleIncomingMessage` 매칭 로직(chat_room_screen.dart:387-419)이 실제 서버 메시지로 교체 — **이미 구현되어 있음**

결과: 내가 보낸 메시지는 연결 상태와 무관하게 즉시 표시되고, 전송 확인은 비동기로 처리된다 (업계 표준).

`_sendMessage`의 기존 `_isSendingMessage` 타임아웃 타이머(line 451-457)는 유지하되, 낙관적 삽입과 충돌하지 않도록 전송 실패 시 로컬 메시지에 실패 표식을 남기는 것은 본 범위 밖(후속). 타임아웃 시 스낵바만 유지.

## 6. 시각 폴백 제거

`chat_websocket_service.dart:313`:

```dart
// 현재
final finalCreated = headerTs ?? payloadTs ?? DateTime.now();
// 변경
final finalCreated = headerTs ?? payloadTs; // 시각 출처 없으면 null 유지
```

`ChatMessage.createdDate`는 `DateTime?`이고, `formatMessageTime(DateTime? dt)`·`isSameMinute(DateTime? a, b)` 모두 nullable을 받으므로 null 전달이 안전하다 (코드 확인 완료).

가짜 `now()` 시각을 찍지 않으므로 "46분→51분 밀림"이 방지되고, 재동기화 시 서버 `createdDate`로 정확히 교정된다.

**점검 사항(구현 중)**: `_messages` 정렬 로직이 `createdDate == null`을 견디는지 확인. null이면 정렬에서 맨 뒤(또는 삽입 순서 유지)로 처리.

## 7. 에러 처리 & 엣지 케이스

- **재조회 실패**: 조용히 무시하고 다음 재연결 때 재시도. 백그라운드 동기화이므로 스낵바 미표시.
- **재연결 폭주**: 짧은 간격 반복 재연결 시 재조회 중복 방지용 `_isResyncing` 플래그 (`Set` 불필요, 단일 bool).
- **화면 dispose 후 이벤트 도착**: `mounted` 체크 후 setState.
- **chat_tab_screen 동기화**: 목록 화면도 `onReconnected` 구독해 각 방의 lastMessage/unreadCount 갱신 (`_loadChatRooms(mode: refresh)` 또는 경량 재조회).

## 8. 테스트 전략

내부망 환경이라 `flutter analyze`/`build`/`pub get` 불가. `dart format`만 가능. 린트/빌드는 사용자가 별도 환경에서 수행.

- **수동 검증**: 비행기 모드 토글로 WS 강제 단절 → 그 사이 상대 메시지 전송 → 재연결 시 화면에 누락 없이 표시되는지 확인.
- **단위 테스트 가능 지점**: `_mergeServerMessages` ID 병합 로직을 순수 함수로 추출하면 입력 리스트 → 병합 결과 검증 가능 (낙관적 메시지 보존, 중복 제거, 시각 교정).

## 9. 변경 파일 요약

| 파일 | 변경 |
|------|------|
| `lib/services/chat_websocket_service.dart` | `onReconnected` 스트림 + `_hasConnectedBefore` 추가, `_onConnect` 분기, 시각 폴백 `now()` 제거 |
| `lib/screens/chat_room_screen.dart` | `onReconnected` 구독 + `_mergeServerMessages` 헬퍼 + `_isResyncing` 플래그, `_sendMessage` 낙관적 삽입 |
| `lib/screens/chat_tab_screen.dart` | `onReconnected` 구독 → 목록 재조회 |
