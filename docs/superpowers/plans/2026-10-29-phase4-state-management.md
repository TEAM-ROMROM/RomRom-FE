# 4단계 상태관리 확대 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 화면·위젯의 API 직접 호출을 없애고(동결 목록 `presentation-must-not-import-api` 비우기, 요청관리 탭 제외), 알림 도메인 상태 계층을 새로 만들며, 서비스→화면·모델→서비스 역방향 의존을 끊는다.

**Architecture:** CLAUDE.md 4-레이어(`lib/repositories` → `lib/states` → `lib/providers` → 화면 구독). 공유 도메인은 AsyncNotifier가 소유, 화면 1회성 호출(신고 제출 등)은 repository provider 경유. 이벤트 버스·GlobalKey 교차호출 금지 — 화면 전환이 필요한 서비스는 앱 루트가 등록한 콜백으로 위임.

**Tech Stack:** Flutter, Riverpod 2.6.1. 새 의존성 없음.

**Spec:** `docs/superpowers/specs/2026-10-29-global-code-ux-performance-design.md` (4단계) + 2단계에서 이월한 알림 페이징

## Global Constraints
- `.claude/instructions/state-management.md` 레시피와 기존 패턴(`item_repository_provider.dart`, `my_items_provider.dart`, `member_block_provider.dart`) 준수. repository는 plain `Provider`로 주입(테스트 override 가능).
- AsyncValue 읽기는 `.valueOrNull`(riverpod 2.6.1 `.value`는 데이터 없는 에러에서 재throw).
- 동작 불변(화면 문구·이동·스낵바 동일). 목록 갱신은 서버 재조회. 새 라이브러리 금지.
- 주석 한국어 한 줄, boolean `is/has/can/should`, 약어 금지.
- 각 Task 끝: `dart format --line-length=120 lib test` → `flutter analyze` 0 → `flutter test` → `ledger . tighten` → `ledger . check`. `*.allow` 줄 추가 금지.
- 커밋 금지(컨트롤러가 단계 끝에 커밋). `lib/screens/request_management_tab_screen.dart`·`lib/widgets/request_management/`는 5단계 담당.
- 화면 1회성 호출 기준: 결과가 다른 화면 상태에 영향 없으면 repository 메서드 직접 호출(provider 경유) 허용, 영향 있으면 notifier 메서드.

## Review Focus
- 알림 무한 스크롤: 마지막 페이지 이후 추가 요청 없음, 동시 스크롤 이벤트에 페이지 중복 요청 없음 (Task 1 테스트)
- 알림 삭제·전체 삭제·읽음 후 목록은 서버 재조회, 홈 배지 즉시 반영 (Task 1 테스트)
- 회원 정보 provider 첫 로드 실패 시 6개 화면이 크래시 없이 기존 실패 처리 (Task 2)
- 세션 만료·제재 화면 전환 콜백이 등록 전이어도 예외 없음 (Task 5 테스트)
- 모델 주소 변환 이동 후 피드·내 물품 표시 주소 동일 (Task 5 테스트)

---

### Task 1: 알림 도메인 (repository → state → provider) + 페이징

**Files:**
- Create: `lib/repositories/notification_repository.dart`, `lib/providers/notification_repository_provider.dart`, `lib/states/notification_list_state.dart`, `lib/providers/notification_list_provider.dart`
- Modify: `lib/screens/notification_screen.dart`(:86 회원정보 포함), `lib/screens/home_tab_screen.dart:~142`(배지)
- Test: `test/providers/notification_list_provider_test.dart`, `test/states/notification_list_state_test.dart`

**Interfaces:**
- Produces: `NotificationRepository { getNotifications({required int pageNumber, required int pageSize}); getUnreadCount(); markAsRead(String id); markAllAsRead(); delete(String id); deleteAll(); }` (NotificationApi 래핑, 반환 타입은 기존 응답 모델 재사용); `@immutable NotificationListState { notifications, unreadCount, nextPageNumber, hasMore, isLoadingMore, copyWith, ==, hashCode }`; `notificationListProvider = AsyncNotifierProvider<NotificationListNotifier, NotificationListState>` with `reload()`, `loadMore()`(in-flight 가드), `markAsRead(id)`, `markAllAsRead()`, `delete(id)`, `deleteAll()`, `refreshUnreadCount()`. 페이지 크기 상수 `notificationPageSize = 20`.
- 화면 dispose 시 전체 읽음 호출은 notifier 메서드로(실패 로그 유지)

- [ ] Step 1: 실패 테스트 — 첫 로드 page 0; loadMore → page 1 추가; hasMore false면 loadMore 무시; 동시 loadMore 2회 → 요청 1회; delete → 서버 재조회(수동 removeWhere 없음); markAllAsRead → unreadCount 0 재조회
- [ ] Step 2~3: 구현 → PASS
- [ ] Step 4: 알림 화면 구독 전환(로딩=기존 스켈레톤 도달 가능하게, 에러=`EmptyStateView.error`, 빈 상태 기존 문구), 스크롤 끝 근처에서 `loadMore`, 홈 배지 `ref.watch(...).valueOrNull?.unreadCount`
- [ ] Step 5: 검증 + tighten + `.claude/instructions/state-management.md` provider 표 갱신 + 보고

### Task 2: 회원 정보 단일 소유 (memberProfileProvider 구독)

**Files:**
- Modify: `lib/screens/main_screen.dart:~83`, `lib/screens/chat_room_screen.dart:~386`, `lib/screens/notification_settings_screen.dart:~66`, `lib/screens/search_range_setting_screen.dart:~48`, `lib/screens/my_page/my_category_settings_screen.dart:~39`, 온보딩 `category_selection_step.dart`·`location_verification_step.dart`·`term_agreement_step.dart`, `lib/screens/my_page/my_location_verification_screen.dart`
- Modify (필요 시): `lib/repositories/member_repository.dart`, `lib/providers/member_profile_provider.dart`

