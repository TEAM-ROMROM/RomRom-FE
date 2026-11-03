# #975 성능 개선 2단계 G3 계획 (세션·회원·알림·채팅방)

설계: `docs/superpowers/specs/2026-11-03-issue-975-performance-phase2-session-design.md`
검증: 작업마다 해당 테스트 > 끝에 `dart format --line-length=120 .` > `flutter analyze` > `flutter test`

## Task 1. 세션 종료 자원 정리
- 테스트 먼저 (`test/utils/user_session_lifecycle_test.dart`): 제재·만료·로그아웃 각각 정리 함수 1회 호출, 화면 전환 전 호출, 대기 없이 즉시
- `lib/services/user_session_resources.dart`: `releaseUserSessionResources()` (하트비트 > 폴러 > 웹소켓)
- `registerSessionEndNavigation`에 `releaseUserResources` 선택 인자 (기본값 실제 정리), `navigateThenReset` 맨 앞에서 실행 (실패 로그)
- 테스트: 정리 함수 중복 호출 안전 (`ChatWebSocketService.forTesting` disconnect 2회)

## Task 2. 회원 프로필 로컬 동기화
- 테스트 먼저
  - `test/services/member_manager_service_test.dart`: 같은 회원 > 프로필 필드 반영·온보딩 플래그 유지, 다른 회원·ID 없음 > 무시
  - `test/repositories/member_repository_test.dart`: 조회 성공 > 저장 함수에 회원 전달, 저장 실패 > 조회 결과 그대로
- `MemberManagerService.syncProfileFromServer`, `MemberManager.syncProfileFromServer`
- `MemberRepository(api, {saveFetchedMyMember})`, `memberRepositoryProvider`에서 주입

## Task 3. 알림 목록 sliver 지연 생성
- 테스트 먼저 (`test/widgets/notification/notification_history_list_test.dart`): `CustomScrollView` 안에서 렌더, 100건 중 일부만 생성, 빈 상태·로딩 행·탭 콜백 유지
- `NotificationHistoryList` > StatefulWidget, sliver 반환, 첫 프레임 행만 순차 등장
- `notification_screen.dart`: `SliverToBoxAdapter` 제거, `MediaQuery.paddingOf`

## Task 4. 채팅방 렌더링
- 테스트 먼저 (`test/utils/widget_instance_cache_test.dart`): 입력 같으면 같은 인스턴스, 다르면 새로 생성
- `lib/utils/widget_instance_cache.dart`
- `chat_room_screen.dart`: 앱바·거래 카드 캐시, `_updateInputFieldHeight` > `MediaQuery.sizeOf`
- `chat_room_messaging.dart`: `_scrollToBottom` > 다음 프레임 콜백 (중복 예약 방지 플래그)
- `chat_input_bar.dart` > `MediaQuery.paddingOf`, `chat_trade_info_card.dart` > `MediaQuery.sizeOf`

## Task 5. 업로드 말풍선 디코딩 크기
- 테스트 먼저 (`test/widgets/chat_message_item_uploading_test.dart`): 업로드 중 말풍선 이미지가 `ResizeImage`(셀 디코딩 폭)
- `chat_image_bubble.dart`: `photoGridCellDecodeSize` 추출, 기존 셀 계산 대체
- `chat_message_item.dart`: `Image.file(cacheWidth/cacheHeight)`

## Task 6. 문서·검증
- `.claude/instructions/state-management.md` 변경 없음 (provider 추가 없음)
- format > analyze > test
