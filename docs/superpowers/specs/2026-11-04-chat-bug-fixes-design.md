# 채팅 버그 11건 수정 설계 (#984)

## 목표
- 끊김 감지·재연결, 같은 방 1회 열기, 메시지 유실·중복·잘못된 스크롤 제거, 목록 페이지·위치 유지
- 동작 범위만 고치고 구조는 유지 (이후 채팅 기능 추가 작업의 바탕)

## 수정 방식
| # | 원인 | 수정 |
|---|---|---|
| 1 | stomp 3.0.1은 소켓 닫힘에 `onWebSocketDone`만 호출 > 연결 상태 true 유지 > 구독 시 `StompBadStateException` | `onWebSocketDone` 등록 > 미연결 표시 (재연결은 StompClient `reconnectDelay` 자동), 구독·전송 실패 시 예외 대신 미연결 표시 > 스트림 유지 후 CONNECTED에 재구독, `waitUntilConnected()` 추가 |
| 2 | 푸시 탭마다 같은 방 push, 전역 폴러를 위 화면이 정지, 회원 ID 미필터 | `OpenChatRoomRegistry`(Provider 주입)로 열린 방·route 맨 위 여부 기록 > 같은 방이 맨 위면 push 생략, 같은 방 다른 화면이 남으면 퇴장 커서 생략. 폴러는 소유자 토큰 스택 (맨 위 화면 상대만 폴링, 위 화면 종료 시 아래 화면 재개), `streamOf(memberId)`로 요청 ID 결과만 |
| 3 | 첫 페이지 조회 후 구독 | 구독 먼저 > 조회 중 수신분 보관 > 조회 결과와 ID 중복 제거 후 반영. 조회 시작 때 미연결이면 연결 후 재조회 1회 |
| 4 | 삭제 후 구독 해제, 내 나가기 방송에 상대 퇴장 모달, pop 2번이 모달만 닫음 | 삭제 전 구독 해제(실패 시 복구·재조회), 내가 보낸 system 메시지 무시, 화면 닫기는 이 route 위 모달 정리 후 pop 1번 (앱바 성공 경로 pop 제거) |
| 5 | 새 메시지마다 맨 아래 이동 | 반영 전 위치가 맨 아래 120px 이내거나 내 메시지일 때만 |
| 6 | 나갈 때마다 pop(true) > 1페이지 재조회, 재조회 방 미구독 | 목록 영향 변경(차단)만 pop(true), 삭제·생성·pop(true)는 `refreshLoadedPages()`(page 0에서 불러온 페이지 수만큼, 페이징 위치 유지), 목록 상태 변경마다 미구독 방만 구독 (`listenManual` fireImmediately) |
| 7 | 안내 시트 노출을 화면 필드로 기억, 시트가 읽음·구독을 막음 | `chatNotificationGuideProvider`(세션 1회, 로그아웃 초기화), 읽음·재연결 구독 먼저 후 안내 순서 실행, await 뒤 mounted 확인 |
| 8 | Android 포그라운드 로컬 알림 payload·탭 처리 없음 | FCM data를 JSON payload로, `onDidReceiveNotificationResponse` > 딥링크 게이트. FCM data > 딥링크 변환 3곳(콜드 스타트·백그라운드 탭·로컬 탭)을 `push_notification_routing.dart` 하나로 |
| 9 | 주소 없는 WS 이미지를 임시 ID로 교체 > 보완 실패 후 재연결 시 원본과 중복 | 서버 ID 유지(없을 때만 임시 ID), 짝짓기는 같은 ID 우선 > 표시 중 서버 메시지 제외 후 발신자 순서, 재연결 동기화도 병합 전 대기 이미지 교체 |
| 10 | 읽음 커서 fire-and-forget 오류 미처리 | `_updateReadCursorInBackground` 하나로 (진입·paused·resumed), 실패는 로그만 |
| 11 | 16.w×16.h 원 + 12.sp 글자 | 최소 16px·가로 4px 여백 알약(`StadiumBorder`), 고정 px |

## 새 파일
- `lib/services/open_chat_room_registry.dart`, `lib/providers/open_chat_room_registry_provider.dart`
- `lib/providers/chat_notification_guide_provider.dart` (userScopedProviders 등록)
- `lib/services/push_notification_routing.dart`
- `lib/utils/chat_room_live_message_rules.dart` (보관분 병합·내 나가기·자동 스크롤 판정)
- `lib/services/chat_message_frame_parser.dart` (소켓 프레임 > 메시지 변환 분리, 웹소켓 서비스 500줄 이하 유지)

## 하지 않는 것
- 맨 아래 이동 버튼, 안 읽은 위치 이동, 연결 상태 배너, 임시 저장, 빠른 답장 (후속 작업)
- 같은 방이 다른 화면 아래 묻혀 있을 때 그 화면으로 되돌아가기 (중간 화면 입력 유실 위험 > 기존처럼 새로 열고 퇴장 커서만 보호)
- 앱 종료 상태 로컬 알림 탭(`getNotificationAppLaunchDetails`)
- 재연결 시 채팅 목록 전체 새로고침 방식 변경

## 테스트
- 웹소켓 조용한 닫힘·구독 실패 보류·전송 실패·연결 대기, 폴러 소유자별 정지·회원 필터
- 열린 채팅방 목록, 같은 방 맨 위 push 생략, 로컬 알림 payload 이동
- 보관분 병합, 내 나가기 판정, 자동 스크롤 판정, 목록 구독 차이, 불러온 페이지 재조회, 세션 안내 플래그, 이미지 대기 메시지 짝짓기·병합
