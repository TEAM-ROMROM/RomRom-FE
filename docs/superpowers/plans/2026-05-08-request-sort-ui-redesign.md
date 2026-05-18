# 요청 관리 정렬 UI 재설계 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 요청 관리 탭의 정렬 버튼·바텀시트 UI를 재설계 — 보더 pill 정렬칩 + Mattermost 스타일 바텀시트로 교체. 토글 라벨 `교환 완료된 글표시` → `완료 표시` 단축.

**Architecture:**
1. `request_sort_bottom_sheet.dart` 내부 위젯 `_RequestSortSheet` 의 `build` 전면 재작성 (좌측 굵은 제목, 옵션 디바이더 제거).
2. `request_management_tab_screen.dart` 내 정렬 칩 부분(`GestureDetector + Row`) 을 보더 pill 스타일로 교체 + 토글 라벨 단축. 헤더 레이아웃은 기존 구조 유지(같은 Row에 정렬 칩 + 토글) 단 시각 스타일만 변경.

**Tech Stack:** Flutter, Dart, ScreenUtil(`.sp` 폰트만, 칩 사이즈/패딩은 고정 픽셀), `AppColors`, `CustomTextStyles`.

**Spec:** `docs/superpowers/specs/2026-05-08-request-sort-ui-redesign-design.md`

