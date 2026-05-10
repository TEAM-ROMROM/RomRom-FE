# Loading Indicator Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `AppLoadingIndicator` 공통 위젯을 만들고, 프로젝트 전체의 `CircularProgressIndicator` 직접 사용을 교체해 로딩 UI를 통일한다.

**Architecture:** `lib/widgets/common/app_loading_indicator.dart`에 `AppLoadingIndicator` 위젯을 생성한다. primary(노란색)와 onDark(흰색 반투명) 두 스타일을 지원하며, `centered()` static 헬퍼로 Center 래핑 반복을 제거한다. 기존 스켈레톤 위젯과 completion_button은 변경하지 않는다.

**Tech Stack:** Flutter, Dart, AppColors (lib/models/app_colors.dart)

---

## 파일 구조

| 파일 | 역할 |
|------|------|
| `lib/widgets/common/app_loading_indicator.dart` | **신규 생성** — 공통 로딩 위젯 |
| `lib/screens/chat_location_picker_screen.dart` | 교체 |
| `lib/screens/chat_room_screen.dart` | 교체 |
| `lib/screens/chat_tab_screen.dart` | 교체 |
| `lib/screens/home_tab_screen.dart` | 교체 (2곳) |
| `lib/screens/item_detail_description_screen.dart` | 교체 (2곳) |
| `lib/screens/item_modification_screen.dart` | 교체 |
| `lib/screens/item_register_location_screen.dart` | 교체 |
| `lib/screens/my_page/block_management_screen.dart` | 교체 |
| `lib/screens/my_page/my_category_settings_screen.dart` | 교체 |
| `lib/screens/my_page/my_like_list_screen.dart` | 교체 (2곳) |
| `lib/screens/my_page/my_profile_edit_screen.dart` | 교체 |
| `lib/screens/my_page/terms_screen.dart` | 교체 |
| `lib/screens/notification_screen.dart` | 교체 |
| `lib/screens/notification_settings_screen.dart` | 교체 |
| `lib/screens/onboarding/term_agreement_step.dart` | 교체 |
| `lib/screens/profile/member_profile_screen.dart` | 교체 |
| `lib/screens/register_tab_screen.dart` | 교체 |
| `lib/screens/request_management_tab_screen.dart` | 교체 (4곳) |
| `lib/screens/search_range_setting_screen.dart` | 교체 |
| `lib/screens/trade_complete_partner_select_screen.dart` | 교체 |
| `lib/screens/trade_request_screen.dart` | 교체 (2곳, textColorBlack → primary) |
| `lib/widgets/chat_image_bubble.dart` | 교체 (size: 32, 24) |
| `lib/widgets/chat_location_bubble.dart` | 교체 |
| `lib/widgets/chat_message_item.dart` | 교체 |
| `lib/widgets/item_card_option_chip.dart` | 교체 |
| `lib/widgets/login_button.dart` | 교체 |
| `lib/widgets/native_ad_widget.dart` | 교체 |
| `lib/widgets/register_input_form.dart` | 교체 (size: 10) |
| `lib/widgets/user_profile_circular_avatar.dart` | 교체 |
| `lib/widgets/common/cached_image.dart` | 교체 (onDark) |

**제외:**
- `lib/deprecated/` — 주석 처리된 코드
- `lib/widgets/skeletons/` — 스켈레톤 유지
- `lib/widgets/common/completion_button.dart` — 흰색(textColorWhite) 사용, 별도 캡슐화됨

---

## Task 1: AppLoadingIndicator 위젯 생성

**Files:**
- Create: `lib/widgets/common/app_loading_indicator.dart`

- [ ] **Step 1: 파일 생성**

`lib/widgets/common/app_loading_indicator.dart` 파일을 아래 내용으로 생성한다:

