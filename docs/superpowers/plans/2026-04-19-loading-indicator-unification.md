# 로딩 인디케이터 통일 구현 계획 (#761)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 토스 앱 스타일로 로딩 경험 통일 — 초기 로딩은 shimmer 스켈레톤, 인라인/페이징은 공통 스피너

**Architecture:** `CommonLoadingIndicator` 공통 위젯 신규 생성 후 33개 파일의 `CircularProgressIndicator` 직접 사용을 교체. 5개 화면의 초기 로딩에 shimmer 스켈레톤 신규 추가. 기존 3개 스켈레톤은 유지.

**Tech Stack:** Flutter, skeletonizer ^2.1.0+1 (추가 패키지 없음), AppColors, CustomTextStyles

---

## 파일 구조

**신규 생성:**
- `lib/widgets/common/loading_indicator.dart` — `CommonLoadingIndicator` 스피너 래퍼
- `lib/widgets/skeletons/home_feed_skeleton.dart` — 홈 피드 초기 로딩 스켈레톤
- `lib/widgets/skeletons/item_detail_skeleton.dart` — 물품 상세 초기 로딩 스켈레톤
- `lib/widgets/skeletons/my_like_list_skeleton.dart` — 찜 목록 초기 로딩 스켈레톤
- `lib/widgets/skeletons/notification_settings_skeleton.dart` — 알림 설정 초기 로딩 스켈레톤
- `lib/widgets/skeletons/trade_partner_select_skeleton.dart` — 거래 파트너 선택 스켈레톤

**수정:**
- `lib/screens/home_tab_screen.dart` — 초기 로딩 스피너 → 스켈레톤, 페이징 스피너 → CommonLoadingIndicator
- `lib/screens/item_detail_description_screen.dart` — 초기 로딩 스피너 → 스켈레톤
- `lib/screens/my_page/my_like_list_screen.dart` — 초기 로딩 스피너 → 스켈레톤, 페이징 → CommonLoadingIndicator
- `lib/screens/notification_settings_screen.dart` — 초기 로딩 스피너 → 스켈레톤
- `lib/screens/trade_complete_partner_select_screen.dart` — 초기 로딩 스피너 → 스켈레톤
- 그 외 28개 파일 — `CircularProgressIndicator` → `CommonLoadingIndicator`

---

## Task 1: CommonLoadingIndicator 공통 위젯 생성

**Files:**
- Create: `lib/widgets/common/loading_indicator.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 앱 전역 공통 로딩 스피너. CircularProgressIndicator 직접 사용 금지 — 이 위젯 사용.
class CommonLoadingIndicator extends StatelessWidget {
  const CommonLoadingIndicator({super.key, this.color = AppColors.primaryYellow, this.size = 24.0});

  /// 버튼 내부 흰색 스피너용 named constructor
  const CommonLoadingIndicator.white({super.key, this.size = 18.0}) : color = AppColors.textColorWhite;

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/common/loading_indicator.dart
```

- [ ] **Step 3: 린트 확인**

```bash
source ~/.zshrc && flutter analyze lib/widgets/common/loading_indicator.dart
```
Expected: No issues found.

---

## Task 2: HomeFeedSkeleton 스켈레톤 생성

홈 피드는 `PageView.builder` 기반 세로 스크롤 구조. 초기 로딩 시 전체 화면을 shimmer로 채운다.

**Files:**
- Create: `lib/widgets/skeletons/home_feed_skeleton.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 홈 피드 초기 로딩 스켈레톤 — PageView 전체화면 shimmer
class HomeFeedSkeleton extends StatelessWidget {
  const HomeFeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: AppColors.opacity10White,
        highlightColor: AppColors.opacity30White,
      ),
      child: Container(
        width: width,
        height: height,
        color: AppColors.primaryBlack,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역 (화면 상단 대부분 차지)
            Skeleton.leaf(
              child: Container(
                width: width,
                height: height * 0.6,
                color: AppColors.opacity10White,
              ),
            ),
            const SizedBox(height: 16),
            // 제목 라인
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(
                    child: Container(width: width * 0.55, height: 18, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 10),
                  Skeleton.leaf(
                    child: Container(width: width * 0.35, height: 15, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 10),
                  Skeleton.leaf(
                    child: Container(width: width * 0.45, height: 13, color: AppColors.opacity10White),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/skeletons/home_feed_skeleton.dart && flutter analyze lib/widgets/skeletons/home_feed_skeleton.dart
```
Expected: No issues found.

