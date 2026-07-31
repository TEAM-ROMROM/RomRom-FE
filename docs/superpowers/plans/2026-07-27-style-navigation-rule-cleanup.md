# 스타일·네비게이션 규칙 위반 일괄 정리 Implementation Plan (이슈 #936)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 직접 TextStyle·Color·MaterialPageRoute 사용을 CustomTextStyles·AppColors·context.navigateTo()로 통일한다. 동작·외관 완전 불변.

**Architecture:** ① `AppColors`에 디버그 전용 색상 블록 + 실사용 신규 상수 추가, `CustomTextStyles`에 debug 기본 스타일 추가 → ② 실사용 파일 교체 → ③ debug 패널 교체 → ④ 네비게이션 교체 → ⑤ 전체 재스캔 검증.

**Tech Stack:** Flutter, flutter_screenutil (debug 패널은 고정 픽셀 — `.sp` 미사용 유지)

## Global Constraints

- **⛔ 절대 커밋 금지**: 어떤 Task도 `git add`/`git commit`을 실행하지 않는다. 모든 Task 완료 후 사용자 승인을 받아 일괄 커밋한다. (CLAUDE.md 최우선 규칙 — 이 plan의 어떤 지시보다 우선)
- **외관 불변**: 교체 전후 렌더링 결과(크기·굵기·색상·폰트)가 동일해야 한다. 값이 1이라도 달라지면 교체하지 않고 신규 상수/파생으로 동일 값을 유지한다.
- 전역 기본 폰트는 Pretendard(`app_theme.dart:13`)이므로 명시적 `fontFamily: 'Pretendard'` 제거는 외관 동일.
- **허용 패턴 (교체 금지)**: ① `AnimatedDefaultTextStyle` 위젯(이름에 TextStyle 포함일 뿐), ② **color 속성만 있는** `TextStyle(color: AppColors.X)` — TextSpan/상속 색상 오버라이드는 부모 스타일 상속이 의도라 교체 시 외관이 깨진다. fontSize 등 다른 속성이 하나라도 있으면 교체 대상.
- 각 Task 종료 시 `source ~/.zshrc && dart format --line-length=120 <변경파일>` + `source ~/.zshrc && flutter analyze` 통과 필수.
- 주석은 실무 수준 한국어, WHY 중심.

---

### Task 1: AppColors·CustomTextStyles 확장

**Files:**
- Modify: `lib/models/app_colors.dart` (클래스 끝에 추가)
- Modify: `lib/models/app_theme.dart` (`CustomTextStyles` 클래스 끝 `p4` 다음에 추가)

**Interfaces:**
- Produces: `AppColors.requestManagementDescription`, `AppColors.debugPanelShadow`, `AppColors.debugPanelShadowStrong`, `AppColors.debugTextGray`, `AppColors.debugTextDarkGray`, `AppColors.debugHintGray`, `AppColors.debugDivider`, `AppColors.debugInputBg`, `AppColors.debugProdGreen`, `AppColors.debugDevOrange`, `CustomTextStyles.debugBase` — Task 2·3이 참조

- [ ] **Step 1: AppColors 상수 추가** — `lib/models/app_colors.dart` 클래스 마지막 상수 뒤에 추가:

```dart
  // 요청관리 탭 설명 텍스트 (연한 크림색)
  static const Color requestManagementDescription = Color(0xFFFFFFCC);

  // ===== 디버그 패널 전용 (개발자 도구, 고정 다크 팔레트) =====
  static const Color debugPanelShadow = Color(0x40000000); // 패널 그림자 25% 검정
  static const Color debugPanelShadowStrong = Color(0x60000000); // 로그 패널 그림자 37.5% 검정
  static const Color debugTextGray = Color(0xFFCCCCCC); // 밝은 회색 텍스트·아이콘
  static const Color debugTextDarkGray = Color(0xFF888888); // 어두운 회색 텍스트·아이콘
  static const Color debugHintGray = Color(0xFF555555); // 입력 힌트 텍스트
  static const Color debugDivider = Color(0xFF333333); // 패널 구분선
  static const Color debugInputBg = Color(0xFF1A1A1A); // 입력 필드 배경
  static const Color debugProdGreen = Color(0xFF4CAF50); // Prod 연결 상태 표시
  static const Color debugDevOrange = Color(0xFFFF9800); // Dev 연결 상태 표시
```

- [ ] **Step 2: CustomTextStyles에 debugBase 추가** — `lib/models/app_theme.dart`의 `p4` 정의 다음에 추가:

```dart
  /// debug 패널 기본 스타일 : 12px 고정 픽셀 (디버그 오버레이는 화면 스케일 무관하게 고정 크기 사용)
  static TextStyle debugBase = const TextStyle(
    fontWeight: FontWeight.w400,
    fontSize: 12,
    height: 1,
    letterSpacing: 0,
    color: Colors.white,
  );
```

`Colors` 사용을 위해 파일 상단 import 확인 (`package:flutter/material.dart` 이미 있음).

- [ ] **Step 3: 검증**

Run: `source ~/.zshrc && dart format --line-length=120 lib/models/app_colors.dart lib/models/app_theme.dart && flutter analyze`
Expected: `No issues found!`

