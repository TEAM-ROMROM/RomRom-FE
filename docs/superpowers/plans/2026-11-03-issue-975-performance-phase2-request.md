# #975 성능 개선 2단계 G2 계획 (요청·프로필·채팅 진입)

설계: `docs/superpowers/specs/2026-11-03-issue-975-performance-phase2-request-design.md`

각 Task는 테스트 먼저(실패 확인) > 구현 > 테스트 통과 순서.

## Task 1. 보낸 요청 재조회 조건 (provider)
- 테스트 `test/providers/trade_requests_provider_test.dart`
  - 같은 카드 목록 재로드 > 보낸 요청 조회 없음, 받은 요청은 조회
  - 카드 목록 변경 > 보낸 요청 전체 조회
  - `isSentReloadForced` > 같은 카드 목록이어도 조회
  - 받은 요청만 하는 로드 진행 중 강제 로드 > 받은 요청 중복 없이 보낸 요청만 추가
- 구현 `lib/providers/trade_requests_provider.dart`: `_lastSentLoadItemIds`, 합류 규칙

## Task 2. 받은 요청 캐시 (provider + state)
- 테스트
  - 캐시 있는 카드 전환 > 응답 전 즉시 캐시 표시·로딩 아님, 응답 후 서버 값
  - 캐시 없는 카드 > 로딩 표시, 응답 후 해제
  - 정렬 변경 > 캐시 비움(로딩 표시)
  - 조회 실패 > 실패 플래그, 캐시 비움
  - 오래된 응답은 캐시에도 쓰지 않음
  - 읽음 처리 > 캐시 갱신
- 구현: `TradeRequestsState.isReceivedLoading`, `_receivedCacheByTakeItemId`

## Task 3. 차단 회원 제외 (state)
- 테스트 `test/states/trade_requests_state_test.dart`: 요청자·상대 기준 제외, 빈 차단 목록 > 원본 그대로
- 구현: `receivedExcludingRequesters`, `sentExcludingOpponents`

## Task 4. 화면 연결 (요청관리 탭)
- 테스트 `test/screens/request_management_tab_screen_test.dart`
  - 내 물품 재조회(카드 같음) > 보낸 요청 재조회 없음
  - 대표 이미지 변경 > 보낸 요청 재조회
  - 당겨서 새로고침 > 보낸 요청 재조회
  - 차단 > 해당 회원 받은 요청 즉시 사라짐
- 구현: 받은 목록 로딩 = 상태 `isReceivedLoading`, 카드 전환 로딩 카운터 제거, 차단 구독, 슬리버 배치

## Task 5. 목록 지연 생성 (위젯)
- 테스트 `test/widgets/request_management/request_lists_test.dart`: 슬리버 헬퍼로 교체, 30건 > 일부만 생성
- 구현: `RequestReceivedList`·`RequestSentList` 슬리버화, `StaggeredListItemEntrance`

## Task 6. 프로필 후기 주소 병렬
- 테스트 `test/services/reviewer_address_resolver_test.dart`: 병렬 시작, 회원 중복 제거, 주소 있는 회원 제외, 일부 실패 무시
- 구현: `lib/services/reviewer_address_resolver.dart`, `profile_review_section.dart` 1회 반영

## Task 7. 채팅방 진입 병렬
- 구현: `chat_room_initial_load.dart` 소켓 연결·메시지·읽음 상태 동시 시작 (화면 본체 테스트 대역 부재 > 실기기 확인 항목)

## 마무리
- `dart format --line-length=120 .` > `flutter analyze` > `flutter test`
