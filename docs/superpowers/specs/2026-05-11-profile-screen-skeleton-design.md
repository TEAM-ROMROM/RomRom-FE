# 프로필 화면 전체 스켈레톤 shimmer 설계

**날짜:** 2026-05-11  
**목표:** 프로필 화면(MemberProfileScreen)의 제각각 로딩 UX를 단일 shimmer 스켈레톤 → 한번에 콘텐츠 전환으로 개선

---

## 현재 문제

```
현재 UX:
  스피너 (프로필 로딩) → 프로필 개요 노출
                       → 교환 섹션 스피너 (독립)
                       → 리뷰 섹션 스피너 (독립)
                       → 각자 완료 시 제각각 표시
```

세 곳의 독립적 `_isLoading` 상태 때문에 섹션이 따로따로 나타남.

---

## 목표 UX

```
목표 UX:
  ProfileScreenSkeleton (전체 shimmer)
  → 프로필 + 교환 + 리뷰 모두 완료
  → 전체 콘텐츠 한번에 표시
```

---

## 변경 범위

### 1. 신규: `lib/widgets/skeletons/profile_screen_skeleton.dart`

기존 `ItemDetailSkeleton` 패턴 동일하게 적용:
- `Skeletonizer(enabled: true, effect: ShimmerEffect(baseColor: AppColors.opacity10White, highlightColor: AppColors.opacity30White))`
- `Skeleton.leaf()` 로 개별 블록 표현
- 실제 화면 레이아웃(`horizontal: 16.w`, `runSpacing: 16.h`) 그대로 모방

레이아웃 블록:
```
[Overview 카드]
  ├─ 원형 아바타 (70.w × 70.w)
  ├─ 닉네임 텍스트 블록
  ├─ 위치 행
  └─ 좋아요 행

[교환 물건 카드]
  ├─ 헤더 블록
  └─ 아이템 썸네일 3개 (가로 나열)

[교환 후기 카드]
  ├─ 헤더 블록
  └─ 후기 카드 2개
```

### 2. `lib/widgets/profile/profile_exchange_section.dart`

`onLoaded: VoidCallback?` prop 추가.

```dart
class ProfileExchangeSection extends StatefulWidget {
  final String? memberId;
  final VoidCallback? onLoaded;  // 추가
  ...
}
```

`_loadMyItems()`의 모든 완료 경로(성공/에러/타인 프로필 early return)에서 `onLoaded?.call()` 호출:

```dart
Future<void> _loadMyItems() async {
  try {
    if (widget.memberId != null) {
      if (mounted) setState(() => _isLoading = false);
      widget.onLoaded?.call();  // 추가
      return;
    }
    ...
    if (mounted) setState(() { _items = items; _isLoading = false; });
  } catch (e) {
    if (mounted) setState(() => _isLoading = false);
  } finally {
    widget.onLoaded?.call();  // 추가 (성공/에러 공통)
  }
}
```

> 단, early return 경로에서 `finally`가 실행되므로 중복 호출 방지 필요 → early return 직전에만 호출하고 finally 제거 방식 또는 플래그 사용.  
> 구현 시 `_calledOnLoaded` 플래그로 단 1회만 호출되도록 보장.

### 3. `lib/widgets/profile/profile_review_section.dart`

`onLoaded: VoidCallback?` prop 추가.

`_loadReviews()`는 이미 `finally` 블록을 사용하고 있어 한 줄만 추가:

```dart
} finally {
  if (mounted) setState(() => _isLoading = false);
  widget.onLoaded?.call();  // 추가
}
```

### 4. `lib/screens/profile/member_profile_screen.dart`

**상태 추가:**
```dart
bool _exchangeLoaded = false;
bool _reviewLoaded = false;
bool get _showContent => !_isLoading && _exchangeLoaded && _reviewLoaded;
```

**body 변경:**
```dart
body: _showContent ? _buildContent() : const ProfileScreenSkeleton()
```

**섹션 콜백 연결:**
```dart
ProfileExchangeSection(
  memberId: _isMyProfile ? null : widget.memberId,
  onLoaded: () => setState(() => _exchangeLoaded = true),
),
ProfileReviewSection(
  memberId: _isMyProfile ? null : widget.memberId,
  onLoaded: () => setState(() => _reviewLoaded = true),
),
```

**에러 케이스:**  
`_hasError = true`이면 `_showContent` 게이트와 별개로 에러 UI를 즉시 표시 (기존 분기 유지).  
에러 시에는 섹션이 렌더링되지 않으므로 `_exchangeLoaded`/`_reviewLoaded`가 영원히 false인 문제가 없음.

**삭제 계정 케이스:**  
동일하게 기존 분기 유지 (skeleton 없이 즉시 empty 화면 표시).

---

## 로딩 시퀀스

```
initState
  └─ _loadProfileData() 시작  →  _isLoading = true

_loadProfileData 완료
  └─ _isLoading = false
  └─ _showContent 계산 → 여전히 false (섹션 미완료)
  └─ body: ProfileScreenSkeleton 유지
  └─ _buildContent 렌더링 시작 (Offstage 없이, 직접 조건 분기)
       ├─ ProfileExchangeSection 렌더링 → _loadMyItems() 시작
       └─ ProfileReviewSection 렌더링 → _loadReviews() 시작

섹션 완료 시 onLoaded 호출
  └─ _exchangeLoaded = true, _reviewLoaded = true
  └─ _showContent = true → 콘텐츠 한번에 표시
```

> 섹션은 프로필 로드 완료 후 렌더링 시작(순차). 병렬 로딩 최적화는 현재 스코프 밖.

---

## 제약사항

- `ProfileScreenSkeleton` 내부는 고정 픽셀 값 사용 (`height: N`, width: N) — iPad 규칙 준수 (모달과 동일 방침)
- 기존 섹션 내부 `CommonLoadingIndicator`는 제거하지 않음 (어차피 skeleton 뒤에 가려져 보이지 않음)
- `_hasError`, `deleteAccount` 분기는 skeleton 게이트 우선 적용 없이 기존 로직 유지