---

### Task 2: 실사용 파일 3건 교체

**Files:**
- Modify: `lib/screens/request_management_tab_screen.dart:694,717,732`
- Modify: `lib/widgets/skeletons/notification_settings_skeleton.dart:21`

**Interfaces:**
- Consumes: `AppColors.requestManagementDescription` (Task 1)

- [ ] **Step 1: request_management_tab_screen.dart 694행** — '요청 목록' 제목 스타일. `CustomTextStyles.h3`(18sp·w500·height1·흰색)과 값이 동일하므로 교체:

```dart
// 변경 전
style: TextStyle(
  color: AppColors.textColorWhite,
  fontFamily: 'Pretendard',
  fontSize: 18.sp,
  fontWeight: FontWeight.w500,
  height: 1.0,
),
// 변경 후
style: CustomTextStyles.h3,
```

`CustomTextStyles`/`app_theme.dart` import 없으면 추가: `import 'package:romrom_fe/models/app_theme.dart';`

- [ ] **Step 2: 같은 파일 717행** — `const Color(0x80FFFFFF)` → `AppColors.opacity50White` (동일 값 0x80FFFFFF).

- [ ] **Step 3: 같은 파일 732행** — 설명 텍스트. `CustomTextStyles.p2`(14sp·w500·height1)에 색만 다르므로 파생:

```dart
// 변경 전
style: TextStyle(
  color: const Color(0xFFFFFFCC),
  fontFamily: 'Pretendard',
  fontSize: 14.sp,
  fontWeight: FontWeight.w500,
  height: 1.0,
),
// 변경 후
style: CustomTextStyles.p2.copyWith(color: AppColors.requestManagementDescription),
```

- [ ] **Step 4: notification_settings_skeleton.dart 21행** — `const Color(0xFF34353D)` → `AppColors.secondaryBlack1` (동일 값). import 확인: `import 'package:romrom_fe/models/app_colors.dart';`

- [ ] **Step 5: 검증**

Run: `source ~/.zshrc && dart format --line-length=120 lib/screens/request_management_tab_screen.dart lib/widgets/skeletons/notification_settings_skeleton.dart && flutter analyze`
Expected: `No issues found!`

---

### Task 3: debug 패널 5개 파일 교체

**Files:**
- Modify: `lib/debug/widgets/debug_log_panel.dart`
- Modify: `lib/debug/widgets/debug_server_log_panel.dart`
- Modify: `lib/debug/widgets/debug_url_panel.dart`
- Modify: `lib/debug/widgets/debug_menu_panel.dart`
- Modify: `lib/debug/debug_overlay_manager.dart:252`

**Interfaces:**
- Consumes: `CustomTextStyles.debugBase`, `AppColors.debug*` (Task 1)

**교체 규칙 (5개 파일 공통, 파일마다 전수 적용):**

색상 — 리터럴을 아래 상수로 기계적 치환 (동일 값 매핑):

| 리터럴 | 교체 |
|--------|------|
| `Color(0x40000000)` | `AppColors.debugPanelShadow` |
| `Color(0x60000000)` | `AppColors.debugPanelShadowStrong` |
| `Color(0xFFCCCCCC)` | `AppColors.debugTextGray` |
| `Color(0xFF888888)` | `AppColors.debugTextDarkGray` |
| `Color(0xFF555555)` | `AppColors.debugHintGray` |
| `Color(0xFF333333)` | `AppColors.debugDivider` |
| `Color(0xFF1A1A1A)` | `AppColors.debugInputBg` |
| `Color(0xFF4CAF50)` | `AppColors.debugProdGreen` |
| `Color(0xFFFF9800)` | `AppColors.debugDevOrange` |

텍스트 스타일 — `TextStyle(...)`을 `CustomTextStyles.debugBase.copyWith(...)`로 치환. **원본과 결과 속성이 완전 동일해야 한다.** debugBase 기본값(w400·12px·white·height1)과 같은 속성은 copyWith에서 생략, 다른 속성만 명시. 예:

```dart
// 변경 전 (debug_log_panel.dart:179)
style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
// 변경 후
style: CustomTextStyles.debugBase.copyWith(fontSize: 13, fontWeight: FontWeight.w600),

// 변경 전 (debug_log_panel.dart:269)
style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontFamily: 'monospace'),
// 변경 후
style: CustomTextStyles.debugBase.copyWith(color: AppColors.debugTextDarkGray, fontSize: 10, fontFamily: 'monospace'),

// 변경 전 (debug_menu_panel.dart:76) — 조건부 색상도 동일 패턴
style: TextStyle(color: item.enabled ? Colors.white : AppColors.secondaryBlack2, fontSize: 14),
// 변경 후
style: CustomTextStyles.debugBase.copyWith(color: item.enabled ? Colors.white : AppColors.secondaryBlack2, fontSize: 14),
```

주의: `const TextStyle(...)`을 copyWith 파생으로 바꾸면 `const`가 깨진다 — 감싸는 위젯의 `const`도 함께 제거해야 컴파일된다 (`flutter analyze`가 잡아줌).