---

## Task 3: ItemDetailSkeleton 스켈레톤 생성

물품 상세 화면 구조: 전체 너비 이미지 → 프로필 → 제목/가격 → 설명.

**Files:**
- Create: `lib/widgets/skeletons/item_detail_skeleton.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 물품 상세 초기 로딩 스켈레톤
class ItemDetailSkeleton extends StatelessWidget {
  const ItemDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: AppColors.opacity10White,
        highlightColor: AppColors.opacity30White,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 영역
            Skeleton.leaf(
              child: Container(width: width, height: 300, color: AppColors.opacity10White),
            ),
            const SizedBox(height: 16),
            // 프로필 행
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Skeleton.leaf(
                    child: const CircleAvatar(radius: 20, backgroundColor: AppColors.opacity10White),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Skeleton.leaf(
                        child: Container(width: 80, height: 13, color: AppColors.opacity10White),
                      ),
                      const SizedBox(height: 6),
                      Skeleton.leaf(
                        child: Container(width: 55, height: 11, color: AppColors.opacity10White),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 제목 + 가격
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(
                    child: Container(width: width * 0.7, height: 18, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 10),
                  Skeleton.leaf(
                    child: Container(width: width * 0.4, height: 16, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 16),
                  // 설명 텍스트 3줄
                  Skeleton.leaf(
                    child: Container(width: width - 32, height: 12, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 6),
                  Skeleton.leaf(
                    child: Container(width: (width - 32) * 0.85, height: 12, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 6),
                  Skeleton.leaf(
                    child: Container(width: (width - 32) * 0.6, height: 12, color: AppColors.opacity10White),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/skeletons/item_detail_skeleton.dart && flutter analyze lib/widgets/skeletons/item_detail_skeleton.dart
```
Expected: No issues found.

---

## Task 4: MyLikeListSkeleton 스켈레톤 생성

찜 목록은 `ListView.separated` 구조. 썸네일(64×64) + 텍스트 3줄.

**Files:**
- Create: `lib/widgets/skeletons/my_like_list_skeleton.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 찜 목록 초기 로딩 스켈레톤
class MyLikeListSkeleton extends StatelessWidget {
  const MyLikeListSkeleton({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      separatorBuilder: (_, _) => const Divider(color: AppColors.opacity10White, thickness: 1.5),
      itemBuilder: (_, __) => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: AppColors.opacity10White,
          highlightColor: AppColors.opacity30White,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              // 썸네일 (정사각형)
              Skeleton.leaf(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.opacity10White,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 텍스트 3줄
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton.leaf(
                    child: Container(width: width * 0.45, height: 13, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 6),
                  Skeleton.leaf(
                    child: Container(width: width * 0.3, height: 11, color: AppColors.opacity10White),
                  ),
                  const SizedBox(height: 6),
                  Skeleton.leaf(
                    child: Container(width: width * 0.55, height: 11, color: AppColors.opacity10White),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/skeletons/my_like_list_skeleton.dart && flutter analyze lib/widgets/skeletons/my_like_list_skeleton.dart
```
Expected: No issues found.

---

## Task 5: NotificationSettingsSkeleton 스켈레톤 생성

알림 설정은 `SingleChildScrollView > Column` 구조. 각 행: 텍스트 2줄 + 토글 자리.

**Files:**
- Create: `lib/widgets/skeletons/notification_settings_skeleton.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 알림 설정 초기 로딩 스켈레톤
class NotificationSettingsSkeleton extends StatelessWidget {
  const NotificationSettingsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          _buildGroup(width, 4),
          const SizedBox(height: 16),
          _buildGroup(width, 1),
        ],
      ),
    );
  }

  Widget _buildGroup(double width, int rowCount) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF34353D), // AppColors.secondaryBlack1
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: List.generate(rowCount, (i) => _buildRow(width, i, rowCount)),
      ),
    );
  }

  Widget _buildRow(double width, int index, int total) {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: AppColors.opacity10White,
        highlightColor: AppColors.opacity30White,
      ),
      child: SizedBox(
        height: 74,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // 텍스트 영역
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.leaf(
                      child: Container(width: width * 0.35, height: 13, color: AppColors.opacity10White),
                    ),
                    const SizedBox(height: 8),
                    Skeleton.leaf(
                      child: Container(width: width * 0.55, height: 11, color: AppColors.opacity10White),
                    ),
                  ],
                ),
              ),
              // 토글 자리
              Skeleton.leaf(
                child: Container(
                  width: 44,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.opacity10White,
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/skeletons/notification_settings_skeleton.dart && flutter analyze lib/widgets/skeletons/notification_settings_skeleton.dart
```
Expected: No issues found.

