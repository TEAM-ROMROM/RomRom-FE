# 2단계 사용자 버그·UX Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 감사에서 확인된 사용자 노출 버그·UX 결함(목록 미갱신, 임시 이미지, 중복 탭, 빈/에러 상태, 이탈 경고, 확인 모달, 접근성, 문구)을 해소한다.

**Architecture:** 공통 지점(`myItemsProvider`, `memberBlockProvider`, `notificationSettingProvider`, `CommonModal`, `EmptyStateView`, `CachedImage`, `AppUrls`)을 고치거나 확장하고, 화면은 그것만 쓰게 한다. 동결 규칙(`docs/architecture/rules/`)의 위반이 줄면 `ledger tighten`.

**Tech Stack:** Flutter, Riverpod, flutter_screenutil, cached_network_image. 새 의존성 없음.

**Spec:** `docs/superpowers/specs/2026-10-29-global-code-ux-performance-design.md` (2단계)

## Global Constraints
- CLAUDE.md 절대 규칙: `CustomTextStyles`, `AppColors`, `context.navigateTo()`, `CommonModal`, enum은 `lib/enums/`, Riverpod 규칙 0~5, `isTablet`, 모달 고정 px, `height: N.h` + vertical `N.h` padding 금지, 고정 높이 + Column 금지.
- 새 라이브러리 금지. 주석 한국어 한 줄 요약·블록 머리글(`~/.claude/coding-conventions.md` 2·7장), boolean `is/has/can/should`.
- 각 Task 끝: `source ~/.zshrc && dart format --line-length=120 lib test` → `flutter analyze` 0 → `flutter test` 전체 통과(아키텍처 규칙 포함). 위반을 없앤 규칙은 `PYTHONIOENCODING=utf-8 python3 /Users/suhsaechan/.claude/plugins/cache/projectops-marketplace/projectops-extras/4.77.2/skills/pro-code-consult/scripts/arch_cli.py ledger . tighten` 후 `ledger . check` 통과. `*.allow`에 줄 추가 금지.
- **커밋 금지**. git add/commit/stash/checkout/restore/reset 금지.
- 문구(내 판단, spec): 앱 표기 "물품" 통일, "판매중/판매 중" → "교환 가능", "…실패: " 접두 제거(ErrorUtils 메시지만), 개발자 문구 → 사용자 문구.
- 글자 크기 상한 1.2배. 터치 영역 최소 44px.

## Review Focus
- 비동기 `onConfirm`이 throw해도 확인 버튼 잠금이 풀리고 모달이 계속 쓸 수 있어야 함 (Task 3 테스트)
- 동기 `onConfirm`(기존 호출부 27곳)은 동작 그대로 (Task 3 테스트)
- 수정 화면에서 아무것도 바꾸지 않았으면 뒤로가기 시 경고 없음 (Task 5)
- 등록 성공 후 pop 시 이탈 경고가 뜨지 않아야 함 (Task 5)
- 에러 상태 "다시 시도"가 중복 탭돼도 요청 1회 (Task 4)

---

### Task 1: 공유 상태 변경을 provider 경유로

**Files:**
- Modify: `lib/repositories/item_repository.dart` (`updateItem` 추가), `lib/providers/my_items_provider.dart` (`update` 추가)
- Create: `lib/repositories/image_repository.dart`, `lib/providers/image_repository_provider.dart`
- Modify: `lib/widgets/register_input_form.dart:850,878`, `lib/widgets/profile/profile_overview_section.dart:113`, `lib/screens/register_tab_screen.dart:491`(틀린 주석), `lib/screens/chat_room_screen.dart:979`, `lib/screens/profile/member_profile_screen.dart:199-208`, `lib/screens/main_screen.dart:93`, `lib/widgets/profile/profile_exchange_section.dart:50-79`
- Test: `test/providers/my_items_provider_test.dart`(기존 파일에 추가)

**Interfaces:**
- Produces: `ItemRepository.updateItem(ItemRequest request) -> Future<void>`; `MyItemsNotifier.update(ItemRequest request) -> Future<void>` (API 후 `reload()`); `class ImageRepository { Future<List<String>> uploadImages(List<XFile> images); Future<void> deleteImages(List<String> imageUrls); }` + `final imageRepositoryProvider = Provider<ImageRepository>(...)` (`item_repository_provider.dart` 패턴)

