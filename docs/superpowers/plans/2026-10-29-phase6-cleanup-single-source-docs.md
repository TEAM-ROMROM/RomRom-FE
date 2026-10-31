# 6단계 정리·단일 원본·문서 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 죽은 코드·중복 위젯·enum 크래시 위험·설정값 사본·중복 빌드 스크립트·규칙 문서 오류를 정리한다.

**Architecture:** 3곳 이상 반복은 공통 지점 하나로, 플랫폼을 넘는 값은 원본 하나로(코딩 규칙 1·5장). 동작 불변.

**Spec:** `docs/superpowers/specs/2026-10-29-global-code-ux-performance-design.md` (6단계)

## Global Constraints
- 동작·모양 불변. 삭제는 참조 0건을 grep으로 확인한 파일만.
- CLAUDE.md 규칙, 주석 한국어 한 줄, boolean `is/has/can/should`.
- 각 Task 끝: `dart format --line-length=120 lib test` → `flutter analyze` 0 → `flutter test` → `ledger . tighten` → `ledger . check`. 커밋 금지(컨트롤러가 단계 끝에).
- 릴리스 워크플로우가 관리하는 버전 값(`version.yml`·`pubspec.yaml` version)은 건드리지 않는다.

## Review Focus
- 공통 태그 위젯으로 바꾼 4곳의 색·크기·패딩이 기존과 동일 (Task 2 위젯 테스트)
- enum 미지 서버값 → 크래시 없이 폴백 (Task 3 테스트)
- 신고 화면 통합 후 물품 신고·회원 신고 각각 기존 사유 목록·API·완료 처리 동일 (Task 2)
- Android `.kts` 삭제 후 CI 체크 경로가 실제 파일을 가리킴 (Task 4)

---

### Task 1: 죽은 코드 삭제
- [ ] 참조 0건 확인 후 삭제: `lib/widgets/common/toggle_selector.dart`, `lib/widgets/common/scrollable_header.dart`, `lib/widgets/common/toggle_header_delegate.dart`, `lib/widgets/home_feed_item_tag_chips.dart`, `lib/widgets/item_card_option_chip.dart`, `lib/deprecated/` 전체
- [ ] 동결 목록에서 사라진 파일 줄 `ledger . tighten`
- [ ] 검증 + 보고(삭제 파일·확인한 grep)

### Task 2: 중복 위젯·화면 공통화
- [ ] 태그 4종(`ItemDetailConditionTag`, `ItemDetailTradeOptionTag`, `RequestManagementTradeOptionTag`, `TradeStatusTagWidget`) → `lib/widgets/common/app_tag.dart` `AppTag`(라벨·글자색·배경색·패딩·글자 스타일 파라미터) + 기존 이름은 얇은 래퍼 또는 호출부 교체. 위젯 테스트로 크기·색 동일 확인
- [ ] 신고 화면 2개(`report_screen.dart`, `member_report_screen.dart`) → 대상 타입 파라미터 하나로(사유 enum·API 호출만 다름)
- [ ] 디버그 패널 2개(`debug_log_panel.dart`, `debug_server_log_panel.dart`) 공통 베이스(리사이즈 핸들·크기 상수·헤더), `_maxBufferSize` 중복 상수 정리
- [ ] 주소 표시 형식 `'$siDo $siGunGu $eupMyoenDong'` 3곳+ → `LocationAddress`의 getter 또는 `lib/utils/` 함수 하나
- [ ] 앱 버전 조회 + 빈 catch 3곳(`login_screen`, `splash_screen`, `my_page_tab_screen`) → 공통 함수 하나
- [ ] 클래스명 오타 `NotificationBotomSheet*` → `NotificationBottomSheet*`, `SkeletonRectanglar` → `SkeletonRectangular`
- [ ] 검증 + 보고

### Task 3: enum 미지값 처리 통일
- [ ] `lib/enums/` 중 `fromServerName`이 throw하는 enum(`ItemCondition`, `TradeStatus` 등)을 nullable 반환으로, 호출부에 폴백(기존 기본값과 동일). `TradeStatus` 에러 메시지의 `ItemTradeOption` 복붙 제거
- [ ] `home_feed_item.dart`·`my_like_list_screen.dart`의 `firstWhere` + 삼키는 catch → `fromServerName` + 폴백
- [ ] 미지 서버값 테스트(각 enum 1개 이상)
- [ ] 검증 + 보고

### Task 4: 설정값 단일 원본·빌드 스크립트
- [ ] 스토어 URL·App Store id: `lib/services/app_review_service.dart:29-33` → `AppUrls` 참조(값 동일 확인)
- [ ] `functions/app-config.js` ↔ `public/app-config.js` 값 일치 확인, `public/app-config.js`의 없는 파일(`app-config-node.js`) 주석 수정
- [ ] `lib/debug/runtime_url_manager.dart`의 운영 API 주소 상수를 `AppUrls`(또는 설정 상수 파일)로 이동, 디버그 폴더는 참조만
- [ ] `android/app/build.gradle.kts`, `android/build.gradle.kts` 삭제(`settings.gradle`이 Groovy이고 `.kts`는 Groovy 문법이라 미사용), `ROMROM-ANDROID-FIREBASE-CICD.yaml:~273`의 `.kts` 검사 경로를 `build.gradle`로
- [ ] `CommonModal` `insetPadding` `40.w` → 고정 40, `ProfileLikesSection` `height: 54.h` → 세로 패딩 고정
- [ ] 검증 + 보고

### Task 5: 규칙 문서 정리
- [ ] 없는 `prompts/코드_스타일_가이드라인.md` 참조 제거 → `.claude/instructions/code-style.md`로 대체(`CLAUDE.md`, `code-style.md`, `project-structure.md`)
- [ ] CLAUDE.md 표준 작업 Flow의 `/cassiiopeia:*` 스킬명을 설치된 `projectops:pro-*` / `/pro-*`로(대응 표), 빌드 댓글 키워드는 워크플로우 기준 `@suh-lab build app`
- [ ] `git-rules.md:7` "확인 후 git add 가능" ↔ CLAUDE.md "절대 금지" 모순 해소(CLAUDE.md 기준으로 맞춤)
- [ ] CLAUDE.md의 `git-rules.md`·`auto-process.md` 중복 구간은 링크로 대체
- [ ] `state-management.md` provider 현황표 최종 갱신, `_pending` Set 규칙은 "항목별 액션은 Set, 단일 버튼은 bool 가드 허용"으로 현실화
- [ ] `docs/architecture/rules/` 규칙 추가: `no-async-value-read`(화면·위젯의 AsyncValue `.value` 금지 — 0건이면 허용 목록 없이)
- [ ] 보고