```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

enum AppLoadingStyle { primary, onDark }

class AppLoadingIndicator extends StatelessWidget {
  final AppLoadingStyle style;
  final double size;
  final double strokeWidth;

  const AppLoadingIndicator({
    super.key,
    this.style = AppLoadingStyle.primary,
    this.size = 24.0,
    this.strokeWidth = 2.5,
  });

  const AppLoadingIndicator.onDark({
    super.key,
    this.size = 24.0,
    this.strokeWidth = 2.5,
  }) : style = AppLoadingStyle.onDark;

  static Widget centered({
    AppLoadingStyle style = AppLoadingStyle.primary,
    double size = 24.0,
    double strokeWidth = 2.5,
  }) {
    return Center(
      child: AppLoadingIndicator(style: style, size: size, strokeWidth: strokeWidth),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = style == AppLoadingStyle.onDark ? AppColors.opacity40White : AppColors.primaryYellow;
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
```

- [ ] **Step 2: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/common/app_loading_indicator.dart
```

- [ ] **Step 3: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze lib/widgets/common/app_loading_indicator.dart
```

Expected: No issues found.

---

## Task 2: screens 교체 (1) — chat, home, item

**Files:**
- Modify: `lib/screens/chat_location_picker_screen.dart`
- Modify: `lib/screens/chat_room_screen.dart`
- Modify: `lib/screens/chat_tab_screen.dart`
- Modify: `lib/screens/home_tab_screen.dart`
- Modify: `lib/screens/item_detail_description_screen.dart`
- Modify: `lib/screens/item_modification_screen.dart`

- [ ] **Step 1: chat_location_picker_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 100)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))

// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 2: chat_room_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 675)
body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),

// After
body: AppLoadingIndicator.centered(),
```

- [ ] **Step 3: chat_tab_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 393) — SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2))
child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),

// After
child: AppLoadingIndicator(size: 20, strokeWidth: 2),
```

- [ ] **Step 4: home_tab_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (2곳):
```dart
// Before (line 530)
return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
// After
return AppLoadingIndicator.centered();

// Before (line 593)
return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
// After
return AppLoadingIndicator.centered();
```

- [ ] **Step 5: item_detail_description_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (2곳):
```dart
// Before (line 330)
body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
// After
body: AppLoadingIndicator.centered(),

// Before (line 463) — CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryYellow)
child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryYellow),
// After
child: AppLoadingIndicator(strokeWidth: 3),
```

- [ ] **Step 6: item_modification_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 73)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 7: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/chat_location_picker_screen.dart lib/screens/chat_room_screen.dart lib/screens/chat_tab_screen.dart lib/screens/home_tab_screen.dart lib/screens/item_detail_description_screen.dart lib/screens/item_modification_screen.dart
```

- [ ] **Step 8: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/chat_location_picker_screen.dart lib/screens/chat_room_screen.dart lib/screens/chat_tab_screen.dart lib/screens/home_tab_screen.dart lib/screens/item_detail_description_screen.dart lib/screens/item_modification_screen.dart
```

Expected: No issues found.

---

## Task 3: screens 교체 (2) — item_register, my_page, notification, onboarding

**Files:**
- Modify: `lib/screens/item_register_location_screen.dart`
- Modify: `lib/screens/my_page/block_management_screen.dart`
- Modify: `lib/screens/my_page/my_category_settings_screen.dart`
- Modify: `lib/screens/my_page/my_like_list_screen.dart`
- Modify: `lib/screens/my_page/my_profile_edit_screen.dart`
- Modify: `lib/screens/my_page/terms_screen.dart`
- Modify: `lib/screens/notification_screen.dart`
- Modify: `lib/screens/notification_settings_screen.dart`
- Modify: `lib/screens/onboarding/term_agreement_step.dart`

- [ ] **Step 1: item_register_location_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 106)
? const Center(child: CircularProgressIndicator())
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 2: block_management_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 95)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 3: my_category_settings_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 72)
? const Center(child: CircularProgressIndicator())
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 4: my_like_list_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (2곳):
```dart
// Before (line 162)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()

// Before (line 188)
child: CircularProgressIndicator(color: AppColors.primaryYellow),
// After
child: AppLoadingIndicator(),
```

