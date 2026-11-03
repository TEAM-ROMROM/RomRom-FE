# 이슈 #971 구현 계획

설계: `docs/superpowers/specs/2026-11-03-issue-971-chat-review-ux-design.md`

각 Task: 실패 테스트 작성 > 구현 > 테스트 통과. 마지막에 format > analyze > test 전체.

## Task 1. 채팅 메시지 순수 함수
- `lib/enums/chat_message_send_status.dart` 추가
- `lib/utils/chat_room_message_rules.dart`: `resolveMessageSendStatus`, `appendOlderMessages`, `findPendingLocalIdsConfirmedByServer`, `mergeServerEchoIntoLocalMessage` 위도·경도 보존, `buildLocalMessageId`
- 테스트: `test/utils/chat_room_message_rules_test.dart`

## Task 2. 채팅방 전송 상태·재전송·사진 입력 글·위치
- `chat_room_screen.dart` 필드, `chat_room_messaging.dart`, `chat_room_attachment_sending.dart`
- `chat_message_item.dart`, `chat_room_message_list.dart`, 새 위젯 `lib/widgets/chat_room/chat_message_send_status_view.dart`

## Task 3. 이전 메시지 페이징
- `chat_room_initial_load.dart`(첫 페이지 끝 여부), 새 part `chat_room_older_messages_paging.dart`(스크롤 리스너·`_loadOlderMessages`), 목록 맨 위 로딩 표시

## Task 4. 완료 요청 카드 중복·문구·복사·후기 쓰기 버튼
- `chat_room_trade_actions.dart`, `chat_message_item.dart`

## Task 5. 위치 선택 폴백 안내
- `chat_location_picker_screen.dart`

## Task 6. 채팅 목록·탭바
- `chat_rooms_state.dart` `hasUnreadMessages`, `chat_rooms_provider.dart` 모르는 방 재조회·loadMore 예외 전달
- `chat_tab_screen.dart` 탭 선택 재조회·필터 이어 불러오기·실패 스낵바
- `custom_bottom_navigation_bar.dart` 배지, 채팅방 진입·퇴장 읽음 처리
- 테스트: `test/providers/chat_rooms_provider_test.dart`, `test/states/`

## Task 7. 상대 선택·앱 밖 교환
- `lib/models/trade_complete_partner_selection.dart`, `trade_complete_partner_select_screen.dart`, `register_tab_screen.dart`(교환 완료 블록만)

## Task 8. 후기 화면
- `lib/utils/trade_review_rules.dart` + 테스트, `trade_review_screen.dart`

## Task 9. 검증
- `dart format --line-length=120 .` > `flutter analyze` > `flutter test`, diff 자체 점검
