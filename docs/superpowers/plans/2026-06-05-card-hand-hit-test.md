# 카드 핸드 히트테스트 정밀화 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 카드 핸드에서 부채꼴로 겹친 카드를 터치할 때, 시각적으로 보이는 최상단 카드가 정확히 선택되도록 `_findCardAtPosition()`을 수정한다.

**Architecture:** `lib/widgets/home_tab_card_hand.dart`의 `_findCardAtPosition()` 단일 메서드 내부만 교체한다. (1) 히트테스트 루프 순서를 렌더 순서(낮은 index = 시각적 최상단)와 일치시키고, (2) 터치점을 각 카드의 회전각만큼 역회전한 뒤 카드 사각형 안에 들어오는지 판정한다. 시그니처·호출처·다른 메서드는 변경하지 않는다.

**Tech Stack:** Flutter / Dart, `dart:math` (이미 import됨, `math` 별칭).

**관련 spec:** `docs/superpowers/specs/2026-06-05-card-hand-hit-test-design.md`

---

## File Structure

- Modify: `lib/widgets/home_tab_card_hand.dart:426-440` — `_findCardAtPosition()` 메서드 본문 교체

테스트 파일은 생성하지 않는다. `_findCardAtPosition`은 `private` 메서드이며 `_calculateCardTransform`이 `BuildContext`/`MediaQuery`에 의존해 순수 단위 테스트가 불가능하다. 검증은 실기기 QA로 한다 (spec 4절 참조). 이 프로젝트에는 위젯 단위 테스트 인프라가 없으므로 신규 테스트 도입은 YAGNI.

---

## Task 1: `_findCardAtPosition()` 역회전 히트테스트로 교체

**Files:**
- Modify: `lib/widgets/home_tab_card_hand.dart:425-440`

- [ ] **Step 1: 기존 메서드 본문을 역회전 판정 로직으로 교체**

`lib/widgets/home_tab_card_hand.dart`의 425~440번 줄(아래 "기존 코드")을 "새 코드"로 정확히 교체한다.

기존 코드:

```dart
  // 좌표에서 카드 찾기
  String? _findCardAtPosition(Offset localPosition) {
    // 왼쪽 카드가 위에 있으므로 (reversed로 렌더링됨)
    // 역순으로 검사하여 위에 있는 카드부터 확인
    for (int i = _cards.length - 1; i >= 0; i--) {
      final transform = _calculateCardTransform(context, i, _cards.length);
      final cardCenterX = transform['centerX'] as double;

      // 카드 영역 체크 (카드 너비의 절반 범위 내)
      if ((localPosition.dx - cardCenterX).abs() < _cardWidth / 2) {
        return _cards[i].itemId;
      }
    }

    return null;
  }
```

새 코드:

```dart
  // 좌표에서 카드 찾기
  // 렌더링은 _cards.reversed로 그려져 index 0이 시각적 최상단(Stack 맨 위)이다.
  // 따라서 index 0부터(=위에 있는 카드부터) 검사해 첫 매치를 반환해야
  // 사용자가 보는 최상단 카드가 선택된다.
  String? _findCardAtPosition(Offset localPosition) {
    for (int i = 0; i < _cards.length; i++) {
      final transform = _calculateCardTransform(context, i, _cards.length);
      final double cardCenterX = transform['centerX'] as double;
      // _calculateCardTransform은 top(카드 상단)을 주므로 중심 Y는 +height/2
      final double cardCenterY = (transform['top'] as double) + _cardHeight / 2;
      // 렌더와 동일한 회전각(tangent + tilt)
      final double angle = transform['angle'] as double;

      // 터치점을 카드 중심 기준 상대 좌표로
      final double dx = localPosition.dx - cardCenterX;
      final double dy = localPosition.dy - cardCenterY;

      // 렌더는 rotateZ(angle)이므로 -angle로 역회전해 카드 로컬 좌표로 변환
      final double cosA = math.cos(-angle);
      final double sinA = math.sin(-angle);
      final double localX = dx * cosA - dy * sinA;
      final double localY = dx * sinA + dy * cosA;

      // 역회전된 좌표가 카드 사각형 안이면 이 카드가 hit (회전·세로 위치 반영)
      if (localX.abs() < _cardWidth / 2 && localY.abs() < _cardHeight / 2) {
        return _cards[i].itemId;
      }
    }

    return null;
  }
```

- [ ] **Step 2: 포맷 적용**

Run: `source ~/.zshrc && dart format --line-length=120 lib/widgets/home_tab_card_hand.dart`
Expected: `1 file(s) ... 0 changed` 또는 `1 changed` (변경 시 정상)

- [ ] **Step 3: 린트 분석 (에러 없음 확인)**

Run: `source ~/.zshrc && flutter analyze lib/widgets/home_tab_card_hand.dart`
Expected: `No issues found!` (해당 파일 관련 error/warning 없음)

- [ ] **Step 4: 커밋하지 않고 대기**

⛔ 자동 커밋 금지 규칙. 사용자가 diff를 확인하고 명시적으로 "커밋해줘"라고 요청할 때까지 `git add`/`git commit`을 실행하지 않는다. 변경 요약만 사용자에게 보고한다.

---

## 실기기 QA 체크리스트 (구현 후 사용자/QA가 수행)

코드로 자동 검증할 수 없으므로 실기기에서 다음을 확인한다 (spec 4절).

- [ ] 부채꼴 겹침 영역에서 각 카드의 **우측 상단**(인접 카드와 겹치는 영역)을 터치 → 보이는(최상단) 카드가 선택되는가
- [ ] 좌 / 중앙 / 우 카드를 각각 선택 → 의도한 카드가 선택되는가
- [ ] 카드 1장만 있을 때 정상 선택되는가
- [ ] 카드를 위로 드래그해 교환 요청 화면 진입 시, 전달되는 `giveItemId`가 선택한 카드와 일치하는가
- [ ] 겹침 없는 빈 영역 터치 시 아무 카드도 선택/드래그되지 않는가

---

## Self-Review 결과

- **Spec coverage:** spec 2절(순서 정렬 + 역회전 판정) → Task 1 Step 1에서 둘 다 구현. spec 3절 데이터 흐름·angle 부호·카드 중심 Y 계산 모두 새 코드에 반영. spec 4절 검증 → QA 체크리스트로 이관. spec 5절 변경 규모(단일 메서드) 준수.
- **Placeholder scan:** 없음. 모든 코드 블록이 실제 교체 코드.
- **Type consistency:** `transform['centerX'|'top'|'angle']`는 모두 `_calculateCardTransform` 반환 맵의 실제 키(spec/원본 코드 확인). `_cardWidth`/`_cardHeight`/`math`는 기존 필드·import. 신규 심볼 도입 없음.
