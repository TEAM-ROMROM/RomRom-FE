# AI 추천 카드 재정렬 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** AI 분석 버튼 클릭 시 추천 카드 3개가 오프스크린에 있어도 자동으로 덱 앞쪽으로 재정렬되어 glow/float 효과와 함께 한 화면에 모두 보이게 한다.

**Architecture:** `HomeTabCardHand`의 `didUpdateWidget`에서 `highlightedItemIds` 변경을 감지해 재정렬 로직을 트리거한다. orbit 복귀 → 카드 위치 보간 이동 → float 순서로 애니메이션이 연결된다. 재정렬 상태는 다음 AI 분석 전까지 유지된다.

**Tech Stack:** Flutter, AnimationController, AnimatedBuilder, Tween, flutter_screenutil

---

## 배경 지식

### 카드 덱 구조
- `_allCards`: 전체 카드 목록 (최대 10개)
- `_cards`: 현재 화면에 로드된 카드 (초기 7개, 스와이프 시 lazy load)
- `_leftLoadedCount`: `_allCards`에서 `_cards[0]` 앞에 있는 카드 수
- `_rightLoadedCount`: `_cards` 뒤에 남은 로드 안 된 카드 수
- `_orbitAngle`: 덱 회전 각도. 중앙 기준값 = `-math.pi / 2`

### 카드 위치 계산
`_calculateCardTransform(context, index, totalCards)` → `{'left': double, 'top': double, 'angle': double, 'centerX': double, 'zIndex': int}`

### AI 하이라이트 흐름
- `HomeTabScreen._onAiRecommend(List<String> itemIds)` → `setState(() => _aiHighlightedItemIds = itemIds)` → `HomeTabCardHand(highlightedItemIds: _aiHighlightedItemIds)`
- `HomeTabCardHand.didUpdateWidget`에서 변경 감지 → 현재는 float 애니메이션만 실행

---

## Task 1: 재정렬 AnimationController 추가

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart`

**Step 1: 상태 변수 추가**

`_HomeTabCardHandState` 클래스의 기존 상태 변수들 아래에 추가:

```dart
// AI 추천 카드 재정렬 애니메이션
// - _reorderAnimController: 카드가 old 위치 → new 위치로 이동하는 보간 제어
// - _preReorderTransforms: 재정렬 직전 각 카드의 transform 스냅샷 (cardId → transform map)
late AnimationController _reorderAnimController;
late Animation<double> _reorderAnimation;
Map<String, Map<String, dynamic>> _preReorderTransforms = {};
```

**Step 2: `initState()`에 초기화 코드 추가**

`_highlightFloatController` 초기화 블록 바로 뒤에:

```dart
// 재정렬 위치 보간 (300ms, easeInOut)
_reorderAnimController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);
_reorderAnimation = CurvedAnimation(parent: _reorderAnimController, curve: Curves.easeInOut);
```

**Step 3: `dispose()`에 dispose 추가**

`_highlightFloatController.dispose();` 바로 뒤에:

```dart
_reorderAnimController.dispose();
```

**Step 4: 포맷 + 린트 확인**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/home_tab_card_hand.dart
source ~/.zshrc && flutter analyze lib/widgets/home_tab_card_hand.dart
```

Expected: 에러 없음

---