- [ ] Step 1: 실패 테스트 — `my_items_provider_test.dart`에 `update` 호출 시 fake repo `updateItem` 1회 + `getMyItems` 재조회 확인 테스트 추가
- [ ] Step 2: 실패 확인 → Step 3: repository·notifier 구현 → 테스트 PASS
- [ ] Step 4: `register_input_form.dart` 수정 모드는 `ref.read(myItemsProvider.notifier).update(itemRequest)`, 이미지 업로드는 `imageRepositoryProvider` 경유. `profile_overview_section.dart:113` 동일. `register_tab_screen.dart:491` 주석을 실제 동작과 맞춤
- [ ] Step 5: 차단 — `chat_room_screen.dart:979`, `member_profile_screen.dart:199-208`은 `memberBlockProvider.notifier.setBlocked(memberId, true/false)` 사용, 채팅방 차단 성공 시 `CommonSnackBar` "사용자를 차단했습니다"(member_profile과 같은 문구)
- [ ] Step 6: `main_screen.dart:93` 알림설정 변경은 `notificationSettingProvider.notifier.setEnabled` 경유(기존 동작·대상 타입 동일)
- [ ] Step 7: `profile_exchange_section.dart`는 내 프로필일 때 `myItemsProvider` 구독으로 목록 표시(별도 `getMyItems` 제거). 타인 프로필 경로는 그대로
- [ ] Step 8: 검증 + `ledger tighten`(presentation-must-not-import-api 감소분) + 변경 파일 보고

### Task 2: 임시 이미지·하드코딩 주소 제거

**Files:**
- Modify: picsum 6파일 (`request_management_tab_screen.dart:156`, `register_tab_screen.dart:226-227`, `my_page/my_register_item_screen.dart:155-158`, `widgets/home_tab_card_hand.dart:662-664`, `widgets/request_management/request_received_list.dart:60`, `widgets/request_management/request_sent_list.dart:85,88`)
- Modify: `lib/widgets/register_input_form.dart:235`, `lib/services/chat_websocket_service.dart:66-72`, `public/index.html:67`, `lib/models/app_urls.dart`
- Test: `test/models/app_urls_test.dart`

**Interfaces:**
- Produces: `AppUrls.chatWebSocketUrl` (static getter) = `AppUrls.baseUrl`의 scheme을 `https→wss`/`http→ws`로 바꾸고 경로 `/chat`; `AppUrls.toAbsoluteImageUrl(String path) -> String` (http/https로 시작하면 그대로, 빈 값이면 `''`, 그 외 `'$imageBaseUrl/$path'`, 앞 `/` 중복 제거)

- [ ] Step 1: 실패 테스트 — `toAbsoluteImageUrl('a/b.jpg') == 'https://suh-project.synology.me/a/b.jpg'`, `('/a.jpg')` 슬래시 1개, `('https://x/y')` 그대로, `('')` == `''`; `chatWebSocketUrl`은 baseUrl을 직접 검증하기 어려우면 순수 함수 `toWebSocketUrl(String httpBaseUrl)`로 분리해 `('https://api.romrom.suhsaechan.kr') == 'wss://api.romrom.suhsaechan.kr/chat'`, `('http://h:8079') == 'ws://h:8079/chat'`
- [ ] Step 2: 실패 확인 → Step 3: 구현 → PASS
- [ ] Step 4: picsum → 빈 문자열(`CachedImage`가 빈 URL을 기본 에러 위젯으로 처리), `'Unknown'` 업로드 시간 → 빈 문자열(표시 위젯이 빈 문자열이면 공간 차지 없게), 카드 덱 이름 폴백 `'아이템'` → `'물품'`
- [ ] Step 5: `register_input_form.dart:235` → `AppUrls.toAbsoluteImageUrl`, 웹소켓 → `AppUrls.chatWebSocketUrl`(옛 "🔧 TEST" 주석·디버그 로그 정리), `public/index.html:67` → `https://apps.apple.com/app/id6748823976`
- [ ] Step 6: 검증 + `ledger tighten`(no-placeholder-image-url, no-hardcoded-server-host) + 보고

### Task 3: CommonModal 확인 잠금·고정 폭 + 채팅하기 중복 방지 + iPad 사이징

