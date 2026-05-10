# 채팅 입력창 멀티라인 UI 개선 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 채팅 입력창에서 여러 줄 입력 시 버튼들을 하단 고정하고, 라운드 값을 동적으로 자연스럽게 전환하여 UI 품질 개선

**Architecture:** ChatInputBar 위젯을 StatelessWidget에서 변경 없이 유지하되, 외부에서 전달받는 `inputFieldHeight` 값을 기반으로 (1) Row의 crossAxisAlignment를 end로 변경하여 버튼 하단 고정, (2) borderRadius를 높이 비율로 동적 계산하여 자연스러운 라운드 전환 구현. 전송 버튼은 suffixIcon에서 분리하여 Row의 독립 자식으로 배치.

**Tech Stack:** Flutter, flutter_screenutil

**이슈:** https://github.com/TEAM-ROMROM/RomRom-FE/issues/716

**Worktree:** `D:\0-suh\project\RomRom-FE-Worktree\20260327__716_채팅_입력창_멀티라인_입력_시_UI_개선`

---

## 파일 구조

| 파일 | 변경 유형 | 역할 |
|------|----------|------|
| `lib/widgets/chat_input_bar.dart` | Modify | 버튼 하단 정렬, 라운드 동적 계산, 전송 버튼 분리 |
| `lib/screens/chat_room_screen.dart` | Modify | 높이 계산 로직 보강 (maxLines 대응) |

---

## Task 1: ChatInputBar — 버튼 하단 고정 + 전송 버튼 분리 + 라운드 동적 전환

**Files:**
- Modify: `lib/widgets/chat_input_bar.dart` (전체)

### 현재 문제 분석

1. **Row의 `crossAxisAlignment: CrossAxisAlignment.center`** → 버튼들이 입력창 중간에 위치
2. **전송 버튼이 `suffixIcon`으로 TextField 내부에 있음** → TextField 높이에 종속되어 하단 고정 불가
3. **`BorderRadius.circular(100.r)`** → 여러 줄일 때 과도한 라운드

### 변경 설계

- `crossAxisAlignment`를 `CrossAxisAlignment.end`로 변경 → +버튼, 전송 버튼 모두 하단 고정
- 전송 버튼을 `suffixIcon`에서 빼내어 Row의 세 번째 자식으로 분리 → TextField와 독립적으로 하단 정렬
- `borderRadius`를 `inputFieldHeight` 기반으로 동적 계산:
  - 1줄 (40.h): `borderRadius = 높이/2` ≈ 캡슐형
  - 여러 줄 (40.h ~ 70.h): 높이가 커질수록 `borderRadius`가 `20.r`까지 선형 보간(lerp)
  - 공식: `radius = lerpDouble(height/2, 20.r, (height - minH) / (maxH - minH))`

---

- [ ] **Step 1: 전송 버튼을 suffixIcon에서 Row 자식으로 분리**

`lib/widgets/chat_input_bar.dart`를 다음과 같이 수정:

```dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/context_menu_enums.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

/// 채팅방 하단 메시지 입력 바
class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isInputDisabled;
  final bool isSendingMessage;
  final bool hasText;
  final double inputFieldHeight;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isInputDisabled,
    required this.isSendingMessage,
    required this.hasText,
    required this.inputFieldHeight,
    required this.hintText,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = Platform.isIOS ? 8.h + MediaQuery.of(context).padding.bottom : 21.h;
    final bool sendDisabled = !hasText || isInputDisabled || isSendingMessage;

    // 동적 라운드 계산: 1줄(캡슐형) → 여러 줄(20.r 둥근 사각형)
    final double minH = 40.h;
    final double maxH = 70.h;
    final double clampedHeight = inputFieldHeight.clamp(minH, maxH);
    final double t = maxH > minH ? ((clampedHeight - minH) / (maxH - minH)) : 0.0;
    final double borderRadius = lerpDouble(clampedHeight / 2, 20.r, t)!;

    return Container(
      padding: EdgeInsets.only(top: 8.h, left: 16.w, bottom: bottomPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // + 버튼 (하단 고정)
          Padding(
            padding: EdgeInsets.only(right: 8.0.w, bottom: 0),
            child: SizedBox(
              width: 40.w,
              height: 40.w,
              child: IgnorePointer(
                ignoring: isInputDisabled,
                child: RomRomContextMenu(
                  position: ContextMenuPosition.above,
                  triggerRotationDegreesOnOpen: 45,
                  customTrigger: Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: const BoxDecoration(color: AppColors.secondaryBlack1, shape: BoxShape.circle),
                    child: Icon(AppIcons.addItemPlus, color: AppColors.textColorWhite, size: 20.sp),
                  ),
                  items: [
                    ContextMenuItem(
                      id: 'select_photo',
                      icon: AppIcons.chatImage,
                      iconColor: AppColors.opacity60White,
                      title: '사진 선택하기',
                      onTap: () => onPickImage(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 텍스트 입력 필드 (suffixIcon 제거)
          Expanded(
            child: SizedBox(
              height: clampedHeight,
              child: TextField(
                controller: controller,
                enabled: !isInputDisabled,
                style: CustomTextStyles.p2.copyWith(
                  color: AppColors.textColorWhite,
                  fontWeight: FontWeight.w400,
                  height: 1.2,
                ),
                minLines: 1,
                maxLines: 5,
                cursorHeight: 16.h,
                cursorColor: AppColors.primaryYellow,
                cursorWidth: 1.5.w,
                decoration: InputDecoration(
                  hintText: hintText,
                  hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity50White),
                  filled: true,
                  fillColor: AppColors.opacity10White,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                ),
                onSubmitted: sendDisabled ? null : (_) => onSend(),
              ),
            ),
          ),
          // 전송 버튼 (Row 자식으로 분리, 하단 고정)
          Padding(
            padding: EdgeInsets.only(left: 4.w, right: 16.w),
            child: SizedBox(
              width: 40.w,
              height: 40.w,
              child: Material(
                color: Colors.transparent,
                child: ClipOval(
                  child: InkWell(
                    onTap: sendDisabled ? null : onSend,
                    customBorder: const CircleBorder(),
                    highlightColor: AppColors.buttonHighlightColorGray,
                    splashColor: AppColors.buttonHighlightColorGray.withValues(alpha: 0.3),
                    child: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: sendDisabled ? AppColors.secondaryBlack2 : AppColors.primaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          AppIcons.arrowUpward,
                          color: sendDisabled ? AppColors.secondaryBlack1 : AppColors.primaryBlack,
                          size: 32.w,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: chat_room_screen.dart — 높이 계산 보강**

`lib/screens/chat_room_screen.dart`의 `_updateInputFieldHeight` 메서드를 수정하여, 텍스트가 줄바꿈 없이 자동 줄넘김되는 경우도 대응:

```dart
void _updateInputFieldHeight() {
  final lineCount = '\n'.allMatches(_messageController.text).length + 1;
  final clampedLines = lineCount.clamp(1, 5);
  double newHeight = 40.h + ((clampedLines - 1) * 7.5.h);
  newHeight = newHeight.clamp(40.h, 70.h);
  if (_inputFieldHeight != newHeight && mounted) {
    setState(() => _inputFieldHeight = newHeight);
  }
}
```

> **변경 이유**: 기존 `14.h` 간격은 줄이 늘어날 때 높이가 너무 급격히 증가. `7.5.h`로 완만하게 조정하여 라운드 전환도 더 자연스럽게.

- [ ] **Step 3: dart format 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/chat_input_bar.dart lib/screens/chat_room_screen.dart
```

- [ ] **Step 4: flutter analyze 실행**

```bash
source ~/.zshrc && flutter analyze
```

에러 발생 시 수정 후 재실행.

- [ ] **Step 5: 수동 테스트 체크리스트**

| 시나리오 | 확인 항목 |
|---------|----------|
| 1줄 입력 | 캡슐형 라운드, +버튼/전송버튼 하단 정렬 |
| 2줄 입력 (Enter 1회) | 라운드 약간 줄어듦, 버튼 하단 유지 |
| 5줄 입력 (Enter 4회) | 라운드 ~20.r, 버튼 하단 고정 |
| 긴 텍스트 (자동 줄넘김) | 높이 자연스럽게 증가 |
| 전송 버튼 비활성 상태 | 회색 원형 유지, 탭 불가 |
| 전송 버튼 활성 상태 | 노란색 원형, 탭 시 전송 |
| + 버튼 기능 | 사진 선택 팝업 정상 동작 |
| iPad | overflow 없음, 레이아웃 정상 |

---

## 변경 요약

| 변경 | Before | After |
|------|--------|-------|
| Row 정렬 | `CrossAxisAlignment.center` | `CrossAxisAlignment.end` |
| 전송 버튼 위치 | `suffixIcon` (TextField 내부) | Row의 세 번째 자식 (독립) |
| BorderRadius | 고정 `100.r` | 동적 `height/2` → `20.r` (선형 보간) |
| 높이 증가 간격 | `14.h` per line | `7.5.h` per line |
| 우측 여백 | `SizedBox(width: 16.w)` | 전송 버튼의 `right: 16.w` 패딩 |
