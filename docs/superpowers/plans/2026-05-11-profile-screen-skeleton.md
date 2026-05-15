# Profile Screen Skeleton Shimmer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 프로필 화면(MemberProfileScreen)의 세 섹션이 제각각 로딩되는 UX를 `ProfileScreenSkeleton` shimmer로 통합하고, 모든 데이터 로드 완료 시 한번에 콘텐츠를 노출한다.

**Architecture:** `MemberProfileScreen`에 `_exchangeLoaded` / `_reviewLoaded` 상태를 추가해 `_showContent` 게이트를 만들고, 두 섹션에 `onLoaded` 콜백을 연결한다. 콘텐츠가 보이기 전까지는 새로 만드는 `ProfileScreenSkeleton`이 전체 화면을 점유한다.

**Tech Stack:** Flutter, skeletonizer ^2.1.0+1, flutter_screenutil

---

## File Map

| 역할 | 파일 | 작업 |
|------|------|------|
| 신규 스켈레톤 위젯 | `lib/widgets/skeletons/profile_screen_skeleton.dart` | Create |
| 교환 섹션 콜백 추가 | `lib/widgets/profile/profile_exchange_section.dart` | Modify |
| 리뷰 섹션 콜백 추가 | `lib/widgets/profile/profile_review_section.dart` | Modify |
| 로딩 조율 + 스켈레톤 연결 | `lib/screens/profile/member_profile_screen.dart` | Modify |

---

### Task 1: `ProfileScreenSkeleton` 위젯 생성

**Files:**
- Create: `lib/widgets/skeletons/profile_screen_skeleton.dart`

- [ ] **Step 1: 파일 생성**

`lib/widgets/skeletons/profile_screen_skeleton.dart`를 아래 내용으로 생성한다.  
`ItemDetailSkeleton`과 동일한 `ShimmerEffect` 설정을 사용하고, 고정 픽셀 값(`width: N`, `height: N`)을 사용한다 (iPad 룰 — `.w`/`.h` 스케일링 금지).

```dart
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:romrom_fe/models/app_colors.dart';

class ProfileScreenSkeleton extends StatelessWidget {
  const ProfileScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Skeletonizer(
      enabled: true,
      effect: ShimmerEffect(
        baseColor: AppColors.opacity10White,
        highlightColor: AppColors.opacity30White,
      ),
      child: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              SizedBox(height: 16),
              _OverviewCardSkeleton(),
              SizedBox(height: 16),
              _ExchangeCardSkeleton(),
              SizedBox(height: 16),
              _ReviewCardSkeleton(),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewCardSkeleton extends StatelessWidget {
  const _OverviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 아바타 + 닉네임
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    color: AppColors.opacity10White,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Container(width: 120, height: 20, color: AppColors.opacity10White),
              ],
            ),
            const SizedBox(height: 28),
            // 위치 행
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.opacity10White,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 16),
            // 좋아요 행
            Container(
              width: double.infinity,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.opacity10White,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExchangeCardSkeleton extends StatelessWidget {
  const _ExchangeCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 블록
            Container(width: 80, height: 16, color: AppColors.opacity10White),
            const SizedBox(height: 19),
            // 아이템 카드 3개 (가로)
            Row(
              children: [
                _ItemCardSkeleton(),
                SizedBox(width: 12),
                _ItemCardSkeleton(),
                SizedBox(width: 12),
                _ItemCardSkeleton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemCardSkeleton extends StatelessWidget {
  const _ItemCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.opacity10White,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 80, height: 14, color: AppColors.opacity10White),
        const SizedBox(height: 8),
        Container(width: 60, height: 12, color: AppColors.opacity10White),
        const SizedBox(height: 6),
        Container(width: 70, height: 11, color: AppColors.opacity10White),
      ],
    );
  }
}

class _ReviewCardSkeleton extends StatelessWidget {
  const _ReviewCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton.leaf(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Container(width: 80, height: 16, color: AppColors.opacity10White),
            const SizedBox(height: 16),
            // 후기 카드 1
            _ReviewRowSkeleton(),
            const SizedBox(height: 16),
            // 후기 카드 2
            _ReviewRowSkeleton(),
          ],
        ),
      ),
    );
  }
}

class _ReviewRowSkeleton extends StatelessWidget {
  const _ReviewRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.opacity10White,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 100, height: 13, color: AppColors.opacity10White),
            const SizedBox(height: 6),
            Container(width: 160, height: 11, color: AppColors.opacity10White),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: 포맷 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/skeletons/profile_screen_skeleton.dart
```

---

### Task 2: `ProfileExchangeSection`에 `onLoaded` 콜백 추가