## Task 2: `_reorderForAiHighlight()` 메서드 구현

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart`

**Step 1: `_generateCards()` 메서드 바로 아래에 새 메서드 추가**

```dart
/// AI 추천 카드를 덱 앞쪽으로 재정렬하고 애니메이션을 실행한다.
///
/// 동작 순서:
/// 1. 추천 카드 중 _cards에 없는 것을 _allCards에서 찾아 _cards에 추가
/// 2. 현재 카드 위치 스냅샷 저장 (_preReorderTransforms)
/// 3. _cards를 [추천카드..., 나머지...] 순으로 재구성
/// 4. orbit 중앙 복귀 애니메이션 (400ms)
/// 5. 400ms 후 재정렬 보간 애니메이션 시작 (300ms)
/// 6. 700ms 후 float 애니메이션 시작
void _reorderForAiHighlight(List<String> highlightedItemIds) {
  if (highlightedItemIds.isEmpty || !mounted) return;

  // 1. 추천 카드 중 _cards에 없는 것 강제 로드
  for (final id in highlightedItemIds) {
    if (!_cards.any((c) => c.itemId == id)) {
      final idx = _allCards.indexWhere((c) => c.itemId == id);
      if (idx != -1) {
        _cards = List.from(_cards)..add(_allCards[idx]);
      }
    }
  }

  // 2. 현재 위치 스냅샷 저장 (재정렬 애니메이션의 시작점)
  final snapshot = <String, Map<String, dynamic>>{};
  for (int i = 0; i < _cards.length; i++) {
    final id = _cards[i].itemId;
    if (id != null) {
      snapshot[id] = _calculateCardTransform(context, i, _cards.length);
    }
  }
  setState(() => _preReorderTransforms = snapshot);

  // 3. _cards 재정렬: 추천 카드 먼저, 나머지 뒤
  final highlighted = _cards.where((c) => highlightedItemIds.contains(c.itemId)).toList();
  final others = _cards.where((c) => !highlightedItemIds.contains(c.itemId)).toList();
  final reordered = [...highlighted, ...others];

  // _leftLoadedCount / _rightLoadedCount 재계산
  // 재정렬 후 _cards가 _allCards의 연속 슬라이스가 아니므로 경계값만 갱신
  final allIds = _allCards.map((c) => c.itemId).toList();
  final loadedIds = reordered.map((c) => c.itemId).toSet();
  _rightLoadedCount = _allCards.where((c) => !loadedIds.contains(c.itemId)).length;
  _leftLoadedCount = 0; // 재정렬 후 왼쪽 로드 기준 초기화

  setState(() => _cards = reordered);

  // 4. orbit 중앙 복귀 (400ms)
  _orbitAccumulated = -math.pi / 2;
  _orbitController?.animateTo(
    -math.pi / 2,
    duration: const Duration(milliseconds: 400),
    curve: Curves.easeOut,
  );

  // 5. 400ms 후 재정렬 보간 시작
  Future.delayed(const Duration(milliseconds: 400), () {
    if (!mounted) return;
    _reorderAnimController.forward(from: 0.0);
  });

  // 6. 700ms 후 float 시작
  Future.delayed(const Duration(milliseconds: 700), () {
    if (!mounted) return;
    _highlightFloatController.forward(from: 0.0);
  });
}
```

**Step 2: 포맷 + 린트 확인**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/home_tab_card_hand.dart
source ~/.zshrc && flutter analyze lib/widgets/home_tab_card_hand.dart
```

Expected: 에러 없음

---

## Task 3: `didUpdateWidget`에서 재정렬 로직 연결

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart`

**Step 1: 현재 `didUpdateWidget` 코드 확인**

현재 코드 (`home_tab_card_hand.dart:151~163`):

```dart
@override
void didUpdateWidget(HomeTabCardHand oldWidget) {
  super.didUpdateWidget(oldWidget);

  // highlightedItemIds 가 새로 들어오면 float 애니메이션 처음부터 재실행
  if (widget.highlightedItemIds != oldWidget.highlightedItemIds) {
    if (widget.highlightedItemIds.isNotEmpty) {
      _highlightFloatController.forward(from: 0.0);
    } else {
      // 하이라이트 해제 시 원위치
      _highlightFloatController.reverse();
    }
  }
}
```

**Step 2: `didUpdateWidget` 전체 교체**

기존 float 로직을 `_reorderForAiHighlight`로 대체한다.
float 애니메이션은 이제 `_reorderForAiHighlight` 내부에서 700ms 지연 후 실행되므로 여기서 제거.

```dart
@override
void didUpdateWidget(HomeTabCardHand oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (widget.highlightedItemIds != oldWidget.highlightedItemIds) {
    if (widget.highlightedItemIds.isNotEmpty) {
      // 재정렬 + orbit 복귀 + float 애니메이션 순서로 실행
      _reorderForAiHighlight(widget.highlightedItemIds);
    } else {
      // 하이라이트 해제 시 float 원위치, 재정렬 스냅샷 초기화
      _highlightFloatController.reverse();
      _reorderAnimController.reverse();
      setState(() => _preReorderTransforms = {});
    }
  }
}
```

**Step 3: `initState`의 기존 float 단독 실행 코드 확인 및 제거**

`initState` 하단의 아래 블록을 삭제한다 (재정렬 없이 float만 실행하던 코드):

```dart
// 삭제 대상 (initState 하단):
// highlightedItemIds 가 이미 있으면 즉시 float 실행
if (widget.highlightedItemIds.isNotEmpty) {
  _highlightFloatController.forward();
}
```

대신 아래 코드로 교체한다:

```dart
// highlightedItemIds가 이미 있으면 재정렬 포함 전체 시퀀스 실행
if (widget.highlightedItemIds.isNotEmpty) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _reorderForAiHighlight(widget.highlightedItemIds);
  });
}
```

**Step 4: 포맷 + 린트 확인**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/home_tab_card_hand.dart
source ~/.zshrc && flutter analyze lib/widgets/home_tab_card_hand.dart
```