**Files:**
- Modify: `lib/widgets/common/common_modal.dart`
- Modify: `lib/screens/item_detail_description_screen.dart:1038,1091` (채팅하기)
- Modify: `lib/widgets/profile/profile_sections.dart:18-20`, `lib/widgets/common/request_management_trade_option_tag.dart:18-21`, `lib/widgets/common/ai_badge.dart:15-16`
- Test: `test/widgets/common/common_modal_test.dart`

**Interfaces:**
- Produces: `CommonModal`의 `onConfirm` 타입을 `FutureOr<void> Function()`로(기존 `VoidCallback` 전달 호출부 컴파일 유지). 확인 버튼 탭 → 실행 중이면 무시, 결과가 Future면 완료(성공·실패 공통)까지 확인·취소 버튼 비활성 + 확인 버튼 자리에 `CommonLoadingIndicator`(작은 크기). 폭 `312`·`maxWidth: 312` 고정 px, 단일 버튼 폭 `264` 고정.

- [ ] Step 1: 실패 위젯 테스트 — (a) Completer로 끝나지 않는 비동기 onConfirm: 확인 2회 탭 → 호출 1회, 로딩 표시 (b) Completer 완료(throw) 후 다시 탭 가능 (c) 동기 onConfirm 2회 탭 → 2회 호출(기존 동작) (d) 모달 Container 폭이 화면 크기와 무관하게 312
- [ ] Step 2: 실패 확인 → Step 3: `CommonModal`을 StatefulWidget(내부 `_isConfirmInProgress`)로 → PASS
- [ ] Step 4: 채팅하기 — `_isChatCreationInProgress` 가드(진행 중이면 return), 진행 중 버튼 로딩/비활성, `finally`에서 해제(`mounted` 확인)
- [ ] Step 5: iPad 규칙 — `height: N.h` 제거하고 `const EdgeInsets.symmetric(vertical: 고정px)`(현재 값의 숫자 그대로)만 사용
- [ ] Step 6: 검증 + 보고

### Task 4: 빈 상태·에러 상태 + 다시 시도

**Files:**
- Modify: `lib/screens/chat_tab_screen.dart:~300`, `lib/screens/register_tab_screen.dart:167-178,366-375`, `lib/screens/my_page/my_like_list_screen.dart:~120`, `lib/screens/home_tab_screen.dart:342,360-376`
- Modify: `lib/widgets/common/empty_state_view.dart` (필요 시 에러 변형)
- Test: `test/widgets/common/empty_state_view_test.dart`

**Interfaces:**
- Produces: `EmptyStateView.error({required VoidCallback onRetry, String centerText = '불러오지 못했어요', String descriptionText = '잠시 후 다시 시도해 주세요'})` named 생성자(아이콘은 기존 `AppIcons` 중 경고 계열, 버튼 문구 `'다시 시도'`)

- [ ] Step 1: 실패 위젯 테스트 — `EmptyStateView.error` 렌더 시 문구·'다시 시도' 버튼, 탭 시 onRetry 1회
- [ ] Step 2~3: 구현 → PASS
- [ ] Step 4: 채팅 목록 — 로딩/에러/빈 3상태. 빈 문구 `'아직 채팅이 없어요'`, 필터 탭(보낸/받은 요청)별 빈 상태도 같은 위젯. 에러는 `chatRoomsProvider` 재조회
- [ ] Step 5: 등록 탭 — `myItemsProvider` 에러(이전 값 없음)면 에러 뷰 + 재시도(`reload`), 등록 버튼 "불러오는 중" 문구는 실제 로딩 중일 때만
- [ ] Step 6: 좋아요 목록 — 실패 시 에러 뷰, `RefreshIndicator` 추가(기존 홈과 같은 스타일)
- [ ] Step 7: 홈 첫 로드 실패 — "물품이 없습니다" 대신 에러 뷰(기존 새로고침 동작 재사용), 직접 `TextStyle` 제거(`home_tab_screen.dart:376`)
- [ ] Step 8: 재시도 중복 탭 방지(진행 중이면 무시) → 검증 + `ledger tighten`(no-direct-text-style) + 보고

### Task 5: 이탈 경고·확인 모달·결과 안내·키보드