**Files:**
- Modify: `lib/widgets/profile/profile_exchange_section.dart`

- [ ] **Step 1: `onLoaded` prop 추가**

`ProfileExchangeSection` StatefulWidget에 `onLoaded` 필드를 추가한다.

```dart
class ProfileExchangeSection extends StatefulWidget {
  final String? memberId;
  final VoidCallback? onLoaded;  // 추가

  const ProfileExchangeSection({super.key, this.memberId, this.onLoaded});  // 수정

  @override
  State<ProfileExchangeSection> createState() => _ProfileExchangeSectionState();
}
```

- [ ] **Step 2: `_loadMyItems()`에 콜백 호출 추가**

`_ProfileExchangeSectionState`에 `_calledOnLoaded` 플래그를 추가해 중복 호출을 방지하고, 모든 완료 경로에서 단 한 번만 `onLoaded`를 호출한다.

기존 `_loadMyItems()` 전체를 아래로 교체한다:

```dart
bool _calledOnLoaded = false;

void _notifyLoaded() {
  if (_calledOnLoaded) return;
  _calledOnLoaded = true;
  widget.onLoaded?.call();
}

/// 내 교환 물건 로드
Future<void> _loadMyItems() async {
  try {
    if (widget.memberId != null) {
      // TODO: 타인 교환 물건 조회 API 개발 후 구현
      if (mounted) setState(() => _isLoading = false);
      _notifyLoaded();
      return;
    }
    final (availableRes, exchangedRes) = await (
      ItemApi().getMyItems(ItemRequest(itemStatus: ItemStatus.available.serverName, pageNumber: 0, pageSize: 20)),
      ItemApi().getMyItems(ItemRequest(itemStatus: ItemStatus.exchanged.serverName, pageNumber: 0, pageSize: 20)),
    ).wait;

    final items = <Item>[...availableRes.itemPage?.content ?? [], ...exchangedRes.itemPage?.content ?? []];
    await Future.wait(items.map((item) => item.resolveAndCacheAddress()));
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint('내 교환 물건 로드 실패: $e');
    if (mounted) setState(() => _isLoading = false);
  } finally {
    _notifyLoaded();
  }
}
```

- [ ] **Step 3: 포맷 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/profile/profile_exchange_section.dart
```

---

### Task 3: `ProfileReviewSection`에 `onLoaded` 콜백 추가

**Files:**
- Modify: `lib/widgets/profile/profile_review_section.dart`

- [ ] **Step 1: `onLoaded` prop 추가**

```dart
class ProfileReviewSection extends StatefulWidget {
  final String? memberId;
  final VoidCallback? onLoaded;  // 추가

  const ProfileReviewSection({super.key, this.memberId, this.onLoaded});  // 수정

  @override
  State<ProfileReviewSection> createState() => _ProfileReviewSectionState();
}
```

- [ ] **Step 2: `_loadReviews()` finally 블록에 콜백 추가**

기존 `finally` 블록에 `onLoaded` 호출 한 줄을 추가한다:

```dart
} finally {
  if (mounted) setState(() => _isLoading = false);
  widget.onLoaded?.call();  // 추가
}
```

- [ ] **Step 3: 포맷 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/profile/profile_review_section.dart
```

---

### Task 4: `MemberProfileScreen` — 로딩 조율 + 스켈레톤 연결

**Files:**
- Modify: `lib/screens/profile/member_profile_screen.dart`

현재 파일 상태 참고:
- `_isLoading` — 프로필 API 로딩 여부 (기존)
- `_hasError` — 에러 분기 (기존)
- `ProfileExchangeSection`, `ProfileReviewSection` — 현재 콜백 없음

- [ ] **Step 1: import 추가**

파일 상단 import 목록에 추가한다:

```dart
import 'package:romrom_fe/widgets/skeletons/profile_screen_skeleton.dart';
```

- [ ] **Step 2: 상태 필드 추가**

`_MemberProfileScreenState` 클래스 필드에 아래 두 줄을 추가한다 (기존 `// 내 프로필 인라인 편집 상태` 블록 아래):

```dart
bool _exchangeLoaded = false;
bool _reviewLoaded = false;
bool get _showContent => !_isLoading && _exchangeLoaded && _reviewLoaded;
```

- [ ] **Step 3: build() body 분기 변경**

`build()` 메서드 내 `PopScope > Scaffold > body` 부분을 아래와 같이 변경한다.

