# #975 성능 개선 2단계 G3 설계 (세션·회원·알림·채팅방)

- 이슈: https://github.com/TEAM-ROMROM/RomRom-FE/issues/975
- 1단계: `2026-11-03-issue-975-performance-phase1-design.md` (2단계로 이월 항목 중 세션·회원·알림·채팅 묶음)
- 원칙: 화면 동작은 그대로, 성능·정리만. 다른 묶음 소유 파일(`home_*`, `main_screen`, `chat_room_initial_load` 등)은 건드리지 않는다

## 1. 세션 종료 시 회원 단위 자원 정리

| 경로 | 지금 | 문제 |
|---|---|---|
| 로그아웃·탈퇴 (`AuthService`) | 토큰 삭제 > 웹소켓 해제 > 하트비트 중단 | 없음 |
| 세션 만료 (`ApiClient._handleSessionExpired`) | 토큰 삭제 > 하트비트 중단 > 회원 정보 삭제 | 웹소켓 연결·구독 유지 |
| 제재 (`ApiClient._handleSuspendedResponse`) | 토큰 삭제 | 웹소켓 유지, 하트비트 계속 (60초마다 403) |
| 시작 실패 탈출 (`SplashScreen`) | 토큰 삭제 > `notifyLoggedOut` | 웹소켓 유지 가능 |

- 세 종료 이벤트(제재·만료·로그아웃)는 모두 `registerSessionEndNavigation`(`lib/utils/user_session_lifecycle.dart`)을 지난다 > 이 지점 한 곳에서 정리
- 새 함수 `releaseUserSessionResources()` (`lib/services/user_session_resources.dart`): 하트비트 중단 > 상대 접속 상태 폴러 중단 > 채팅 웹소켓 해제
- 화면 전환 직전 즉시 실행 (provider 초기화처럼 1초 대기하지 않음: 토큰이 이미 지워져 연결 유지 이유 없음)
- 중복 호출 안전: `disconnect()`는 비어 있으면 빈 목록만 정리, `HeartbeatManager.stop()`·`ChatMemberStatusPoller.stop()`은 멱등 > 로그아웃·탈퇴의 기존 호출 유지
- 테스트를 위해 정리 함수는 선택 인자로 주입 (기본값 = 실제 정리)

## 2. 회원 정보 캐시

- 1단계에서 `MemberManagerService`의 `Member` 메모리 캐시는 이미 제거됨 > 남은 저장소 2개: `UserInfo`(SharedPreferences, 회원 ID·온보딩 플래그·프로필 일부) / `memberProfileProvider`(화면용 회원 상태, 단일 소유)
- 스플래시 `MemberManager.getCurrentMember()`의 실제 역할: 로컬에 회원 정보가 없을 때(재설치 등) 서버에서 받아 `UserInfo`에 저장 > 온보딩 판정. provider로 옮기지 않는다
  - 스플래시 다음 `startUserSession`이 회원 provider를 전부 초기화 > 스플래시에서 provider를 채워도 버려지고 메인에서 한 번 더 조회 (요청 증가)
  - provider는 `UserInfo`에 쓰지 않음 > 온보딩 판정에 쓸 수 없음
- 어긋남 방지 최소 변경: provider가 서버에서 내 정보를 받을 때마다 `UserInfo`의 프로필 필드(닉네임·이메일·프로필 사진·역할·계정 상태·좌표·수정일)를 덮어쓴다
  - 지점: `MemberRepository.getMemberInfo` 성공 후 주입된 저장 함수 (`MemberManager.syncProfileFromServer`) > provider·provider 테스트는 그대로
  - 회원 ID·온보딩 플래그는 바꾸지 않음 (온보딩 흐름 소유, null 기본값으로 덮으면 온보딩 재진입 위험)
  - 로컬 회원 ID와 다른 응답·회원 ID 없는 응답은 무시. 저장 실패는 조회 결과에 영향 없음 (로그만)
  - 효과: 프로필 수정 후 제재 안내 화면 닉네임 등 `UserInfo`를 읽는 곳이 최신값

