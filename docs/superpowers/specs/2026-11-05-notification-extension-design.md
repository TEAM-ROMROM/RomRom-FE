# 알림 확장 설계 (FE #1007, BE #861)

수락·거절·완료·후기 알림, 방해금지 시간, 사용자 공지 상세. 스토어 v1.10.142 앱이 새 서버에서 그대로 동작하는 것을 전제로 한다.

## 1. 새 알림 타입 4종

| 서버 타입 | 발생 지점 (BE) | 받는 사람 | 딥링크 | 수신 동의 |
|---|---|---|---|---|
| `TRADE_REQUEST_ACCEPTED` | `ChatRoomService.createOneToOneRoom` 새 방 생성 (받은 사람이 채팅 시작) | 요청 보낸 사람 | `romrom://chat/room?chatRoomId=` | 교환 알림 |
| `TRADE_REQUEST_REJECTED` | `TradeRequestService.rejectTradeRequest` (저장 방식 미변경, 이벤트만) | 요청 보낸 사람 | `romrom://item/detail?itemId={상대 물품}` | 교환 알림 |
| `TRADE_COMPLETED` | `ChatTradeCompletionService.confirmTradeCompletion` / `TradeRequestService.completeTrade` | 완료 요청한 상대 / 요청 보낸 사람 | 채팅방 / 상대 물품 상세 | 교환 알림 |
| `TRADE_REVIEW_RECEIVED` | `TradeReviewService.postTradeReview` | 후기 받은 사람 | `romrom://profile/reviews` | 활동 알림 |

- 결정: 새 수신 동의 항목 없이 기존 분류에 묶는다 (거래 진행 3종 > `isTradeNotificationAgreed`, 후기 > `isActivityNotificationAgreed`). 설정 화면 설명 문구만 갱신.
- 결정: 이벤트는 `TradeProgressNotificationEvent` 1클래스 + 종류별 정적 생성 메서드, 리스너 1곳 (AFTER_COMMIT, 비동기). 관리자 강제 완료(`AdminTradeService`)는 발송하지 않음.
- Flyway `V1_4_72`: `notification_history_notification_type_check` 제약 제거 (Hibernate가 만든 enum 목록 제약이 있으면 새 타입 기록 저장 실패).

## 2. 옛 앱 호환

- 옛 앱 알림함은 모르는 타입을 공지로 표시하고 "알림 끄기"가 콘텐츠·마케팅 동의를 끈다 (크래시는 없음, `fromServerName ?? announcement`).
- 결정: 목록·미확인 개수 API는 `isExtendedTypeSupported=true`일 때만 확장 타입 포함. 미전달(옛 앱) > 제외. 새 앱은 두 API에 항상 전송.
- FCM은 실제 타입 그대로 발송: 옛 앱은 모르는 타입을 null로 처리(포그라운드 = 알림 목록만 갱신, 탭 = 딥링크 경로로 이동). 수락·거절·완료 딥링크는 옛 앱도 아는 경로, 후기·공지 상세는 모르는 경로 > 알림함 폴백.
- app_config 스위치: 없음 (옛 앱 차단·의미 변경 없음, 모두 추가 필드·추가 값).

## 3. 방해금지 시간

- 저장: `member` 컬럼 3개 `is_do_not_disturb_enabled`(기본 false), `do_not_disturb_start_time`(22:00), `do_not_disturb_end_time`(08:00), KST.
- API: 기존 `POST /api/members/notification/update`에 선택 필드 `isDoNotDisturbEnabled`, `doNotDisturbStartTime`, `doNotDisturbEndTime`(`HH:mm`) 추가. 조회는 회원 프로필 응답 `member`(시각 `HH:mm`).
- 판정 `DoNotDisturbTimeRule`: 시작 포함·종료 제외, 시작 > 종료면 자정 넘김, 시작 = 종료면 구간 없음.
- 동작: `sendToMember`는 기록 저장 후 방해금지 중이면 FCM만 생략. 공지 전체 발송도 회원별 방해금지 제외 (토큰 조회 시 회원 JOIN FETCH).
- FE: 설정 화면 하단 `DoNotDisturbSettingsSection` (스위치 + 시작·종료 행 > 휠 시트, 10분 단위). 상태 `doNotDisturbSettingProvider`(동기 Notifier, optimistic, 진행 중 중복 무시, 실패 롤백). 시작 = 종료는 저장 막고 안내.
- 결정: 방해금지는 푸시를 줄이는 설정이라 알림 권한 확인 없이 켠다.

## 4. 공지 상세

- API: `POST /api/notification/get/announcement` (multipart `announcementId`, JWT) > `{announcement: {announcementId, title, content, imageUrl?, linkUrl?, createdDate}}`. 없으면 `ANNOUNCEMENT_NOT_FOUND`(404).
- 결정: 같은 컨트롤러의 다른 사용자 API와 맞춰 GET 대신 POST multipart.
- 공지 푸시 payload에 `deepLink = romrom://notice/detail?announcementId=` 추가. FE는 딥링크 없는 공지 푸시(배포 전 발송분)도 `announcementId`로 보정.
- 관리자 등록·수정에 선택 `announcementImageUrl`, `announcementLinkUrl` 필드 추가 (관리자 화면 입력 UI는 이번 범위 밖).
- FE `NoticeDetailScreen`: 로딩 > 실패 다시 시도 > 제목·작성일·이미지·본문·"자세히 보기"(romrom:// 앱 내, https:// 외부 브라우저).

## 5. FE 반영

- `NotificationType` 4종 + `unknown` 폴백 (서버 이름 조회 대상 아님, 끄기 메뉴 숨김). 알림함의 모르는 타입은 공지가 아니라 `unknown`.
- 끄기 메뉴: 대응 설정 없는 유형(관리자 제재·unknown)은 숨김 (`canToggleNotificationType`).
- 포그라운드 푸시 갱신: 수락 > 보낸 요청 + 채팅방, 거절 > 보낸 요청, 완료 > 내 물품 + 채팅방, 후기 > 받은 후기(`receivedReviewsRefreshTriggerProvider` 신호 > 열린 내 프로필 후기 재조회). 모두 알림 목록 포함.
- 딥링크 `notice/detail` > 공지 상세, `profile/reviews` > 내 프로필.
