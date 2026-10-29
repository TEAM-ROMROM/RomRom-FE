# 5단계 대형 파일 분해 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 500줄 초과 화면·위젯을 동작 불변으로 분해한다(#937 흡수). 요청관리 탭은 남은 상태 문제(직접 변경·이중 로드·API 직접 호출)까지 정리한다.

**Architecture:** private 빌더 메서드·큰 build 블록을 `lib/widgets/<화면명>/` 하위 위젯 파일로 추출. 상태 로직(setState·provider 연동)은 원래 화면에 두고 위젯은 값·콜백만 받는다(요청관리 탭 7/31 진행분과 같은 방식: `lib/widgets/request_management/`).

**Tech Stack:** Flutter, Riverpod 2.6.1.

**Spec:** `docs/superpowers/specs/2026-10-29-global-code-ux-performance-design.md` (5단계), 참고 `docs/superpowers/plans/2026-07-31-large-file-decomposition.md`

## Global Constraints
- 동작·모양 불변(위젯 트리 결과 동일, 키·Hero 태그·GlobalKey 위치 유지). 추출 위젯은 화면 상태를 직접 들지 않고 생성자 값·콜백만 받음.
- 파일당 목표 500줄 이하(분해 후 화면 파일·추출 파일 모두). 파일명 = 주 타입명(snake_case), `_widget` 접미사 금지.
- AsyncValue는 `.valueOrNull`. CLAUDE.md 규칙, 주석 한국어 한 줄, boolean `is/has/can/should`.
- 각 Task 끝: `dart format --line-length=120 lib test` → `flutter analyze` 0 → `flutter test` → `ledger . tighten` → `ledger . check`. `*.allow` 줄 추가 금지. 커밋 금지(컨트롤러가 단계 끝에).
- 기존 위젯 테스트(카드 덱·로드 에러·이탈 가드 등)는 그대로 통과해야 한다.

## Review Focus
- 추출 후 Hero 전환·GlobalKey(공유 시트 위치 등)가 같은 위치에서 동작 (각 Task)
- 카드 덱 히트테스트·드래그 감촉 불변 (Task 3, 기존 테스트)
- 등록 폼 이탈 가드·저장 중 차단 그대로 (Task 4, 기존 테스트)
- 요청관리 탭 첫 진입 시 로드 1회 (Task 5 테스트)

---

### Task 1: 물품 상세 화면 분해 (`item_detail_description_screen.dart` 1,147줄)
- [ ] build(약 690줄)를 이미지 영역·판매자 정보·본문(가격·태그·설명)·위치 지도·하단 액션바·상태 변경 시트로 분리 → `lib/widgets/item_detail/`
- [ ] 로딩·지오코딩·상태변경·공유·채팅생성 로직은 화면에 유지(메서드 단위 정리만)
- [ ] 검증 + 보고(줄 수 전/후)

### Task 2: 채팅방 화면 분해 (`chat_room_screen.dart` 1,081줄)
- [ ] 메시지 목록·입력 영역·거래 상태 배너·상단 바 연결부를 `lib/widgets/chat_room/`로 추출(기존 `chat_input_bar`, `chat_room_app_bar`, `chat_message_item` 재사용)
- [ ] 소켓·낙관적 메시지·이미지 업로드·거래 완료 상태 로직은 화면(또는 4단계에서 만든 repository/notifier)에 유지
- [ ] 검증 + 보고

### Task 3: 홈 카드 덱 분해 (`home_tab_card_hand.dart` 1,070줄)
- [ ] 카드 한 장 렌더링(`_buildCard`의 정적 본문), 드롭존·아이콘 오버레이, 변환 계산(순수 함수)을 `lib/widgets/home_tab_card_hand/`로 추출. 제스처·컨트롤러·히트테스트는 원 파일 유지
- [ ] 변환 계산 순수 함수에 단위 테스트(기존 값과 동일)
- [ ] 검증(기존 `test/widgets/home_tab_card_hand_test.dart` 통과) + 보고

### Task 4: 물품 등록 폼 분해 (`register_input_form.dart` 1,014줄)
- [ ] build(약 630줄)를 이미지 선택 영역·카테고리 바텀시트·상태/거래방식 선택·가격 영역·위치 영역·제출 버튼으로 분리 → `lib/widgets/register_input_form/`
- [ ] 업로드·제출·이탈 가드·스냅샷 로직은 폼에 유지
- [ ] 검증(기존 이탈 가드·등록 화면 테스트 통과) + 보고

### Task 5: 요청관리 탭 마무리 + 나머지 500줄 초과
**Files:** `lib/screens/request_management_tab_screen.dart`, `lib/providers/trade_requests_provider.dart`, `lib/widgets/request_management/*`, 500줄 초과 잔여(`home_tab_screen.dart`, `register_tab_screen.dart`, `my_page/profile_image_crop_screen.dart`, `widgets/home_feed_item_widget.dart`)
- [ ] provider 상태 직접 변경(`r.isNew = …` 후 `setReceived`) 제거 → notifier 메서드(예: `markReceivedAsRead(id)`)로 불변 갱신
- [ ] 수신 목록 fetch를 `tradeRequestsProvider`가 소유(화면의 TradeApi 직접 호출 제거), 첫 진입 이중 로드(initState + 첫 listen) 제거, 받은/보낸 로드 병렬
- [ ] `.value` 3곳 → `.valueOrNull`, `firstWhere` orElse 없는 곳(`request_sent_list.dart`) 폴백
- [ ] 실패 테스트(첫 진입 로드 1회, isNew 갱신이 새 상태 객체) → 구현 → PASS
- [ ] 나머지 500줄 초과 파일은 같은 방식으로 500줄 이하로(동작 불변)
- [ ] 검증 + tighten(`presentation-must-not-import-api` 0줄 목표) + 보고
