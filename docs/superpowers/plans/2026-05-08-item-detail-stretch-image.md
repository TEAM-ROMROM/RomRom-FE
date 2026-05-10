# 물품 상세 화면 이미지 Stretch 효과 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 물품 상세 화면 최상단에서 아래로 당길 때 검정 여백 없이 이미지가 균등 확대되는 iOS Photos 스타일 효과를 iOS·Android 양쪽에서 동작하게 구현한다.

**Architecture:** `SingleChildScrollView`에 `BouncingScrollPhysics`를 강제 적용하고, `ScrollController.addListener`로 음수 overscroll을 직접 감지한다. `ValueNotifier<double>`에 1.0 ~ 1.2 범위 scale 값을 보관하고 `Transform.scale`로 이미지 영역만 확대한다. layout 재계산을 유발하는 height 변경을 일절 하지 않아 이전 "지진 현상" 재발을 원천 차단한다.

**Tech Stack:** Flutter, Dart, ScrollController, ValueNotifier, BouncingScrollPhysics, Transform.scale

**Spec:** `docs/superpowers/specs/2026-05-08-item-detail-stretch-image-design.md`
**Issue:** [#579](https://github.com/TEAM-ROMROM/RomRom-FE/issues/579)
**Branch:** `20260507_#579_최상단에서_아래로_스크롤시_이미지_여백_대신_이미지_살짝_확대하는것으로_UI_개선`
**Worktree:** `D:\0-suh\project\RomRom-FE-Worktree\20260507_579_최상단에서_아래로_스크롤시_이미지_여백_대신_이미지_살짝_확대하는것으로_UI_개선`

---

## 환경 제약 (반드시 숙지)

- 내부망 환경 — `flutter pub get` / `flutter analyze` / `flutter build` / `flutter test` 등 외부 연결 명령 실행 금지 (CLAUDE.md 규칙)
- 코드 수정 후에는 **`dart format --line-length=120 .`** 만 실행
- 린트/빌드/테스트는 사용자가 별도 환경에서 직접 수행
- 자동 위젯 테스트 작성 금지 (이번 변경 범위 대비 과도)
- 실기기 검증은 사용자가 본인 환경에서 진행. 본 계획은 코드 작성·포매팅까지만 책임

## File Structure

| 파일 | 역할 | 변경 종류 |
|------|------|----------|
| `lib/screens/item_detail_description_screen.dart` | 물품 상세 화면. stretch 효과 추가 대상 | 수정 |

신규 파일 없음. enum/모델/위젯 분리 없음. 단일 파일 내 인라인으로 처리한다 (파일 크기 1095 lines, 위젯 트리 단순 유지를 위해 별도 추출 안 함).

---

## Task 1: 필드 및 상수 추가

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart` (`_ItemDetailDescriptionScreenState` 클래스 필드 영역, 80-99 라인 부근)

이 task에서 stretch 효과에 필요한 `ScrollController`, `ValueNotifier<double>`, 상수 두 개를 클래스 필드로 추가한다.

- [ ] **Step 1: 클래스 필드에 stretch 관련 멤버 추가**

대상 파일을 열고 80번 라인 부근의 `_ItemDetailDescriptionScreenState` 클래스 필드 블록을 찾는다. 기존 필드는 다음과 같다:

```dart
class _ItemDetailDescriptionScreenState extends State<ItemDetailDescriptionScreen> {
  late PageController pageController;
  late final ValueNotifier<int> currentIndexVN;
  late final ValueNotifier<bool> isLikedVN;
  late final ValueNotifier<int> likeCountVN;
  bool _likeInFlight = false;
  final GlobalKey _shareButtonKey = GlobalKey();

  bool deleteModalShown = false; // 삭제/존재하지 않는 사용자 모달 중복 방지 플래그
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
```

`final GlobalKey _shareButtonKey = GlobalKey();` 다음 줄에 다음 4개 멤버를 추가한다:

```dart
  final GlobalKey _shareButtonKey = GlobalKey();

  // 이미지 stretch 효과
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _stretchScaleVN = ValueNotifier<double>(1.0);
  static const double _stretchThreshold = 100.0;
  static const double _maxStretchScale = 0.2;
```

- [ ] **Step 2: 포매팅 적용**

```bash
cd "D:/0-suh/project/RomRom-FE-Worktree/20260507_579_최상단에서_아래로_스크롤시_이미지_여백_대신_이미지_살짝_확대하는것으로_UI_개선"
source ~/.zshrc && dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

Expected: `Formatted X file(s)` 또는 `Unchanged X file(s)` 출력. 에러 없음.

- [ ] **Step 3: 변경 확인 (커밋 X)**

`git diff lib/screens/item_detail_description_screen.dart`로 4줄 추가만 있는지 확인. 사용자 명시적 요청 전까지 절대 commit/add 금지 (CLAUDE.md 규칙).

---

## Task 2: `_onScroll` 콜백 메서드 추가

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart` (메서드 추가 위치: `dispose` 메서드 바로 위, 318 라인 부근)

이 task에서 scroll position을 읽고 scale 값을 계산하는 `_onScroll` 메서드를 추가한다. 진동 회피를 위해 `pixels >= 0`일 때는 scale 1.0을 강제한다.

- [ ] **Step 1: `_onScroll` 메서드 정의**

`@override void dispose() {` 직전에 다음 메서드를 추가한다.

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

  @override
  void dispose() {
```

- [ ] **Step 2: 포매팅 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

Expected: `Formatted` 또는 `Unchanged`. 에러 없음.

- [ ] **Step 3: 변경 확인**

`git diff`로 메서드 1개(약 12줄)만 추가됐는지 확인. 다른 라인 변경 없어야 함.

---

## Task 3: `initState` / `dispose` 라이프사이클 처리

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart` (`initState` 100-108 라인, `dispose` 318-325 라인)

이 task에서 `_scrollController`에 리스너 등록 / 해제 / dispose를 추가한다.

- [ ] **Step 1: `initState`에 리스너 등록**

기존 `initState`:

```dart
  @override
  void initState() {
    super.initState();
    currentIndexVN = ValueNotifier<int>(widget.currentImageIndex);
    pageController = PageController(initialPage: widget.currentImageIndex);
    isLikedVN = ValueNotifier<bool>(false);
    likeCountVN = ValueNotifier<int>(0);
    _loadItemDetail();
  }
```

`_loadItemDetail();` 직전에 한 줄 추가:

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

- [ ] **Step 2: `dispose`에서 리스너 해제 및 dispose 호출**

기존 `dispose`:

```dart
  @override
  void dispose() {
    currentIndexVN.dispose();
    pageController.dispose();
    isLikedVN.dispose();
    likeCountVN.dispose();
    super.dispose();
  }
```

`super.dispose()` 직전에 3줄 추가:

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

- [ ] **Step 3: 포매팅 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

Expected: `Formatted` 또는 `Unchanged`. 에러 없음.

- [ ] **Step 4: 변경 확인**

`git diff`로 4줄 추가만 있는지 확인.

---

## Task 4: `SingleChildScrollView`에 controller·physics 부착

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart` (424 라인 `SingleChildScrollView`)

이 task에서 `SingleChildScrollView`에 `controller`와 `physics`를 부착한다. Android에서도 bouncing 동작을 보장한다.

- [ ] **Step 1: `SingleChildScrollView`에 두 인자 추가**

기존 코드 (424 라인):

```dart
            // 전체 화면 콘텐츠
            SingleChildScrollView(
              child: Column(
```

다음과 같이 수정한다:

```dart
            // 전체 화면 콘텐츠
            SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Column(
```

- [ ] **Step 2: 포매팅 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

Expected: `Formatted` 또는 `Unchanged`. 에러 없음.

- [ ] **Step 3: 변경 확인**

`git diff`로 2줄 추가만 있는지 확인.

---

## Task 5: 이미지 영역에 `Transform.scale` 적용

**Files:**
- Modify: `lib/screens/item_detail_description_screen.dart` (이미지 `Stack` 영역, 428-554 라인)

이 task에서 이미지 영역의 최상위 `Stack`을 `ValueListenableBuilder<double>` + `Transform.scale`로 감싼다. 이미지 영역만 확대되며, 하단 description 영역은 영향 없다.

- [ ] **Step 1: 이미지 Stack 영역 확인**

수정 대상 영역 시작 (라인 425-429):

```dart
              child: Column(
                children: [
                  /// 배경 이미지 (가로 스와이프 가능)
                  Stack(
                    children: [
```

수정 대상 영역 끝 (라인 553-555):

```dart
                        ),
                    ],
                  ),
```

(`Stack` 닫힘 직후 `///`주석 `/// 아이템 설명 영역`이 등장하는 지점.)

- [ ] **Step 2: `Stack`을 `ValueListenableBuilder` + `Transform.scale`로 감쌈**

수정 전 (이미지 Stack 시작·끝):

```dart
              child: Column(
                children: [
                  /// 배경 이미지 (가로 스와이프 가능)
                  Stack(
                    children: [
                      // ... 이미지 PageView, 인디케이터, 그라디언트, 거래완료 오버레이 ...
                    ],
                  ),

                  /// 아이템 설명 영역
                  Padding(
```

수정 후:

```dart
              child: Column(
                children: [
                  /// 배경 이미지 (가로 스와이프 가능)
                  ValueListenableBuilder<double>(
                    valueListenable: _stretchScaleVN,
                    builder: (_, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: Stack(
                      children: [
                        // ... 이미지 PageView, 인디케이터, 그라디언트, 거래완료 오버레이 ...
                      ],
                    ),
                  ),

                  /// 아이템 설명 영역
                  Padding(
```

**작업 방법:**

1. 425 라인 `/// 배경 이미지 (가로 스와이프 가능)` 직후의 `Stack(` 시작 부분을 다음과 같이 변경한다:

```dart
                  /// 배경 이미지 (가로 스와이프 가능)
                  ValueListenableBuilder<double>(
                    valueListenable: _stretchScaleVN,
                    builder: (_, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: child,
                      );
                    },
                    child: Stack(
                      children: [
```

2. 해당 `Stack`이 닫히는 지점(553-554 라인 `],` `),` 부분)에서 `Stack`의 닫는 괄호 `)` 뒤에 `ValueListenableBuilder`의 닫는 괄호 `)`를 한 단계 더 추가한다:

수정 전:
```dart
                        ),
                    ],
                  ),

                  /// 아이템 설명 영역
```

수정 후:
```dart
                        ),
                      ],
                    ),
                  ),

                  /// 아이템 설명 영역
```

(들여쓰기가 한 단계 깊어진다. `dart format`이 자동으로 맞춰준다.)

- [ ] **Step 3: 포매팅 적용**

```bash
source ~/.zshrc && dart format --line-length=120 lib/screens/item_detail_description_screen.dart
```

Expected: `Formatted` 출력 (들여쓰기 변경 때문). 에러 없음.

- [ ] **Step 4: 변경 확인**

`git diff lib/screens/item_detail_description_screen.dart`로 다음을 확인:
- `ValueListenableBuilder<double>(` `valueListenable: _stretchScaleVN,` `builder: ...` `child: Stack(...)` 구조 형성됨
- `Stack` 내부 children(PageView, 인디케이터, 그라디언트 등)은 들여쓰기만 한 칸 깊어졌고 코드 변경 없음
- 이미지 Stack 다음 `Padding(/// 아이템 설명 영역)` 영역은 변경 없음
- 닫는 괄호 짝이 맞음 (괄호 검증 — 빌드는 사용자가 수행)

---

## Task 6: 사용자 수동 검증 요청

**Files:** 없음 (코드 변경 X). 사용자 환경 확인 단계.

이 task는 코드 변경이 끝난 시점에 한 번만 수행한다. 사용자에게 다음 검증 항목을 안내하고 결과를 받는다.

- [ ] **Step 1: 사용자에게 검증 안내**

다음 메시지를 사용자에게 전달:

> 코드 변경 완료. worktree에서 직접 다음 검증 부탁드립니다 (내부망 환경상 제가 빌드/테스트 실행 불가):
>
> 1. `flutter pub get` 후 `flutter analyze` — 에러/경고 없는지 확인
> 2. iOS 시뮬레이터/실기기 — 물품 상세 진입 후 최상단에서 pull-down → 이미지 1.0 → 1.2배 균등 확대 + 검정 여백 안 보임
> 3. Android 실기기 — 동일 동작 (bouncing 작동, 확대됨)
> 4. 손 떼면 부드럽게 1.0배 복귀 (지진/떨림 없음)
> 5. PageView 가로 스와이프 정상 동작
> 6. Hero 애니메이션 정상 동작
> 7. 거래완료 상태 진입 시 오버레이도 함께 확대되는지 확인
> 8. iPad에서 overflow 없는지 확인

- [ ] **Step 2: 사용자 피드백 수신 후 분기**

- 정상 동작: Task 7 (선택 — 커밋)로 진행
- 문제 발견: 문제 내용 보고 받아 troubleshoot 후 해당 Task 재실행

---

## Task 7: 커밋 (사용자 명시 요청 시에만 수행)

**Files:** 없음 (git 작업).

CLAUDE.md 규칙: 사용자가 명시적으로 "커밋해줘"라고 요청한 경우에만 commit 실행. 그 전까지 절대 `git add`/`git commit` 금지.

- [ ] **Step 1: 사용자 커밋 요청 대기**

사용자가 명시적 커밋 지시를 내릴 때까지 대기. 자동 진행 금지.

- [ ] **Step 2: 변경 파일 stage**

```bash
cd "D:/0-suh/project/RomRom-FE-Worktree/20260507_579_최상단에서_아래로_스크롤시_이미지_여백_대신_이미지_살짝_확대하는것으로_UI_개선"
git add lib/screens/item_detail_description_screen.dart
git add docs/superpowers/specs/2026-05-08-item-detail-stretch-image-design.md
git add docs/superpowers/plans/2026-05-08-item-detail-stretch-image.md
```

- [ ] **Step 3: 커밋 실행 (issue #579 컨벤션 준수)**

```bash
git commit -m "$(cat <<'EOF'
최상단에서 아래로 스크롤시 이미지 여백 대신 이미지 살짝 확대하는것으로 UI 개선 : feat : ScrollController + Transform.scale로 이미지 stretch 효과 구현 https://github.com/TEAM-ROMROM/RomRom-FE/issues/579
EOF
)"
```

Expected: `[20260507_#579_... <hash>] ...` 형태 커밋 결과 출력.

- [ ] **Step 4: 푸시는 사용자 명시 요청 시에만**

`git push`도 사용자 명시 지시 전까지 절대 실행 금지.

---

## Self-Review

작성된 plan을 spec(`docs/superpowers/specs/2026-05-08-item-detail-stretch-image-design.md`)과 대조하여 누락 점검:

| Spec 요구사항 | 매핑 Task |
|---------------|----------|
| 균등 Scale 1.0 → 1.2 | Task 1 (`_maxStretchScale = 0.2`), Task 5 (`Transform.scale alignment: center`) |
| 100px overscroll에서 최대 도달 | Task 1 (`_stretchThreshold = 100.0`) |
| BouncingScrollPhysics 자체 스프링 복귀 | Task 4 (`physics: BouncingScrollPhysics()`) |
| Android 동일 동작 | Task 4 (모든 플랫폼 BouncingScrollPhysics 강제) |
| ScrollController.addListener | Task 1 (controller 필드), Task 2 (`_onScroll`), Task 3 (addListener/removeListener) |
| 이미지 영역만 확대 | Task 5 (이미지 Stack만 ValueListenableBuilder로 감쌈) |
| height 변경 금지 (진동 방지) | 모든 Task에서 SizedBox/Container height 미변경 |
| pixels >= 0 분기 | Task 2 |
| 자동 테스트 미작성 | Task 6 (수동 검증으로 대체) |
| 커밋은 사용자 요청 시에만 | Task 7 |

**Placeholder scan**: TBD/TODO/"적절히"/"필요시" 등 패턴 없음. 모든 step에 구체적 코드/명령/예상 결과 포함됨.

**Type 일관성**: 모든 task에서 `_scrollController` (소문자 시작), `_stretchScaleVN` (VN 접미사), `_stretchThreshold`, `_maxStretchScale` (모두 static const) 명칭 통일. `_onScroll` 메서드명 일관 사용.

이슈 없음. 그대로 사용.

---

## Execution Handoff

Plan 작성 완료. 다음 두 가지 실행 옵션 중 선택:

1. **Subagent-Driven (recommended)** — task별로 fresh subagent 디스패치. 각 task 후 review. 빠른 iteration
2. **Inline Execution** — 현재 세션에서 executing-plans skill로 batch 실행. checkpoint마다 review

어느 방식으로 진행?