**Issue:** [#794](https://github.com/TEAM-ROMROM/RomRom-FE/issues/794)

**Branch:** `20260420_#794_요청_목록_정렬_필터_기능_추가`

**Worktree:** `D:\0-suh\project\RomRom-FE-Worktree\20260420_794_요청_목록_정렬_필터_기능_추가`

---

## File Structure

| 파일 | 책임 | 변경 종류 |
|------|------|----------|
| `lib/widgets/common/request_sort_bottom_sheet.dart` | 정렬 바텀시트 UI 전담 | 수정 (build 재작성) |
| `lib/screens/request_management_tab_screen.dart` | 요청 관리 탭 화면, 정렬 칩 + 토글 영역 포함 | 수정 (정렬 칩 스타일 + 토글 라벨) |
| `lib/enums/request_sort_type.dart` | 정렬 enum | 변경 없음 |

---

## 절대 규칙

- **`flutter analyze` / `flutter build` / `flutter test` / `flutter pub get` 실행 금지** (내부망 환경, 외부 패키지 다운로드 불가).
- 코드 수정 후 **`dart format --line-length=120 .` 만** 실행.
- **사용자 명시적 승인 없이 `git commit` / `git add` 절대 금지.** 모든 step의 Commit 단계는 "사용자 승인 받기"로 대체.
- 위젯 테스트 작성 — Dart `flutter test` 실행 불가하므로 본 plan에서는 위젯 단위 자동 테스트 작성하지 않음. 시각 검증은 사용자 수동(QA) 으로 수행.

---

## Task 1: 바텀시트 디자인 전면 교체 (Mattermost 스타일)

**Files:**
- Modify: `lib/widgets/common/request_sort_bottom_sheet.dart` (전체)

**목표:** 좌측 굵은 제목 + 디바이더 제거 + 선택 항목만 노랑·✓ 표시.

**스펙 매핑:** spec `## UI 디자인 결정 → 4. 바텀시트 — Mattermost 스타일`

- [ ] **Step 1: 현재 파일 백업 의사 확인 (사용자에게 묻지 말고 git 추적 중이므로 그냥 진행)**

이 step은 액션 없음 — git 추적 상태이므로 변경 후 diff 확인 가능.

- [ ] **Step 2: `request_sort_bottom_sheet.dart` 전체 내용 교체**

파일 경로: `lib/widgets/common/request_sort_bottom_sheet.dart`

기존 86줄 전체를 아래 내용으로 교체:

```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class RequestSortBottomSheet {
  const RequestSortBottomSheet._();

  static Future<void> show({
    required BuildContext context,
    required RequestSortType currentSort,
    required ValueChanged<RequestSortType> onSelected,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSortSheet(currentSort: currentSort, onSelected: onSelected),
    );
  }
}

class _RequestSortSheet extends StatelessWidget {
  final RequestSortType currentSort;
  final ValueChanged<RequestSortType> onSelected;

  const _RequestSortSheet({required this.currentSort, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primaryBlack,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          // 드래그 핸들
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.opacity30White,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // "정렬" 제목 — 좌측 정렬, 굵게
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              '정렬',
              style: CustomTextStyles.p1.copyWith(
                color: AppColors.textColorWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // 옵션 목록 — 디바이더 없음
          ...RequestSortType.values.map((type) => _buildOption(context, type)),
          SizedBox(height: 16 + bottomInset),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, RequestSortType type) {
    final isSelected = type == currentSort;
    return InkWell(
      onTap: () {
        onSelected(type);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              type.label,
              style: CustomTextStyles.p1.copyWith(
                color: isSelected ? AppColors.primaryYellow : AppColors.textColorWhite,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: AppColors.primaryYellow, size: 18),
          ],
        ),
      ),
    );
  }
}
```

**변경 핵심:**
- 가운데 정렬 작은 회색 "정렬" 텍스트 → 좌측 굵은 제목 (`p1`, w600, white)
- `Divider` 제거 (제목 아래 1px 라인 삭제)
- 옵션 행 `Border(bottom: BorderSide(...))` 제거 (옵션 사이 디바이더 삭제)
- 옵션 패딩 `vertical: 16, horizontal: 24` → `vertical: 16, horizontal: 20` (제목 정렬 라인 일치)
- 하단 `SizedBox` 에 `MediaQuery.padding.bottom` 더해 iOS safe area 처리
- 핸들은 `Center` 위젯으로 명시 가운데 정렬 (Column `crossAxisAlignment: stretch` 사용 위해)

- [ ] **Step 3: 포매팅**

```bash
dart format --line-length=120 lib/widgets/common/request_sort_bottom_sheet.dart
```

- [ ] **Step 4: 시각 검증 (수동)**

사용자에게 확인 요청:
- 받은 요청 정렬 칩 탭 → 바텀시트 노출
- 좌측 "정렬" 제목 굵게, 옵션 사이 라인 없음, 선택 항목만 노랑 + ✓
- iPad에서 모달 폭 정상

- [ ] **Step 5: 사용자 승인 받기 → 커밋**

사용자 승인 후 (자동 커밋 금지):

```bash
git add lib/widgets/common/request_sort_bottom_sheet.dart
git commit -m "요청 목록 정렬·필터 기능 추가 : feat : 바텀시트 디자인 Mattermost 스타일로 변경 https://github.com/TEAM-ROMROM/RomRom-FE/issues/794"
```

> 커밋은 `/cassiiopeia:commit` 거치는 것이 표준이지만, 본 plan에서는 사용자 승인 후 직접 커밋. 사용자 명시 요청 시 `/cassiiopeia:commit` 호출.

---

## Task 2: 정렬 칩 — 보더 pill 스타일로 변경 (받은 요청)

**Files:**
- Modify: `lib/screens/request_management_tab_screen.dart` (`_buildRequestListHeader` 영역, 약 710~744줄)

**목표:** 받은 요청 헤더의 정렬 버튼을 인라인 노란 텍스트 → 보더 pill 칩으로 교체. 토글 라벨 `교환 완료된 글표시` → `완료 표시`.

**스펙 매핑:** spec `## UI 디자인 결정 → 1. 정렬 버튼 — 보더 pill 칩` + `## 2. 토글 라벨 단축`

- [ ] **Step 1: 현재 코드 위치 확인**

`lib/screens/request_management_tab_screen.dart` 의 `_buildRequestListHeader` 메서드 안 다음 블록 (약 710~744줄):

```dart
// 정렬 버튼 + 완료된 요청 필터 토글
Row(
  children: [
    // 정렬 버튼 (신규)
    GestureDetector(
      onTap: () => RequestSortBottomSheet.show(
        context: context,
        currentSort: _receivedSortType,
        onSelected: (selected) => setState(() => _receivedSortType = selected),
      ),
      child: Row(
        children: [
          Text(
            _receivedSortType.label,
            style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryYellow, size: 14),
        ],
      ),
    ),
    const SizedBox(width: 12),
    Text(
      '교환 완료된 글표시',
      style: CustomTextStyles.p3.copyWith(
        color: const Color(0x80FFFFFF),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5.sp,
      ),
    ),
    SizedBox(width: 8.w),
    CompletedToggleSwitch(value: _showCompletedRequests, onChanged: _toggleCompletedRequests),
  ],
),
```

- [ ] **Step 2: 위 블록 전체를 아래로 교체**

```dart
// 정렬 칩 (보더 pill) + 완료 표시 토글
Row(
  children: [
    _buildSortChip(
      currentSort: _receivedSortType,
      onChanged: (selected) => setState(() => _receivedSortType = selected),
    ),
    const SizedBox(width: 12),
    Text(
      '완료 표시',
      style: CustomTextStyles.p3.copyWith(
        color: const Color(0x80FFFFFF),
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5.sp,
      ),
    ),
    SizedBox(width: 8.w),
    CompletedToggleSwitch(value: _showCompletedRequests, onChanged: _toggleCompletedRequests),
  ],
),
```

- [ ] **Step 3: `_buildSortChip` private 메서드 추가**

`_RequestManagementTabScreenState` 클래스 안 적당한 위치(예: `_buildRequestListHeader` 메서드 바로 아래) 에 추가:

```dart
/// 정렬 칩 (보더 pill 스타일)
Widget _buildSortChip({
  required RequestSortType currentSort,
  required ValueChanged<RequestSortType> onChanged,
}) {
  return GestureDetector(
    onTap: () => RequestSortBottomSheet.show(
      context: context,
      currentSort: currentSort,
      onSelected: onChanged,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primaryYellow.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentSort.label,
            style: CustomTextStyles.p3.copyWith(
              color: AppColors.primaryYellow,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primaryYellow,
            size: 14,
          ),
        ],
      ),
    ),
  );
}
```

**핵심:**
- 패딩 고정 픽셀 (`12, 5`) — iPad 과확대 방지
- `BorderRadius.circular(20)` — 라운드 pill
- 보더: 노랑 50% opacity, 1px
- 텍스트: `p3`, w500, 노랑

- [ ] **Step 4: 포매팅**

```bash
dart format --line-length=120 lib/screens/request_management_tab_screen.dart
```

- [ ] **Step 5: 시각 검증 (수동)**

사용자 확인 요청:
- 받은 요청 헤더 우측 — 보더 pill 칩 (라운드, 노랑 보더)
- 토글 라벨 "완료 표시" 4자
- 정렬 칩 탭 → 바텀시트 정상 노출
- 칩 탭 영역 충분 (텍스트만 있을 때보다 큼)
- iPad에서 칩 크기 정상 (과확대 X)

- [ ] **Step 6: 사용자 승인 받기 → 커밋**

```bash
git add lib/screens/request_management_tab_screen.dart
git commit -m "요청 목록 정렬·필터 기능 추가 : feat : 받은 요청 정렬 버튼 보더 pill 칩으로 교체 및 토글 라벨 단축 https://github.com/TEAM-ROMROM/RomRom-FE/issues/794"
```

---

## Task 3: 정렬 칩 — 보낸 요청에도 적용

**Files:**
- Modify: `lib/screens/request_management_tab_screen.dart` (`_buildSentRequestsList` 영역, 약 295~318줄)

**목표:** 보낸 요청 헤더의 정렬 버튼도 보더 pill 칩으로 통일.

**스펙 매핑:** spec `## UI 디자인 결정 → 3. 헤더 레이아웃 → 보낸 요청`

- [ ] **Step 1: 현재 코드 확인**

`_buildSentRequestsList` 메서드 안 약 295~318줄:

```dart
return Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    // 정렬 버튼 행 (항상 표시)
    Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 8),
      child: GestureDetector(
        onTap: () => RequestSortBottomSheet.show(
          context: context,
          currentSort: _sentSortType,
          onSelected: (selected) => setState(() => _sentSortType = selected),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_sentSortType.label, style: CustomTextStyles.p3.copyWith(color: AppColors.primaryYellow)),
            const SizedBox(width: 2),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryYellow, size: 14),
          ],
        ),
      ),
    ),
    // 기존 목록/빈상태/로딩
    ...
```

- [ ] **Step 2: `Padding(...)` 블록 안 `GestureDetector` 부분을 `_buildSortChip` 호출로 교체**

해당 `Padding` 블록을 다음으로 교체:

```dart
// 정렬 칩 행 (항상 표시)
Padding(
  padding: const EdgeInsets.fromLTRB(0, 0, 16, 8),
  child: _buildSortChip(
    currentSort: _sentSortType,
    onChanged: (selected) => setState(() => _sentSortType = selected),
  ),
),
```

> 보낸 요청은 토글 없음 — `Column(crossAxisAlignment: CrossAxisAlignment.end)` 로 우측 정렬 유지 (현재와 동일). 제목/설명도 본 PR에서 추가 안 함 (현재 코드에 없음).

- [ ] **Step 3: 포매팅**

```bash
dart format --line-length=120 lib/screens/request_management_tab_screen.dart
```

- [ ] **Step 4: 시각 검증 (수동)**

사용자 확인 요청:
- 보낸 요청 탭 진입 → 우측에 보더 pill 칩 노출 (받은 요청 칩과 동일 스타일)
- 칩 탭 → 바텀시트 노출
- 받은/보낸 요청 정렬 상태 독립 유지 (탭 전환 시 각자 보존)

- [ ] **Step 5: 사용자 승인 받기 → 커밋**

```bash
git add lib/screens/request_management_tab_screen.dart
git commit -m "요청 목록 정렬·필터 기능 추가 : feat : 보낸 요청 정렬 버튼도 보더 pill 칩으로 통일 https://github.com/TEAM-ROMROM/RomRom-FE/issues/794"
```

---

## Task 4: 최종 통합 검증

**Files:** 변경 없음 (검증 단계만)

**목표:** 받은/보낸 요청 + 바텀시트 + iPad 대응 통합 검증.

- [ ] **Step 1: 미사용 import 확인**

`lib/screens/request_management_tab_screen.dart` 와 `lib/widgets/common/request_sort_bottom_sheet.dart` 양쪽에서 미사용 import 정리. (대부분 그대로 사용)

- [ ] **Step 2: 포매팅 한 번 더**

```bash
dart format --line-length=120 .
```

- [ ] **Step 3: 시각 회귀 체크리스트 (사용자 수동 QA)**

| 항목 | 기대 동작 |
|------|----------|
| 받은 요청 — 칩 표시 | 보더 pill, 노랑 보더+텍스트, 라운드 20 |
| 받은 요청 — 토글 라벨 | "완료 표시" |
| 보낸 요청 — 칩 표시 | 받은 요청과 동일 스타일 |
| 칩 탭 — 바텀시트 | 좌측 굵은 제목 "정렬", 디바이더 X |
| 바텀시트 — 선택 항목 | 노랑 + ✓, 비선택은 white w400 |
| 정렬 상태 독립 | 받은/보낸 탭 전환 시 각자 보존 |
| 빈 상태 | 정렬 칩 항상 노출 (보낸 요청 빈 상태 포함) |
| iPad 대응 | 칩 크기 정상 (과확대 X), 모달 폭 정상 |
| 다크모드 | 검정 배경 위 모든 요소 가독성 OK |

- [ ] **Step 4: 사용자 승인 받기 → 통합 커밋 (필요 시)**

추가 정리 변경이 있으면 커밋. 없으면 skip.

---

## Self-Review 결과

**1. Spec coverage:**
- spec `## UI 디자인 결정 → 1. 정렬 버튼 보더 pill` → Task 2 Step 3 (`_buildSortChip`) ✅
- spec `## 2. 토글 라벨 단축` → Task 2 Step 2 (`교환 완료된 글표시` → `완료 표시`) ✅
- spec `## 3. 헤더 레이아웃 → 받은 요청` → Task 2 ✅
- spec `## 3. 헤더 레이아웃 → 보낸 요청` → Task 3 ✅
- spec `## 4. 바텀시트 Mattermost 스타일` → Task 1 ✅
- spec `## 변경 안함` 항목들 — enum/API 호출 — 본 plan에 추가 변경 없음 ✅

**2. Placeholder scan:** TBD/TODO/"적절한 처리" 없음. 모든 step에 실제 코드/명령 포함. ✅

**3. Type consistency:** `_buildSortChip` 시그니처 (`currentSort: RequestSortType`, `onChanged: ValueChanged<RequestSortType>`) — Task 2/3 양쪽에서 동일 호출. enum `RequestSortType.label` 참조 일관. ✅

---

## 후속 작업 (본 plan 범위 외)

- 백엔드 API 정렬 파라미터 명세 확정 후 `_loadReceivedRequestsForCurrentCard` / `_loadSentRequestsForCurrentCard` 에 sort 파라미터 전달
- AI 추천순 라벨 백엔드 합의 따라 조정 가능성
- 본 PR 통합 후 별도 이슈로 추적