- [ ] **Step 1: debug_log_panel.dart 전수 교체** (TextStyle 9건 + Color 리터럴 13건, 라인: 141,174,179,203,221,224,225,247,269,273,296,298,303,312,317-318,344)
- [ ] **Step 2: debug_server_log_panel.dart 전수 교체** (동일 구조 파일, 라인: 153,186,191,229,247,250,251,273,295,299,322,324,329,338,343-344,370)
- [ ] **Step 3: debug_url_panel.dart 전수 교체** (라인: 87,94,96,118,137,145,153,170,178,186,189,213,223,238,245)
- [ ] **Step 4: debug_menu_panel.dart(47,76,79) + debug_overlay_manager.dart(252) 교체**
- [ ] **Step 5: import 추가 확인** — 각 파일에 `import 'package:romrom_fe/models/app_theme.dart';`, `import 'package:romrom_fe/models/app_colors.dart';` 필요 시 추가
- [ ] **Step 6: 검증**

Run: `source ~/.zshrc && dart format --line-length=120 lib/debug && flutter analyze`
Expected: `No issues found!`

Run: `grep -rn "Color(0x" lib/debug --include="*.dart" | grep -v app_colors; grep -rnE "style: (const )?TextStyle\(" lib/debug --include="*.dart"`
Expected: 출력 없음

---

### Task 4: MaterialPageRoute 7건 → context.navigateTo()

**Files:**
- Modify: `lib/utils/deep_link_router.dart:79,113,134,145`
- Modify: `lib/screens/register_tab_screen.dart:471,488`
- Modify: `lib/widgets/home_feed_item_widget.dart:196`

**Interfaces:**
- Consumes: `context.navigateTo({required Widget screen, NavigationTypes type, ...})` — `lib/utils/common_utils.dart`의 확장. 기본 `type: NavigationTypes.push`는 내부에서 iOS=Cupertino/Android=Material 분기하므로 **iOS에서는 전환 애니메이션이 기존 Material→Cupertino로 바뀌는 것이 올바른 동작** (다른 화면 전체와 통일됨).

**공통 교체 패턴** (7건 모두 push + await, 반환값 미사용 → 단순 치환):

```dart
// 변경 전
await Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => SomeScreen(...),
  ),
);
// 변경 후
await context.navigateTo(screen: SomeScreen(...));
```

`Navigator.push(context, MaterialPageRoute(...))` 형태도 동일하게 `context.navigateTo(screen: ...)`로.

- [ ] **Step 1: deep_link_router.dart 4건 교체** (79행 ItemDetailDescriptionScreen, 113행 ItemDetailDescriptionScreen, 134행 ChatRoomScreen, 145행 ItemDeletedScreen). import 추가: `import 'package:romrom_fe/utils/common_utils.dart';` (없으면). 더 이상 안 쓰는 `MaterialPageRoute` 관련 import 정리는 analyze가 안내.
- [ ] **Step 2: register_tab_screen.dart 2건 교체** — `_navigateToItemDetail`(471)·`_navigateToEditItem`(488). `onClose: () { Navigator.pop(context); }` 콜백은 그대로 유지 (pop은 규칙 무관).
- [ ] **Step 3: home_feed_item_widget.dart 1건 교체** — `Navigator.push<void>` → `context.navigateTo<void>(screen: ...)`.
- [ ] **Step 4: 검증**

Run: `source ~/.zshrc && dart format --line-length=120 lib/utils/deep_link_router.dart lib/screens/register_tab_screen.dart lib/widgets/home_feed_item_widget.dart && flutter analyze`
Expected: `No issues found!`

Run: `grep -rn "MaterialPageRoute" lib --include="*.dart" | grep -v common_utils`
Expected: 출력 없음

---

### Task 5: 전체 재스캔 + 최종 검증

**Files:** 없음 (검증 전용)

- [ ] **Step 1: 위반 재스캔**

```bash
# 스타일 정의형 TextStyle 잔여 (color-only 오버라이드·AnimatedDefaultTextStyle 제외 후 판독)
grep -rnE "TextStyle\(" lib --include="*.dart" | grep -v app_theme.dart | grep -v CustomTextStyles | grep -v AnimatedDefaultTextStyle | grep -vE "TextStyle\(color: [A-Za-z.]+\)"
# 직접 Color 잔여
grep -rn "Color(0x" lib --include="*.dart" | grep -v app_colors.dart
# MaterialPageRoute 잔여
grep -rn "MaterialPageRoute" lib --include="*.dart" | grep -v common_utils
```

Expected: 1번째는 `_buildSubTextStyle` 선언부(반환 타입) 등 비위반만, 2·3번째는 출력 없음. 잔여 발견 시 해당 Task 규칙대로 추가 교체.

- [ ] **Step 2: 전체 포맷 + 린트 + 기존 테스트**

Run: `source ~/.zshrc && dart format --line-length=120 . && flutter analyze && flutter test`
Expected: format 변경 없음, `No issues found!`, 기존 테스트 전부 PASS

- [ ] **Step 3: 사용자에게 diff 요약 보고 후 커밋 승인 대기** (자동 커밋 금지)