- [ ] Step 1: 읽기 — 최신값이 필요한 설정 화면은 `ref.read(memberProfileProvider.notifier).reload()` 후 `valueOrNull`, 그 외는 `ref.read(memberProfileProvider.future)`(실패 시 기존 catch 경로)
- [ ] Step 2: 회원 정보 변경(카테고리·위치·검색 범위·약관 동의 등)은 `MemberRepository` 메서드 추가 후 notifier 메서드(변경 + `reload`)로
- [ ] Step 3: provider 테스트 추가(변경 메서드 → repository 1회 + 재조회)
- [ ] Step 4: 검증 + tighten + 보고

### Task 3: 채팅 호출을 repository·provider 경유로

**Files:**
- Modify: `lib/repositories/chat_repository.dart`, `lib/providers/chat_rooms_provider.dart`, `lib/screens/chat_room_screen.dart`, `lib/screens/item_detail_description_screen.dart:~1116`, `lib/screens/trade_complete_partner_select_screen.dart:~50`
- Test: `test/providers/chat_rooms_provider_test.dart`(없으면 생성)

- [ ] Step 1: `ChatRepository`에 화면이 쓰는 ChatApi 메서드 래핑(메시지 조회, 읽음 커서, 거래 완료 요청/취소/거절/확정, 방 생성, 방 삭제, 물품별 방 조회, 이미지 업로드는 `imageRepositoryProvider`)
- [ ] Step 2: 방 나가기/삭제는 `ChatRoomsNotifier.deleteRoom(chatRoomId)`(API + reload), 방 생성은 `ChatRoomsNotifier.createRoom(...)`(API + reload, 생성 결과 반환)
- [ ] Step 3: 실패 테스트 → 구현 → PASS (deleteRoom → repository 1회 + 재조회)
- [ ] Step 4: 화면은 `ref.read(chatRepositoryProvider)`/notifier 사용, `ChatApi()`·`MemberApi()` 직접 생성 제거(차단은 이미 `memberBlockProvider`)
- [ ] Step 5: 검증 + tighten + 보고

### Task 4: 나머지 화면·위젯 직접 호출 제거

**Files:**
- Modify: 동결 목록 잔여 파일 — `item_modification_screen.dart`, `item_price_input_screen.dart`, `member_report_screen.dart`, `report_screen.dart`, `my_page/block_management_screen.dart`, `my_page/my_like_list_screen.dart`, `profile/member_profile_screen.dart`, `splash_screen.dart`, `trade_request_screen.dart`, `trade_review_screen.dart`, `home_tab_screen.dart`(알림 외), `widgets/home_feed_item_widget.dart`, `widgets/login_button.dart`, `widgets/profile/profile_exchange_section.dart`, `widgets/profile/profile_review_section.dart`
- Create: 필요한 repository(예: `report_repository.dart`, `trade_review` 관련은 `trade_repository`에 추가) + provider 파일

- [ ] Step 1: 파일마다 직접 호출 목록화 → 공유 상태 영향 여부로 notifier 메서드/repository 메서드 결정(보고서에 표)
- [ ] Step 2: repository·provider 추가 또는 확장, 화면 교체(동작·문구 불변)
- [ ] Step 3: 새 repository 메서드 최소 1개씩 fake 테스트 또는 provider 테스트
- [ ] Step 4: 검증 + tighten(`presentation-must-not-import-api`에 요청관리 탭만 남는지 확인) + 보고

### Task 5: 역방향 의존 제거 (서비스→화면, 모델→서비스)

**Files:**
- Modify: `lib/services/api_client.dart`(:11-12, 67-72, 428-431), `lib/services/auth_service.dart`(:7, 37), 앱 루트(`lib/main.dart` 또는 `lib/screens/main_screen.dart` 상위)
- Create: `lib/services/session_navigation_handler.dart`
- Modify: `lib/models/apis/objects/item.dart:7,62-75`, `lib/models/home_feed_item.dart:6,54-90` → 주소 변환을 `lib/services/item_address_resolver.dart`(또는 repository)로 이동, 호출부(`my_items_provider`, `home_feed_provider`/repository, 좋아요 목록 등) 갱신
- Test: `test/services/session_navigation_handler_test.dart`, `test/services/item_address_resolver_test.dart`

**Interfaces:**
- Produces: `class SessionNavigationHandler { static void register({required void Function(String suspendReason, String suspendedUntil) onAccountSuspended, required void Function() onSessionExpired, required void Function() onLoggedOut}); static void notifyAccountSuspended(...); static void notifySessionExpired(); static void notifyLoggedOut(); }` — 미등록 시 no-op + 로그. 앱 루트에서 `navigatorKey` + `context.navigateTo`로 기존과 같은 화면·전환 타입 등록
- `HomeFeedItem.fromItems(items, {startIndex, required Map<String, String> locationTextByItemId})` 또는 동등한 순수 변환 + resolver가 주소 채움 — 이름은 구현자 판단, 모델은 services import 없음

- [ ] Step 1: 실패 테스트 — 미등록 notify 호출 시 예외 없음; 등록 후 notify → 콜백 1회; resolver가 좌표 없는 물품은 '미지정', 좌표 있으면 캐시된 주소 문자열
- [ ] Step 2~3: 구현 → PASS
- [ ] Step 4: `api_client`·`auth_service`에서 screens import 제거(화면 전환은 handler 경유, 전환 타입·대상 화면 동일), 모델의 services import 제거
- [ ] Step 5: 검증 + tighten(`services-must-not-import-screens`, `models-must-not-import-services` 0줄) + 보고
