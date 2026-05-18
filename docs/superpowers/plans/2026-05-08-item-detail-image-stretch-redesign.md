# 물품 상세 이미지 Stretch 효과 재설계 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물품 상세 화면에서 아래로 당겼을 때 이미지 하단(인디케이터 라인)을 프로필 경계선에 고정하고 위로만 확장하여 status bar 영역까지 메우도록 재설계한다.

**Architecture:** 기존 `Transform.scale(alignment: Alignment.center)`를 `Alignment.bottomCenter`로 변경하여 하단 고정. max scale을 status bar 높이 기준 동적 계산. 손 떼면 `AnimationController` + `Curves.easeOutCubic` 300ms로 부드럽게 1.0 복귀.

**Tech Stack:** Flutter, Dart, ScrollController, AnimationController, ValueNotifier, Transform.scale, MediaQuery

**Spec:** `docs/superpowers/specs/2026-05-08-item-detail-image-stretch-redesign.md`

**테스트 정책:** Flutter 위젯 테스트로 ScrollController overscroll + Transform.scale alignment 동작을 검증하는 비용이 매우 높고 실기기 동작과 시뮬레이터/테스트 동작이 다름(이슈 댓글에서 이미 확인됨: "젝스쳐가 시뮬레이터에서 제대로 작동을 안해서 테스트빌드 실기기에서 확인이 필요함"). 따라서 자동 테스트 대신 **각 task 후 `dart format` + `flutter analyze`(사용자 환경) + 실기기 TestFlight/APK QA**로 검증한다.

**변경 파일:** `lib/screens/item_detail_description_screen.dart` (단일 파일)

---

## Task 1: AnimationController 및 상태 필드 추가