**변경 전:**
```dart
body: SingleChildScrollView(
  child: Padding(
    padding: EdgeInsets.symmetric(horizontal: 16.w),
    child: Wrap(
      runSpacing: 16.h,
      children: [
        ProfileOverviewSection(
          isEditable: _isMyProfile,
          nickname: _nickname,
          imageUrl: _profileUrl,
          location: _location,
          receivedLikes: _totalLikeCount,
          accountStatus: _accountStatus,
          onShowSaveButton: _isMyProfile ? () => setState(() => _showSaveButton = true) : null,
          onUploadFailed: _isMyProfile
              ? () {
                  if (!_isProfileEdited) setState(() => _showSaveButton = false);
                }
              : null,
          onImageUploaded: _isMyProfile
              ? (url) => setState(() {
                    _profileUrl = url;
                    _isProfileEdited = true;
                  })
              : null,
          onNicknameChanged: _isMyProfile
              ? (nickname) => setState(() {
                    _nickname = nickname;
                    _isProfileEdited = true;
                    _showSaveButton = true;
                  })
              : null,
        ),
        if (!_isMyProfile && _isBlockedUser)
          Center(
            child: Text('차단됨', style: CustomTextStyles.p2.copyWith(color: AppColors.isBlockedStatusText)),
          ),
        ProfileExchangeSection(memberId: _isMyProfile ? null : widget.memberId),
        ProfileReviewSection(memberId: _isMyProfile ? null : widget.memberId),
      ],
    ),
  ),
),
```

**변경 후:**
```dart
body: _showContent ? _buildProfileContent() : const ProfileScreenSkeleton(),
```

- [ ] **Step 4: `_buildProfileContent()` 메서드 추가**

클래스 내 어디든 (예: `_buildProfileMenu()` 위) 아래 메서드를 추가한다:

```dart
Widget _buildProfileContent() {
  return SingleChildScrollView(
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        runSpacing: 16.h,
        children: [
          ProfileOverviewSection(
            isEditable: _isMyProfile,
            nickname: _nickname,
            imageUrl: _profileUrl,
            location: _location,
            receivedLikes: _totalLikeCount,
            accountStatus: _accountStatus,
            onShowSaveButton: _isMyProfile ? () => setState(() => _showSaveButton = true) : null,
            onUploadFailed: _isMyProfile
                ? () {
                    if (!_isProfileEdited) setState(() => _showSaveButton = false);
                  }
                : null,
            onImageUploaded: _isMyProfile
                ? (url) => setState(() {
                      _profileUrl = url;
                      _isProfileEdited = true;
                    })
                : null,
            onNicknameChanged: _isMyProfile
                ? (nickname) => setState(() {
                      _nickname = nickname;
                      _isProfileEdited = true;
                      _showSaveButton = true;
                    })
                : null,
          ),
          if (!_isMyProfile && _isBlockedUser)
            Center(
              child: Text('차단됨', style: CustomTextStyles.p2.copyWith(color: AppColors.isBlockedStatusText)),
            ),
          ProfileExchangeSection(
            memberId: _isMyProfile ? null : widget.memberId,
            onLoaded: () => setState(() => _exchangeLoaded = true),
          ),
          ProfileReviewSection(
            memberId: _isMyProfile ? null : widget.memberId,
            onLoaded: () => setState(() => _reviewLoaded = true),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 5: 포맷 + 린트 실행**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/profile/member_profile_screen.dart && flutter analyze lib/screens/profile/member_profile_screen.dart lib/widgets/profile/profile_exchange_section.dart lib/widgets/profile/profile_review_section.dart lib/widgets/skeletons/profile_screen_skeleton.dart
```

에러 없으면 완료. 경고가 있으면 수정 후 재실행.

---

## Self-Review

**Spec coverage 확인:**
- [x] `ProfileScreenSkeleton` 신규 생성 — Task 1
- [x] `ProfileExchangeSection.onLoaded` 추가 + `_calledOnLoaded` 중복 방지 — Task 2
- [x] `ProfileReviewSection.onLoaded` 추가 — Task 3
- [x] `_exchangeLoaded` / `_reviewLoaded` / `_showContent` 게이트 — Task 4
- [x] body를 `_showContent ? content : skeleton` 분기 — Task 4
- [x] 에러/삭제계정 분기는 `_hasError`/`_accountStatus` 체크가 `build()` 상단에서 먼저 처리되므로 별도 변경 불필요

**타입 일관성:**
- `onLoaded: VoidCallback?` — Task 2, 3, 4 모두 동일
- `_notifyLoaded()` — Task 2 내부 전용, Task 4와 인터페이스 없음
- `_showContent` getter — Task 4 Step 2에서 정의, Step 3에서 사용

**Placeholder 없음** — 모든 스텝에 실제 코드 포함.