**Files:**
- Modify: `lib/screens/item_register_screen.dart:23`, `lib/screens/item_modification_screen.dart:66`, `lib/widgets/register_input_form.dart`(변경 여부 노출)
- Modify: `lib/screens/my_page_tab_screen.dart:190`, `lib/widgets/chat_message_item.dart:193-205`, `lib/widgets/chat_room_app_bar.dart:117`, `lib/screens/report_screen.dart:47`, `lib/screens/member_report_screen.dart`, `lib/screens/register_tab_screen.dart:530`, `lib/screens/item_detail_description_screen.dart:451-455`

- [ ] Step 1: 등록/수정 — 폼이 초기값과 다르면(`hasUnsavedChanges`) `PopScope(canPop: false)` + `CommonModal.confirm(message: '작성 중인 내용이 사라져요.\n나가시겠어요?', confirmText: '나가기')`. 저장 성공 후 pop은 경고 없이
- [ ] Step 2: 로그아웃 확인 `CommonModal.confirm(message: '로그아웃하시겠어요?', confirmText: '로그아웃')`
- [ ] Step 3: 거래 "확인 및 완료하기" 확인 `'거래를 완료하면 되돌릴 수 없어요.\n완료하시겠어요?'`, 거절·완료 버튼은 `_isPendingTradeAction` 동안 비활성 표시
- [ ] Step 4: 채팅방 신고 — 결과를 await 후 성공 시 `'신고가 접수되었습니다.'`(home_tab_screen과 같은 문구)
- [ ] Step 5: 신고 화면 2개 — 키보드가 입력란을 가리지 않게 `resizeToAvoidBottomInset` 기본값 또는 `viewInsets.bottom` 패딩
- [ ] Step 6: 교환 완료로 변경 성공 스낵바(반대 방향과 같은 형식), 상세 "물품 정보가 없습니다" 화면에 뒤로가기 앱바
- [ ] Step 7: 검증 + 보고

### Task 6: 접근성 (글자 크기·라벨·터치 영역)

**Files:**
- Modify: `lib/main.dart:232`, `lib/widgets/common/report_menu_button.dart:15-16`
- Modify: 아이콘 전용 버튼 공통 지점(앱바 뒤로가기·닫기·더보기 등 공통 위젯이 있으면 그 한 곳, 없으면 사용처) — `lib/widgets/common/` 우선
- Test: `test/main_text_scale_test.dart` 또는 순수 함수 테스트

**Interfaces:**
- Produces: `TextScaler clampAppTextScaler(TextScaler systemScaler)` (최소 1.0, 최대 1.2) — `lib/utils/text_scale_utils.dart`

- [ ] Step 1: 실패 테스트 — 시스템 1.5 → 1.2, 0.8 → 1.0, 1.1 → 1.1
- [ ] Step 2~3: 구현 → `main.dart` 적용
- [ ] Step 4: 아이콘 전용 버튼에 `Semantics(label:)` 또는 `tooltip`(한국어: '뒤로 가기', '닫기', '더보기', '신고', '설정', '알림' 등 실제 의미), 신고 메뉴 터치 영역 44×44(아이콘 크기는 유지)
- [ ] Step 5: 검증 + 보고

### Task 7: 문구 통일

**Files:**
- Modify: `lib/` 전체 사용자 노출 문자열 (주석·로그 제외), `lib/enums/item_status.dart:14`

- [ ] Step 1: "물건" → "물품"(사용자 노출 문자열만, 화면 제목·버튼·안내·스낵바), `'판매중'`/`'판매 중'`/`'판매중으로 변경'` → `'교환 가능'`/`'교환 가능으로 변경'`(ItemStatus.available.label 포함)
- [ ] Step 2: `'… 실패: ${ErrorUtils.getErrorMessage(e)}'` 형태 → `ErrorUtils.getErrorMessage(e)`만 (7곳: `register_tab_screen.dart:539,561`, `item_detail_description_screen.dart:284,309,1118`, `chat_room_app_bar.dart:145,174` 및 grep으로 찾은 동일 패턴)
- [ ] Step 3: 개발자 문구 → 사용자 문구: `'물품 ID가 없습니다'` → `'물품 정보를 찾을 수 없어요'`; `'신고 하기'` → `'신고하기'`; `'교환방식을'` → `'교환 방식을'`
- [ ] Step 4: 문자열 의존 테스트 갱신, 검증 + 변경 목록(바꾼 문구 전/후 표) 보고