**목적:** spring 복귀 애니메이션 인프라 도입. 이 단계만으로는 동작 변화 없음. 컴파일만 통과시킴.

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`

- [ ] **Step 1: State 클래스에 `SingleTickerProviderStateMixin` 추가**

`lib/screens/item_detail_description_screen.dart` 80번 라인 클래스 선언 변경:

변경 전:
```dart
class _ItemDetailDescriptionScreenState extends State<ItemDetailDescriptionScreen> {
```

변경 후:
```dart
class _ItemDetailDescriptionScreenState extends State<ItemDetailDescriptionScreen>
    with SingleTickerProviderStateMixin {
```

- [ ] **Step 2: 필드 추가 — AnimationController, _scaleAtRelease, _cachedMaxScale**

기존 88~92번 라인 영역(이미지 stretch 효과 필드 블록) 변경:

변경 전:
```dart
  // 이미지 stretch 효과
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _stretchScaleVN = ValueNotifier<double>(1.0);
  static const double _stretchThreshold = 100.0;
  static const double _maxStretchScale = 0.2;
```

변경 후:
```dart
  // 이미지 stretch 효과
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _stretchScaleVN = ValueNotifier<double>(1.0);
  static const double _stretchThreshold = 100.0;
  static const Duration _returnAnimDuration = Duration(milliseconds: 300);
  late final AnimationController _returnAnim;
  double _scaleAtRelease = 1.0;
  double _cachedMaxScale = 1.0;
```

- [ ] **Step 3: `initState`에 AnimationController 초기화 + listener 등록 추가**

기존 `initState` (107~115번 라인):

변경 전:
```dart
  @override
  void initState() {
    super.initState();
    currentIndexVN = ValueNotifier<int>(widget.currentImageIndex);
    pageController = PageController(initialPage: widget.currentImageIndex);
    isLikedVN = ValueNotifier<bool>(false);
    likeCountVN = ValueNotifier<int>(0);
    _scrollController.addListener(_onScroll);
    _loadItemDetail();
  }
```

변경 후:
```dart
  @override
  void initState() {
    super.initState();
    currentIndexVN = ValueNotifier<int>(widget.currentImageIndex);
    pageController = PageController(initialPage: widget.currentImageIndex);
    isLikedVN = ValueNotifier<bool>(false);
    likeCountVN = ValueNotifier<int>(0);
    _returnAnim = AnimationController(vsync: this, duration: _returnAnimDuration);
    _returnAnim.addListener(_onReturnAnimTick);
    _scrollController.addListener(_onScroll);
    _loadItemDetail();
  }

  void _onReturnAnimTick() {
    final t = Curves.easeOutCubic.transform(_returnAnim.value);
    _stretchScaleVN.value = _scaleAtRelease + (1.0 - _scaleAtRelease) * t;
  }
```

- [ ] **Step 4: `dispose`에 `_returnAnim` 해제 추가**

기존 `dispose` (340~349번 라인):

변경 전:
```dart
  @override
  void dispose() {
    currentIndexVN.dispose();
    pageController.dispose();
    isLikedVN.dispose();
    likeCountVN.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stretchScaleVN.dispose();
    super.dispose();
  }
```

변경 후:
```dart
  @override
  void dispose() {
    currentIndexVN.dispose();
    pageController.dispose();
    isLikedVN.dispose();
    likeCountVN.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _returnAnim.removeListener(_onReturnAnimTick);
    _returnAnim.dispose();
    _stretchScaleVN.dispose();
    super.dispose();
  }
```

- [ ] **Step 5: 포매팅 + 컴파일 검증**

내부망 환경 — `dart pub get` 불가. `dart format`만 실행:
```
dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```
Expected: 포매팅 변경 사항 출력 또는 "no changes" 출력. 에러 없음.

`flutter analyze`는 사용자가 별도 환경에서 수행.

- [ ] **Step 6: Commit**

사용자 승인 후 commit. **사용자 명시 요청 없으면 commit 금지.** `cassiiopeia:commit` skill 사용.

커밋 메시지 예시:
```
최상단에서 아래로 스크롤시 이미지 여백 대신 이미지 살짝 확대하는것으로 UI 개선 : refactor : AnimationController 인프라 도입 https://github.com/TEAM-ROMROM/RomRom-FE/issues/579
```

---

## Task 2: `_cachedMaxScale` 갱신 로직 추가 (`didChangeDependencies`)

**목적:** status bar 높이 기준 max scale을 한 번 캐시. orientation 변경에도 자동 재계산.

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`

- [ ] **Step 1: `didChangeDependencies` 오버라이드 추가**

`initState` 메서드 직후, `_onReturnAnimTick` 다음에 추가:

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

- [ ] **Step 2: 포매팅 검증**

```
dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```
Expected: 포매팅 OK.

- [ ] **Step 3: Commit**

사용자 승인 후 commit. 메시지 예시:
```
최상단에서 아래로 스크롤시 이미지 여백 대신 이미지 살짝 확대하는것으로 UI 개선 : feat : status bar 기준 max scale 동적 계산 https://github.com/TEAM-ROMROM/RomRom-FE/issues/579
```

---

## Task 3: `_onScroll` 로직 재작성 (동적 max scale + 복귀 애니메이션 트리거)

**목적:** 정적 max scale → `_cachedMaxScale` 사용. pixels >= 0 진입 시 spring 애니메이션 시작.

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`

- [ ] **Step 1: `_onScroll` 메서드 전체 교체**

기존 `_onScroll` (327~337번 라인 영역):

변경 전:
```dart
  /// ScrollController 리스너. 음수 overscroll에 비례해 [_stretchScaleVN] 값을 1.0~1.2 사이로 갱신한다.
  /// pixels >= 0일 때는 1.0을 강제해 정상 스크롤 영역에서 효과가 발생하지 않게 한다.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pixels = _scrollController.position.pixels;
    if (pixels >= 0) {
      if (_stretchScaleVN.value != 1.0) _stretchScaleVN.value = 1.0;
      return;
    }
    final overscroll = -pixels;
    final progress = (overscroll / _stretchThreshold).clamp(0.0, 1.0);
    _stretchScaleVN.value = 1.0 + progress * _maxStretchScale;
  }
```

변경 후:
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

- [ ] **Step 2: 포매팅 검증**

```
dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

- [ ] **Step 3: Commit**

사용자 승인 후 commit. 메시지 예시:
```
최상단에서 아래로 스크롤시 이미지 여백 대신 이미지 살짝 확대하는것으로 UI 개선 : feat : spring 복귀 애니메이션 + 동적 scale 적용 https://github.com/TEAM-ROMROM/RomRom-FE/issues/579
```

---

## Task 4: `Transform.scale` alignment 변경 (`center` → `bottomCenter`)

**목적:** 핵심 변경. 이미지 영역 하단 고정, 위로만 확장.

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart`

- [ ] **Step 1: `ValueListenableBuilder<double>` builder 변경**

기존 454~458번 라인 영역:

변경 전:
```dart
                  ValueListenableBuilder<double>(
                    valueListenable: _stretchScaleVN,
                    builder: (_, scale, child) {
                      return Transform.scale(scale: scale, alignment: Alignment.center, child: child);
                    },
```

변경 후:
```dart
                  ValueListenableBuilder<double>(
                    valueListenable: _stretchScaleVN,
                    builder: (_, scale, child) {
                      return Transform.scale(scale: scale, alignment: Alignment.bottomCenter, child: child);
                    },
```

- [ ] **Step 2: 포매팅 검증**

```
dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

- [ ] **Step 3: Commit**

사용자 승인 후 commit. 메시지 예시:
```
최상단에서 아래로 스크롤시 이미지 여백 대신 이미지 살짝 확대하는것으로 UI 개선 : fix : 이미지 alignment를 bottomCenter로 변경하여 하단 고정 https://github.com/TEAM-ROMROM/RomRom-FE/issues/579
```

---

## Task 5: 실기기 QA 빌드 + 검증

**목적:** 실제 동작 확인. spec의 검증 항목 체크.

**Files:** 변경 없음 (검증 단계)

- [ ] **Step 1: PR 코멘트로 빌드 트리거**

GitHub PR(또는 이슈 #579)에 댓글 추가:
```
@suh-lab app build
```

`cassiiopeia:github` skill 사용 (직접 `gh`/`curl` 호출 금지).

- [ ] **Step 2: TestFlight/APK 설치 후 실기기 검증**

다음 항목 모두 확인:

**핵심 동작:**
- [ ] 초기 진입: 이미지 하단 = 인디케이터 라인 = 프로필 경계선
- [ ] 아래로 당김 → 이미지 **상단**만 위로 확장 (하단 고정)
- [ ] 끝까지 당김 → status bar 영역 검은 여백 완전히 사라짐
- [ ] 손 뗌 → 약 300ms 부드럽게 1.0 복귀 (떨림/지진 없음)

**회귀:**
- [ ] 가로 PageView 좌우 스와이프 정상
- [ ] 인디케이터 dot 표시 정상
- [ ] 거래완료 검정 50% 오버레이 + "교환 완료" 배지 함께 stretch
- [ ] 검정 그라데이션 함께 stretch
- [ ] errorWidget(이미지 없음)도 stretch 적용
- [ ] 정상 스크롤(콘텐츠 위로) 시 stretch 발생 안 함
- [ ] 좋아요·공유·메뉴·뒤로가기·지도·채팅/요청 버튼 정상

**디바이스:**
- [ ] iPhone notch 모델 — status bar 영역 메움 확인
- [ ] iPhone 구형 (작은 status bar) — 메움 확인
- [ ] Android 폰 — overscroll + stretch 동작 확인
- [ ] iPad — overflow 없음, 하단 고정 정상

**엣지:**
- [ ] 빠른 연속 pull-down → animation cancel 정상
- [ ] pull-down 도중 위로 다시 스크롤 → 자연스럽게 1.0
- [ ] 화면 회전 시 max scale 재계산 (didChangeDependencies)

- [ ] **Step 3: 문제 발견 시 수정**

검증 항목 실패 시 해당 Task 단계로 돌아가 수정 → 재빌드.

- [ ] **Step 4: 검증 완료 후 PR / 담당자확인 라벨로 이동**

`cassiiopeia:github` skill로 PR 생성 또는 이슈 라벨 변경.

---

## Self-Review

**1. Spec coverage 체크:**

| Spec 요구 | Task |
|---|---|
| `Alignment.center` → `bottomCenter` | Task 4 |
| max scale 동적 계산 (`statusBarHeight / imageH`) | Task 2 (`_computeMaxScale`) + Task 3 (`_cachedMaxScale` 사용) |
| `AnimationController` 300ms easeOutCubic 복귀 | Task 1 (init/dispose) + Task 1 Step 3 (`_onReturnAnimTick`) + Task 3 (트리거) |
| `with SingleTickerProviderStateMixin` | Task 1 Step 1 |
| `_scaleAtRelease` 캐시 | Task 1 Step 2 + Task 3 |
| `didChangeDependencies`에서 `_cachedMaxScale` 갱신 | Task 2 |
| 가로 PageView·좋아요·메뉴 등 무영향 | 검증 = Task 5 |
| 거래완료 오버레이·그라데이션 함께 stretch | Stack 내부 위치 유지로 자동 충족 (코드 변경 없음). 검증 = Task 5 |

→ 모든 spec 요구사항이 task에 매핑됨.

**2. Placeholder scan:** TBD/TODO/"add appropriate" 등 없음. 모든 코드 블록 완전.

**3. Type consistency 체크:**
- `_returnAnim` (AnimationController) — Task 1에서 선언, Task 1 Step 4 (dispose), Task 3 (`_returnAnim.isAnimating`, `_returnAnim.forward`, `_returnAnim.stop()`)에서 사용. 일관됨.
- `_scaleAtRelease` (double) — Task 1에서 선언, Task 3에서 set, Task 1 Step 3 listener에서 read. 일관됨.
- `_cachedMaxScale` (double) — Task 1에서 선언 (default 1.0), Task 2에서 갱신, Task 3에서 read. 일관됨.
- `_computeMaxScale()` — Task 2에서 정의, Task 2에서만 호출. 일관됨.
- `_onReturnAnimTick` — Task 1 Step 3에서 정의 + addListener, Task 1 Step 4에서 removeListener. 일관됨.
- `_stretchScaleVN`·`_scrollController`·`_stretchThreshold` — 기존 필드 유지. 변경 없음.

→ 모든 식별자 일관됨. 추가 수정 불필요.