Expected: 에러 없음

---

## Task 4: `_buildCard`에 재정렬 위치 보간 적용

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart`

**Step 1: `_buildCard`의 `AnimatedBuilder` 내 animation 리스트에 `_reorderAnimation` 추가**

현재 코드 (약 line 319):
```dart
animation: Listenable.merge([_fanAnimation, _pullAnimation, _highlightPulseAnimation, _highlightFloatAnimation]),
```

변경 후:
```dart
animation: Listenable.merge([_fanAnimation, _pullAnimation, _highlightPulseAnimation, _highlightFloatAnimation, _reorderAnimation]),
```

**Step 2: `_buildCard` 내 `left`, `top` 계산 직후에 재정렬 보간 코드 삽입**

현재 코드에서 `left`, `top`, `angle` 계산 후 `double scale = 1.0;` 바로 위에 삽입:

```dart
// ── 재정렬 보간 적용 ─────────────────────────────────────────
// _preReorderTransforms에 이 카드의 old transform이 있으면
// old position → new position 으로 _reorderAnimation.value 에 따라 보간
if (cardId != null && _preReorderTransforms.containsKey(cardId)) {
  final oldTransform = _preReorderTransforms[cardId]!;
  final oldLeft = oldTransform['left'] as double;
  final oldTop = oldTransform['top'] as double;
  final t = _reorderAnimation.value;
  left = lerpDouble(oldLeft, left, t)!;
  top = lerpDouble(oldTop, top, t)!;
}
// ────────────────────────────────────────────────────────────
```

**Step 3: `lerpDouble` import 확인**

파일 상단에 이미 `import 'dart:ui';` 가 있으므로 추가 import 불필요. (lerpDouble은 dart:ui에 포함)

**Step 4: 재정렬 완료 후 `_preReorderTransforms` 정리 (메모리 누수 방지)**

`_reorderAnimController` 초기화 코드 바로 뒤에 리스너 등록:

```dart
_reorderAnimController.addStatusListener((status) {
  if (status == AnimationStatus.completed && mounted) {
    setState(() => _preReorderTransforms = {});
  }
});
```

**Step 5: 포맷 + 린트 확인**

```bash
source ~/.zshrc && dart format --line-length=120 lib/widgets/home_tab_card_hand.dart
source ~/.zshrc && flutter analyze lib/widgets/home_tab_card_hand.dart
```

Expected: 에러 없음

---

## Task 5: 전체 검증 및 엣지케이스 처리

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart`

**Step 1: `_reorderForAiHighlight`에 `cards` 위젯 파라미터가 null이거나 비어 있을 때 조기 리턴 확인**

`_reorderForAiHighlight` 메서드 최상단:

```dart
void _reorderForAiHighlight(List<String> highlightedItemIds) {
  if (highlightedItemIds.isEmpty || !mounted) return;
  if (_allCards.isEmpty) return; // 카드가 없으면 처리 불필요
  // ... 나머지 로직
}
```

**Step 2: `Future.delayed` 콜백에서 `mounted` 재확인 (이미 Task 2에서 처리됨) — 확인만**

`_reorderForAiHighlight` 내 두 개의 `Future.delayed` 블록에 `if (!mounted) return;` 이 있는지 확인.

**Step 3: 핫 리로드로 동작 검증**

Flutter 앱 실행 후:
1. 홈 화면 → AI 분석 버튼 탭
2. 덱이 중앙으로 돌아오는지 확인
3. 추천 카드 3개가 왼쪽으로 이동하는지 확인
4. glow + float 효과가 재정렬 후 나타나는지 확인
5. 피드를 다음으로 넘겨도 재정렬 상태가 유지되는지 확인

**Step 4: 전체 포맷 + 린트 최종 확인**

```bash
source ~/.zshrc && dart format --line-length=120 .
source ~/.zshrc && flutter analyze
```

Expected: 에러 없음, warning 없음