---

## Task 6: TradePartnerSelectSkeleton 스켈레톤 생성

거래 파트너 선택은 `ListView` 구조. 각 행: 원형 프로필 + 이름/위치 2줄 + 버튼 자리.

**Files:**
- Create: `lib/widgets/skeletons/trade_partner_select_skeleton.dart`

- [ ] **Step 1: 파일 생성**

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 거래 파트너 선택 초기 로딩 스켈레톤
class TradePartnerSelectSkeleton extends StatelessWidget {
  const TradePartnerSelectSkeleton({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: itemCount,
      itemBuilder: (_, __) => Skeletonizer(
        enabled: true,
        effect: const ShimmerEffect(
          baseColor: AppColors.opacity10White,
          highlightColor: AppColors.opacity30White,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            children: [
              // 원형 프로필
              Skeleton.leaf(
                child: const CircleAvatar(radius: 22, backgroundColor: AppColors.opacity10White),
              ),
              const SizedBox(width: 12),
              // 이름 + 위치
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Skeleton.leaf(
                      child: Container(width: width * 0.35, height: 13, color: AppColors.opacity10White),
                    ),
                    const SizedBox(height: 6),
                    Skeleton.leaf(
                      child: Container(width: width * 0.25, height: 11, color: AppColors.opacity10White),
                    ),
                  ],
                ),
              ),
              // 선택 버튼 자리
              Skeleton.leaf(
                child: Container(
                  width: 60,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.opacity10White,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/skeletons/trade_partner_select_skeleton.dart && flutter analyze lib/widgets/skeletons/trade_partner_select_skeleton.dart
```
Expected: No issues found.

---

## Task 7: 홈 피드 로딩 교체

**Files:**
- Modify: `lib/screens/home_tab_screen.dart:529-530, 593`

- [ ] **Step 1: import 추가**

파일 상단 import 목록에 추가:
```dart
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/skeletons/home_feed_skeleton.dart';
```

- [ ] **Step 2: 초기 로딩 교체 (line ~529)**

변경 전:
```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
}
```

변경 후:
```dart
if (_isLoading) {
  return const HomeFeedSkeleton();
}
```

- [ ] **Step 3: 페이징 로딩 교체 (line ~593)**

변경 전:
```dart
return const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow));
```

변경 후:
```dart
return const Center(child: CommonLoadingIndicator());
```

- [ ] **Step 4: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/home_tab_screen.dart && flutter analyze lib/screens/home_tab_screen.dart
```
Expected: No issues found.

---

## Task 8: 물품 상세 로딩 교체

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart:330`

- [ ] **Step 1: import 추가**

```dart
import 'package:romrom_fe/widgets/skeletons/item_detail_skeleton.dart';
```

- [ ] **Step 2: 초기 로딩 교체 (line ~330)**

변경 전:
```dart
body: Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
```

변경 후:
```dart
body: const ItemDetailSkeleton(),
```

- [ ] **Step 3: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_detail_description_screen.dart && flutter analyze lib/screens/item_detail_description_screen.dart
```
Expected: No issues found.

---

## Task 9: 찜 목록 로딩 교체

**Files:**
- Modify: `lib/screens/my_page/my_like_list_screen.dart:161-162, 188`

- [ ] **Step 1: import 추가**

```dart
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/skeletons/my_like_list_skeleton.dart';
```

- [ ] **Step 2: 초기 로딩 교체 (line ~161)**

변경 전:
```dart
body: _items.isEmpty && _isLoading
    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
```

변경 후:
```dart
body: _items.isEmpty && _isLoading
    ? Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const MyLikeListSkeleton(),
      )
```

- [ ] **Step 3: 페이징 로딩 교체 (line ~182)**

변경 전:
```dart
return Padding(
  padding: EdgeInsets.symmetric(vertical: 16.h),
  child: const Center(
    child: SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(color: AppColors.primaryYellow),
    ),
  ),
);
```

변경 후:
```dart
return const Padding(
  padding: EdgeInsets.symmetric(vertical: 16),
  child: Center(child: CommonLoadingIndicator(size: 20)),
);
```

- [ ] **Step 4: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/my_page/my_like_list_screen.dart && flutter analyze lib/screens/my_page/my_like_list_screen.dart
```
Expected: No issues found.

---

## Task 10: 알림 설정 로딩 교체

**Files:**
- Modify: `lib/screens/notification_settings_screen.dart:129`

- [ ] **Step 1: import 추가**

```dart
import 'package:romrom_fe/widgets/skeletons/notification_settings_skeleton.dart';
```

- [ ] **Step 2: 초기 로딩 교체 (line ~128)**

변경 전:
```dart
body: _isLoading
    ? const Center(child: CircularProgressIndicator())
```

변경 후:
```dart
body: _isLoading
    ? const NotificationSettingsSkeleton()
```

- [ ] **Step 3: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/notification_settings_screen.dart && flutter analyze lib/screens/notification_settings_screen.dart
```
Expected: No issues found.

---

## Task 11: 거래 파트너 선택 로딩 교체

**Files:**
- Modify: `lib/screens/trade_complete_partner_select_screen.dart:72`

- [ ] **Step 1: import 추가**

```dart
import 'package:romrom_fe/widgets/skeletons/trade_partner_select_skeleton.dart';
```

- [ ] **Step 2: 초기 로딩 교체 (line ~71)**

변경 전:
```dart
child: _isLoading
    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))
```

변경 후:
```dart
child: _isLoading
    ? const TradePartnerSelectSkeleton()
```

- [ ] **Step 3: 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/trade_complete_partner_select_screen.dart && flutter analyze lib/screens/trade_complete_partner_select_screen.dart
```
Expected: No issues found.

---

## Task 12: 나머지 28개 파일 CircularProgressIndicator 일괄 교체

아래 파일들의 `CircularProgressIndicator`를 `CommonLoadingIndicator`로 교체한다.
`color:` 인자는 제거(기본값 primaryYellow 사용). `strokeWidth:` 인자도 제거(2.0 고정).
버튼 내부(`completion_button.dart`, `login_button.dart`)는 `CommonLoadingIndicator.white()` 사용.

**Files:**
- Modify: `lib/screens/register_tab_screen.dart`
- Modify: `lib/screens/item_modification_screen.dart`
- Modify: `lib/screens/chat_room_screen.dart`
- Modify: `lib/screens/request_management_tab_screen.dart`
- Modify: `lib/widgets/login_button.dart`
- Modify: `lib/widgets/common/cached_image.dart`
- Modify: `lib/widgets/common/completion_button.dart`
- Modify: `lib/widgets/chat_message_item.dart`
- Modify: `lib/widgets/chat_image_bubble.dart`
- Modify: `lib/widgets/chat_location_bubble.dart`
- Modify: `lib/widgets/register_input_form.dart`
- 그 외 나머지 파일들

- [ ] **Step 1: 각 파일에 import 추가 및 교체**

각 파일마다:
1. `import 'package:romrom_fe/widgets/common/loading_indicator.dart';` 추가
2. `CircularProgressIndicator(color: AppColors.primaryYellow)` → `CommonLoadingIndicator()` 로 교체
3. `SizedBox(width: N, height: N, child: CircularProgressIndicator(...))` → `CommonLoadingIndicator(size: N)` 로 교체
4. 버튼 내부(흰 배경): `CommonLoadingIndicator.white()` 로 교체

`completion_button.dart` 예시:

변경 전:
```dart
CircularProgressIndicator(strokeWidth: 2, color: AppColors.textColorWhite)
```

변경 후:
```dart
const CommonLoadingIndicator.white()
```

`cached_image.dart` 예시:

변경 전:
```dart
placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: AppColors.primaryYellow)),
```

변경 후:
```dart
placeholder: (context, url) => const Center(child: CommonLoadingIndicator()),
```

- [ ] **Step 2: 전체 포맷 및 린트**

```bash
source ~/.zshrc && dart format --line-length=120 . && flutter analyze
```
Expected: No issues found.

---

## Task 13: 최종 검증 및 전체 린트

- [ ] **Step 1: 전체 포맷 및 린트 최종 확인**

```bash
source ~/.zshrc && dart format --line-length=120 . && flutter analyze
```
Expected: No issues found.

- [ ] **Step 2: `CircularProgressIndicator` 직접 사용 잔존 여부 확인**

```bash
grep -rn "CircularProgressIndicator" lib/ --include="*.dart"
```

Expected: 결과 없음. (있으면 해당 파일도 교체)
