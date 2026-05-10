# 물품 상세 이미지 Stretch 효과 재설계 v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** 당긴 픽셀 양 = 이미지가 위로 늘어나는 픽셀 양 (1:1 매핑). v1의 clamp/threshold/동적 max scale 제거.

**Architecture:** v1 인프라(`_returnAnim`, `_scaleAtRelease`, `_returnAnimDuration`, `_onReturnAnimTick`, `bottomCenter` alignment) 그대로 유지. `_onScroll` 공식만 `1.0 + overscroll / imageH`로 교체. 4개 식별자(`_stretchThreshold`, `_cachedMaxScale`, `_computeMaxScale`, `didChangeDependencies`) 제거.

**Tech Stack:** Flutter, Dart, ScrollController, AnimationController, ValueNotifier

**Spec:** `docs/superpowers/specs/2026-05-08-item-detail-image-stretch-redesign-v2.md`

**테스트 정책:** 위젯 테스트 비용 높고 실기기와 동작 차이 크므로 자동 테스트 작성 안 함. 각 task 후 `dart format` + 실기기 TestFlight/APK QA로 검증.

**변경 파일:** `lib/screens/item_detail_description_screen.dart` (단일 파일)

---

## Task 1: `_onScroll` 단순화 + 불필요 식별자 제거

**목적:** clamp/threshold 제거하고 1:1 매핑 적용. 동시에 v1 잔존물 4개 (`_stretchThreshold`, `_cachedMaxScale`, `_computeMaxScale`, `didChangeDependencies`) 제거.

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`

- [ ] **Step 1: `_stretchThreshold` 필드 제거**

기존 필드 블록(line ~89-95 영역)에서 `_stretchThreshold` 라인 제거.

변경 전:
```dart
  static const double _stretchThreshold = 100.0;
  static const Duration _returnAnimDuration = Duration(milliseconds: 300);
```

변경 후:
```dart
  static const Duration _returnAnimDuration = Duration(milliseconds: 300);
```

- [ ] **Step 2: `_cachedMaxScale` 필드 제거**

같은 필드 블록에서 `_cachedMaxScale` 라인 제거.

변경 전:
```dart
  late final AnimationController _returnAnim;
  double _scaleAtRelease = 1.0;
  double _cachedMaxScale = 1.0;
```

변경 후:
```dart
  late final AnimationController _returnAnim;
  double _scaleAtRelease = 1.0;
```

- [ ] **Step 3: `didChangeDependencies` + `_computeMaxScale` 메서드 둘 다 제거**

다음 블록 전체 삭제:

```dart
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedMaxScale = _computeMaxScale();
  }

  double _computeMaxScale() {
    final topGap = MediaQuery.of(context).padding.top;
    final imageH = widget.imageSize.height;
    if (imageH <= 0) return 1.0;
    return 1.0 + (topGap / imageH);
  }
```

- [ ] **Step 4: `_onScroll` 메서드 본문 변경**

기존 `_onScroll` 메서드 전체를 다음으로 교체:

변경 전:
```dart
  /// ScrollController 리스너. 음수 overscroll에 비례해 [_stretchScaleVN] 값을 갱신하고
  /// pixels >= 0 진입 시 spring 애니메이션으로 1.0 복귀시킨다.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;

    if (pixels >= 0) {
      // 손 뗀 직후: scale > 1.0 이고 애니메이션 진행 중이 아닐 때만 시작
      if (_stretchScaleVN.value > 1.0 && !_returnAnim.isAnimating) {
        _scaleAtRelease = _stretchScaleVN.value;
        _returnAnim.forward(from: 0.0);
      }
      return;
    }

    // 당기는 중: 애니메이션이 돌고 있으면 멈추고 즉시 반영
    if (_returnAnim.isAnimating) _returnAnim.stop();

    final overscroll = -pixels;
    final progress = (overscroll / _stretchThreshold).clamp(0.0, 1.0);
    _stretchScaleVN.value = 1.0 + progress * (_cachedMaxScale - 1.0);
  }
```

변경 후:
```dart
  /// ScrollController 리스너. 당긴 픽셀 양과 이미지가 위로 늘어나는 픽셀 양을 1:1 매핑한다.
  /// pixels >= 0 진입 시 spring 애니메이션으로 1.0 복귀시킨다.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;

    if (pixels >= 0) {
      // 손 뗀 직후: scale > 1.0 이고 애니메이션 진행 중이 아닐 때만 시작
      if (_stretchScaleVN.value > 1.0 && !_returnAnim.isAnimating) {
        _scaleAtRelease = _stretchScaleVN.value;
        _returnAnim.forward(from: 0.0);
      }
      return;
    }

    // 당기는 중: 애니메이션이 돌고 있으면 멈추고 즉시 반영
    if (_returnAnim.isAnimating) _returnAnim.stop();

    final overscroll = -pixels;
    final imageH = widget.imageSize.height;
    if (imageH <= 0) return;
    _stretchScaleVN.value = 1.0 + overscroll / imageH;
  }
```

- [ ] **Step 5: 포매팅 + 잔존물 검증**

```
dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

추가 검증 — 다음 4개 식별자가 파일에 0건 있어야 함:
- `_stretchThreshold`
- `_cachedMaxScale`
- `_computeMaxScale`
- `didChangeDependencies`

`grep` 후 잔존물 있으면 제거.

- [ ] **Step 6: Commit**

사용자 명시 승인 후 commit. 메시지 예시:
```
최상단에서 아래로 스크롤시 이미지 여백 대신 이미지 살짝 확대하는것으로 UI 개선 : fix : 당긴 픽셀과 위로 확장 픽셀 1:1 매핑으로 단순화 https://github.com/TEAM-ROMROM/RomRom-FE/issues/579
```

---

## Task 2: 실기기 QA 빌드 + 검증

**Files:** 변경 없음 (검증 단계)

- [ ] **Step 1: PR comment + 빌드 트리거**
- [ ] **Step 2: TestFlight/APK 실기기 검증** — spec 검증 항목 모두 체크
- [ ] **Step 3: 문제 발견 시 수정 → 재빌드**

---

## Self-Review

**Spec coverage:**
| Spec 요구 | Task |
|---|---|
| `_stretchThreshold` 제거 | Task 1 Step 1 |
| `_cachedMaxScale` 제거 | Task 1 Step 2 |
| `_computeMaxScale`/`didChangeDependencies` 제거 | Task 1 Step 3 |
| `_onScroll`에 1:1 매핑 공식 | Task 1 Step 4 |
| `imageH <= 0` 가드 | Task 1 Step 4 (`if (imageH <= 0) return;`) |
| `Transform.scale(alignment: bottomCenter)` 유지 | (변경 없음 — 그대로) |
| spring 복귀 애니메이션 유지 | (변경 없음 — `_returnAnim` 그대로) |

**Placeholder scan:** TBD/TODO 없음.

**Type consistency:** `_onScroll` 안의 모든 식별자(`_scrollController`, `_stretchScaleVN`, `_returnAnim`, `_scaleAtRelease`, `widget.imageSize.height`)는 v1 task 후 그대로 존재. 추가 정의 불필요.