- [ ] **Step 5: my_profile_edit_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 265)
child: const CircularProgressIndicator(color: AppColors.primaryYellow),
// After
child: AppLoadingIndicator(),
```

- [ ] **Step 6: terms_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 56)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 7: notification_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 447)
child: const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2)),
// After
child: AppLoadingIndicator.centered(strokeWidth: 2),
```

- [ ] **Step 8: notification_settings_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 129)
? const Center(child: CircularProgressIndicator())
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 9: term_agreement_step.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 117)
return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
// After
return AppLoadingIndicator.centered();
```

- [ ] **Step 10: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_register_location_screen.dart lib/screens/my_page/block_management_screen.dart lib/screens/my_page/my_category_settings_screen.dart lib/screens/my_page/my_like_list_screen.dart lib/screens/my_page/my_profile_edit_screen.dart lib/screens/my_page/terms_screen.dart lib/screens/notification_screen.dart lib/screens/notification_settings_screen.dart lib/screens/onboarding/term_agreement_step.dart
```

- [ ] **Step 11: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/item_register_location_screen.dart lib/screens/my_page/block_management_screen.dart lib/screens/my_page/my_category_settings_screen.dart lib/screens/my_page/my_like_list_screen.dart lib/screens/my_page/my_profile_edit_screen.dart lib/screens/my_page/terms_screen.dart lib/screens/notification_screen.dart lib/screens/notification_settings_screen.dart lib/screens/onboarding/term_agreement_step.dart
```

Expected: No issues found.

---

## Task 4: screens 교체 (3) — profile, register, request, search, trade

**Files:**
- Modify: `lib/screens/profile/member_profile_screen.dart`
- Modify: `lib/screens/register_tab_screen.dart`
- Modify: `lib/screens/request_management_tab_screen.dart`
- Modify: `lib/screens/search_range_setting_screen.dart`
- Modify: `lib/screens/trade_complete_partner_select_screen.dart`
- Modify: `lib/screens/trade_request_screen.dart`

- [ ] **Step 1: member_profile_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 195)
body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
// After
body: AppLoadingIndicator.centered(),
```

- [ ] **Step 2: register_tab_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 367)
child: const Center(child: CircularProgressIndicator()),
// After
child: AppLoadingIndicator.centered(),
```

- [ ] **Step 3: request_management_tab_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (4곳 — strokeWidth: 2 유지):
```dart
// Before (line 294)
child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2)),
// After
child: AppLoadingIndicator.centered(strokeWidth: 2),

// Before (line 569)
child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2)),
// After
child: AppLoadingIndicator.centered(strokeWidth: 2),

// Before (line 724)
child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2)),
// After
child: AppLoadingIndicator.centered(strokeWidth: 2),

// Before (line 741)
child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow, strokeWidth: 2)),
// After
child: AppLoadingIndicator.centered(strokeWidth: 2),
```

- [ ] **Step 4: search_range_setting_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 75)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 5: trade_complete_partner_select_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 72)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 6: trade_request_screen.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (2곳 — line 404는 textColorBlack → primary로 통일):
```dart
// Before (line 229)
? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
// After
? AppLoadingIndicator.centered()

// Before (line 404) — textColorBlack → primaryYellow로 통일
child: const CircularProgressIndicator(color: AppColors.textColorBlack, strokeWidth: 2),
// After
child: AppLoadingIndicator(strokeWidth: 2),
```

- [ ] **Step 7: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/profile/member_profile_screen.dart lib/screens/register_tab_screen.dart lib/screens/request_management_tab_screen.dart lib/screens/search_range_setting_screen.dart lib/screens/trade_complete_partner_select_screen.dart lib/screens/trade_request_screen.dart
```