## 3. 알림 목록 지연 생성

- 지금: 부모는 이미 `CustomScrollView`지만 목록을 `SliverToBoxAdapter` + `shrinkWrap` `ListView`로 넣어 알림 전부(페이지 누적 수백 건)를 한 번에 생성·레이아웃
- 변경: `NotificationHistoryList`가 sliver를 반환 (`SliverPadding` + `SliverList.builder`, 다음 페이지 조회 표시는 마지막 행). 빈 상태는 `SliverToBoxAdapter`
- 등장 애니메이션: 지연 생성이면 스크롤로 처음 나타나는 행·되돌아온 행이 다시 지연 등장 (이전에는 화면 밖에서 이미 끝나 있음) > 목록이 처음 그려진 프레임의 행만 순차 등장, 이후 생성 행은 바로 표시
- 유지: 탭 필터, 페이징(끝 근처 판정은 같은 스크롤 컨트롤러), 당겨서 새로고침, 빈 상태 문구, 읽음 처리(dispose), 스켈레톤·에러 뷰
- 헤더 상단 여백 `MediaQuery.of(context).padding.top` > `MediaQuery.paddingOf` (키보드 등 다른 값 변경에 재빌드 안 함)

## 4. 채팅방 렌더링

| 항목 | 지금 | 변경 |
|---|---|---|
| 맨 아래 스크롤 | 호출마다 `Future.delayed(100ms)` 타이머 생성 (취소 불가, 해제 후에도 실행) | 다음 프레임 콜백 1개로 합침 (같은 프레임 여러 호출 > 1번), 해제 후 무시 |
| dispose 타이머 | `_wsImageFetchTimer`·에코 대기 타이머는 #971에서 정리됨 | 남은 누락(맨 아래 스크롤 지연)은 위 변경으로 제거 |
| 입력창 높이 계산 | `MediaQuery.of(context).size` > 채팅방 화면 전체가 키보드 애니메이션 매 프레임 재빌드 | `MediaQuery.sizeOf` |
| 입력창 하단 여백 | `MediaQuery.of(context).padding` > 입력창이 키보드 매 프레임 재빌드 | `MediaQuery.paddingOf` |
| 거래 카드 이동 | `MediaQuery.of(context).size` | `MediaQuery.sizeOf` |
| 메시지 수신마다 재빌드 | 수신 `setState`가 `chat_room_initial_load.dart`(다른 묶음 소유)에 있음 | 앱바·거래 카드는 입력값이 같으면 이전 위젯 인스턴스 재사용 (`WidgetInstanceCache`) > Flutter가 하위 재빌드 생략. 목록·추천 배너·입력창은 메시지에 따라 바뀌므로 재빌드 유지 |

- 수신 `setState`를 목록 전용 알림(ValueNotifier 등)으로 바꾸는 방식은 하지 않음: 입력창(시스템 메시지 > 입력 막힘·전송 잠금)·추천 배너가 메시지에서 파생되고, 수신 처리 파일이 다른 묶음 소유라 위험 대비 이득이 작음

## 5. 채팅 사진 업로드 말풍선

- 지금: 업로드 중 말풍선이 압축 전 원본(`Image.file`)을 원본 해상도로 디코딩 (12MP 한 장 약 48MB, 최대 10장)
- 변경: 셀 표시 크기로 디코딩 (`cacheWidth`·`cacheHeight`). 셀 디코딩 크기 계산은 `chat_image_bubble.dart`의 `photoGridCellDecodeSize` 하나로 (업로드 말풍선·서버 이미지 셀 공통, 그리드 배치 표 단일 원본)

## 하지 않는 것

- 스플래시 회원 조회의 provider 이전 (2절 이유)
- `MemberManagerService._fetchMemberInfo`가 오류를 삼켜 스플래시의 "연결 오류 > 다시 시도" 분기가 로컬 회원 정보 없을 때 동작하지 않는 문제: 동작 변경이라 보고만
- 메시지 수신 처리 구조 변경 (4절 이유)
