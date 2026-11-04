# 채팅 확장 설계 (FE #1006 · BE #860)

방별 알림 끄기, 내 메시지 삭제, 메시지 신고, 약속 카드·리마인드. 스토어 v1.10.142 앱 호환 유지가 전제.

## 옛 앱(v1.10.142) 호환 근거
- 옛 앱 `ChatMessage.type`은 `$enumDecodeNullable` > 모르는 값이면 예외 > 목록 조회 통째 실패. 새 MessageType 추가 금지
- `SYSTEM` 수신 = "상대가 나감" 처리(입력창 잠금) > 약속 상태 알림에 SYSTEM 사용 금지
- json_serializable 기본값 = 모르는 키 무시 > 새 필드 추가는 안전
- 옛 앱은 `/sub/chat.room.{id}` 만 구독 > 수정 이벤트는 새 토픽으로 보내 옛 앱이 받지 않게 함
- 알림 타입 `fromServerName` 은 모르는 값 > null 이지만, 리마인드는 기존 `CHAT_MESSAGE_RECEIVED` 재사용 (+ `chatPushKind`)
- 결정: 옛 앱을 막는 동작이 없어 app_config 스위치 없음

## API (전부 POST multipart, 인증 필수)
| 경로 | 요청 | 응답 |
|---|---|---|
| `/api/chat/rooms/notification-mute/update` | chatRoomId, isNotificationMuted | `isNotificationMuted` |
| `/api/chat/rooms/messages/delete` | chatRoomId, chatMessageId | `chatMessage` (삭제 반영본) |
| `/api/chat/rooms/appointments/propose` | chatRoomId, appointmentAt(`2026-11-06T15:00:00`, KST), placeName(1~50자), latitude?, longitude? | `chatMessage` |
| `/api/chat/rooms/appointments/accept` | chatRoomId, chatMessageId | `chatMessage` |
| `/api/chat/rooms/appointments/cancel` | chatRoomId, chatMessageId | `chatMessage` |
| `/api/report/chat-message/post` | chatRoomId, chatMessageId, memberReportReasons(1~5), extraComment | 200 |

- 목록 `ChatRoomDetailDto.isNotificationMuted`, 메시지 조회 `ChatRoomResponse.isNotificationMuted` (내 설정만, 상대 상태는 노출 안 함)
- `ChatMessage` 추가 필드: `isDeleted`, `appointment { appointmentAt, placeName, latitude, longitude, status(PROPOSED|ACCEPTED|CANCELED), statusChangedMemberId }`

## STOMP
- 새 토픽 `/sub/chat.update.{chatRoomId}`: 이미 있는 메시지의 변경본(ChatMessage 모양) > chatMessageId 로 교체
- 사용처 2개: 메시지 삭제, 약속 상태 변경. 새 약속 제안은 기존 `/sub/chat.room.{id}` 로 TEXT 메시지 전송

## 1. 방별 알림 끄기
- 저장: Mongo `ChatUserState.notificationMutedAt` (null = 켜짐, JSON 비노출)
- 끈 방: 채팅 FCM 미발송, 안 읽음 수는 그대로 (결정)
- FE: 채팅방 메뉴 "알림 끄기/켜기", 목록 행에 음소거 아이콘

## 2. 내 메시지 삭제
- 보낸 사람만, 보낸 지 24시간 이내 (결정), TEXT·IMAGE·LOCATION 만, 약속 메시지는 삭제 대신 취소 (결정)
- soft delete (`deletedAt`, 원본 보존: 관리자·신고 확인용)
- 회원 조회 응답: content "삭제된 메시지입니다.", type TEXT, 사진·좌표·약속 제거 > 옛 앱은 글자로 표시
- 오류: CHAT_MESSAGE_NOT_FOUND, CHAT_MESSAGE_DELETE_NOT_SENDER, CHAT_MESSAGE_DELETE_PERIOD_EXPIRED, CHAT_MESSAGE_NOT_DELETABLE

## 3. 메시지 신고
- Report 도메인 재사용: 새 테이블 `chat_message_report` (+ 사유 `chat_message_report_reason`), Flyway V1_4_71
- 사유는 회원 신고 사유(MemberReportReason) 재사용 (결정), 신고 시점 본문 스냅샷 저장
- 상대 메시지만, 같은 메시지 중복 신고 금지 (DUPLICATE_CHAT_MESSAGE_REPORT), 관리자 메일 알림 유형 "채팅 메시지 신고"
- 관리자 목록 화면은 이번 범위 밖 (후속)

## 4. 약속 카드
- 새 타입 없이 TEXT + `appointment` 필드 (결정). 본문 예: `[약속] 11월 6일 (금) 오후 3:00 · 군자역`
- 상태 변경 시 본문도 `[약속 확정] ...` / `[약속 취소] ...` 로 갱신 > 옛 앱은 다시 들어오면 최신 상태 글자 확인
- 수락: 제안 받은 사람만, PROPOSED 이고 약속 시각 전 (결정) / 취소: 양쪽 모두, PROPOSED·ACCEPTED
- 수락·취소 시 상대가 방 밖이고 알림 켜짐이면 채팅 푸시 ("약속을 수락했어요" 등)
- 오류: INVALID_CHAT_APPOINTMENT, CHAT_APPOINTMENT_ACCEPT_FORBIDDEN, CHAT_APPOINTMENT_STATUS_CONFLICT

## 5. 약속 리마인드
- `@Scheduled` 1분 간격 (스케줄링 기존 활성), 확정 약속 시각 60분 전부터 1회
- Mongo findAndModify 로 건별 선점 > 블루그린 동시 실행 중복 발송 방지
- 양쪽 회원에게 발송, 방별 알림 끄기 무시 (결정), 전역 채팅 알림 동의는 따름, 나간 회원 제외
- 푸시: type CHAT_MESSAGE_RECEIVED, `chatPushKind=APPOINTMENT_REMINDER`, deepLink 채팅방

## FE
- 메시지 길게 누르기: 복사(기존) + 내 메시지 24시간 내 삭제 + 상대 메시지 신고 (기존 신고 사유 UI 재사용)
- 삭제 말풍선 "삭제된 메시지입니다.", 약속 카드(수락·취소 버튼), 첨부 메뉴 "약속 잡기" (날짜·시간·장소)
- 공유 상태: 목록의 알림 끄기 값은 `chatRoomsProvider` 가 소유