- [ ] **Step 8: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze lib/screens/profile/member_profile_screen.dart lib/screens/register_tab_screen.dart lib/screens/request_management_tab_screen.dart lib/screens/search_range_setting_screen.dart lib/screens/trade_complete_partner_select_screen.dart lib/screens/trade_request_screen.dart
```

Expected: No issues found.

---

## Task 5: widgets 교체

**Files:**
- Modify: `lib/widgets/chat_image_bubble.dart`
- Modify: `lib/widgets/chat_location_bubble.dart`
- Modify: `lib/widgets/chat_message_item.dart`
- Modify: `lib/widgets/item_card_option_chip.dart`
- Modify: `lib/widgets/login_button.dart`
- Modify: `lib/widgets/native_ad_widget.dart`
- Modify: `lib/widgets/register_input_form.dart`
- Modify: `lib/widgets/user_profile_circular_avatar.dart`
- Modify: `lib/widgets/common/cached_image.dart`

- [ ] **Step 1: chat_image_bubble.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (2곳 — SizedBox 제거 후 size 파라미터 사용):
```dart
// Before (line 155)
child: SizedBox(width: 32, height: 32, child: CircularProgressIndicator(color: AppColors.primaryYellow)),
// After
child: AppLoadingIndicator(size: 32),

// Before (line 177)
child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: AppColors.primaryYellow)),
// After
child: AppLoadingIndicator(size: 24),
```

- [ ] **Step 2: chat_location_bubble.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 167)
child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryYellow),
// After
child: AppLoadingIndicator(strokeWidth: 2),
```

- [ ] **Step 3: chat_message_item.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 326)
child: CircularProgressIndicator(color: AppColors.primaryYellow),
// After
child: AppLoadingIndicator(),
```

- [ ] **Step 4: item_card_option_chip.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 79)
child: const CircularProgressIndicator(strokeWidth: 2),
// After
child: AppLoadingIndicator(strokeWidth: 2),
```

- [ ] **Step 5: login_button.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 55)
child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
// After
child: AppLoadingIndicator.centered(),
```

- [ ] **Step 6: native_ad_widget.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 69)
child: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
// After
child: AppLoadingIndicator.centered(),
```

- [ ] **Step 7: register_input_form.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경 (SizedBox + Padding 구조 내부, size: 10으로 오버라이드):
```dart
// Before (line 841-850)
Padding(
  padding: EdgeInsets.all(12.w),
  child: SizedBox(
    width: 10.w,
    height: 10.w,
    child: CircularProgressIndicator(
      strokeWidth: 2.w,
      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryYellow),
    ),
  ),
)
// After
Padding(
  padding: EdgeInsets.all(12.w),
  child: AppLoadingIndicator(size: 10, strokeWidth: 2),
)
```

- [ ] **Step 8: user_profile_circular_avatar.dart 교체**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 83)
? const Center(child: CircularProgressIndicator())
// After
? AppLoadingIndicator.centered()
```

- [ ] **Step 9: cached_image.dart 교체 (onDark)**

import 추가:
```dart
import 'package:romrom_fe/widgets/common/app_loading_indicator.dart';
```

변경:
```dart
// Before (line 68)
child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.opacity40White),
// After
child: AppLoadingIndicator.onDark(strokeWidth: 2),
```

- [ ] **Step 10: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/chat_image_bubble.dart lib/widgets/chat_location_bubble.dart lib/widgets/chat_message_item.dart lib/widgets/item_card_option_chip.dart lib/widgets/login_button.dart lib/widgets/native_ad_widget.dart lib/widgets/register_input_form.dart lib/widgets/user_profile_circular_avatar.dart lib/widgets/common/cached_image.dart
```

- [ ] **Step 11: flutter analyze 확인**

```bash
source ~/.zshrc && flutter analyze lib/widgets/
```

Expected: No issues found.

---

## Task 6: 전체 검증 및 잔여 CircularProgressIndicator 확인

**Files:** 없음 (검증만)

- [ ] **Step 1: 잔여 CircularProgressIndicator 검색**

```bash
grep -rn "CircularProgressIndicator" lib/ --include="*.dart" | grep -v "deprecated" | grep -v "skeletons" | grep -v "completion_button"
```

Expected: 결과가 없거나, `app_loading_indicator.dart` 1개만 남아야 함.

- [ ] **Step 2: 전체 flutter analyze 실행**

```bash
source ~/.zshrc && flutter analyze
```

Expected: No issues found.

- [ ] **Step 3: 전체 dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 .
```
