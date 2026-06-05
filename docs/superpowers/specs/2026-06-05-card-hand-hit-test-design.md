# 카드 핸드 히트테스트 정밀화 설계

- **이슈**: [#854](https://github.com/TEAM-ROMROM/RomRom-FE/issues/854) — [버그][홈] 카드 핸드에서 본인 물품 선택 시 우측 물품이 선택됨
- **작성일**: 2026-06-05
- **대상 파일**: `lib/widgets/home_tab_card_hand.dart` (단일 파일)

## 1. 문제

홈탭 하단 카드 핸드에서 부채꼴로 겹친 카드 중 하나를 터치하면, 시각적으로 보이는 카드가 아니라 그 **오른쪽에 배치된 카드**가 선택되어 교환 요청의 `giveItemId`로 전달된다.

근본 원인은 `_findCardAtPosition()` (현재 426번 줄)의 두 가지 결함이다.

### 결함 1 — 렌더 순서와 히트테스트 순서 역전

| 구분 | 코드 위치 | 동작 |
|------|-----------|------|
| 렌더링 | `build()` 내 `_cards...reversed.map(...)` (1009번 줄) | index 0이 **마지막에 그려짐 → Stack에서 시각적 최상단** |
| 히트테스트 | `for (int i = _cards.length - 1; i >= 0; i--)` 첫 매치 반환 (429번 줄) | **가장 높은 index** 카드를 반환 |

렌더는 "낮은 index = 위", 히트테스트는 "높은 index 우선"으로 **정반대**다. 겹침 영역에서 사용자 눈에 보이는 최상단 카드는 낮은 index(왼쪽)인데, 히트테스트는 높은 index(오른쪽)를 골라 "우측 물품 선택" 현상이 발생한다.

### 결함 2 — 회전·세로 위치 무시

```dart
if ((localPosition.dx - cardCenterX).abs() < _cardWidth / 2) { ... }
```

`centerX`(수평 거리)만 검사하고 카드의 **회전각(`angle`)·세로 위치(`top`)를 전혀 반영하지 않는다.** 카드는 부채꼴로 회전·tilt 되어 있어 실제 화면상 영역이 단순 수직 띠가 아닌데도, X축 거리만으로 판정하므로 겹침 경계(특히 우측 상단)에서 오판이 발생한다.

## 2. 해결 전략

`_findCardAtPosition()` **단일 메서드의 내부 구현만 교체**한다. 입력(`Offset localPosition`)과 출력(`String? itemId`) 시그니처는 유지하므로 호출처(`_handlePanStart`)와 그 외 모든 코드는 변경 없음. 변경은 이 파일 한 곳에 국한된다.

두 결함을 동시에 해결한다.

1. **순서 정렬**: 루프를 `for (int i = 0; i < _cards.length; i++)`로 바꿔 낮은 index(시각적 최상단)부터 검사하고 첫 매치를 반환.
2. **회전 반영 (역회전 후 사각형 판정)**: 터치점을 각 카드의 로컬 좌표계로 역변환한 뒤 카드 사각형 안에 들어오는지 판정.

### 왜 역회전 방식인가

렌더링이 `Positioned(left, top)` + `Transform(...rotateZ(angle))`로 카드를 배치한다. 동일한 `angle`/위치로 터치점을 역변환하면 **화면에 실제로 그려진 카드 영역과 수학적으로 100% 일치**한다. `_calculateCardTransform()`이 이미 `centerX`, `top`, `angle`을 제공하므로 새 계산식 없이 기존 값을 그대로 재사용한다.

Flutter 네이티브 히트테스트(카드별 GestureDetector) 방식은 가장 정확하지만 드래그/회전 제스처 전체 구조를 재설계해야 해 이번 버그 범위를 크게 초과하므로 채택하지 않는다.

## 3. 구현 상세

### 데이터 흐름

```
localPosition (덱 로컬 좌표)
  → for i = 0 .. length-1            // 낮은 index = 시각적 맨 위부터
      t = _calculateCardTransform(context, i, _cards.length)
      카드중심 = (t.centerX, t.top + _cardHeight / 2)
      Δ = localPosition - 카드중심
      // -angle 만큼 역회전 (카드 로컬 좌표로 변환)
      localX = Δx * cos(-angle) - Δy * sin(-angle)
      localY = Δx * sin(-angle) + Δy * cos(-angle)
      if |localX| < _cardWidth / 2 && |localY| < _cardHeight / 2:
          return _cards[i].itemId   // 첫 매치 = 최상단 카드
  → return null
```

### 핵심 포인트

- **카드 중심 Y**: `_calculateCardTransform`은 `top`(카드 상단)을 반환하므로 중심은 `top + _cardHeight / 2`. 회전은 렌더링에서 `Transform(alignment: Alignment.center)`로 중심 기준이므로 역회전도 중심 기준으로 맞춘다.
- **angle 부호**: 렌더가 `rotateZ(angle)`(시계방향 양수)이므로 역변환은 `-angle`. 표준 2D 회전 행렬 사용.
- **transform의 angle**: `_calculateCardTransform`이 반환하는 `angle`은 `tangent + tilt`로, 실제 렌더에 쓰이는 값과 동일하다. fan/pull/reorder 같은 애니메이션 중간 변형은 히트테스트 대상이 아니다(터치 시작은 정지 상태의 카드 기준).

### 엣지 케이스

| 상황 | 동작 |
|------|------|
| 카드 0개 | 루프 미실행 → `null` 반환 (기존과 동일) |
| 카드 1개 | `tilt = 0`, `angle`만 적용되어 정상 판정 |
| 겹침 없는 빈 영역 터치 | 매치 없음 → `null` |
| 두 카드가 동시에 포함하는 점 | 낮은 index(시각적 최상단) 우선 반환 — 의도된 동작 |

## 4. 테스트 / 검증

- `_calculateCardTransform`이 `BuildContext`/`MediaQuery`에 의존하므로 순수 단위 테스트는 어렵고 위젯 테스트 환경이 필요하다.
- 현실적 검증은 **실기기 QA**: 부채꼴 겹침 영역에서
  - 각 카드의 **우측 상단**(인접 카드와 겹치는 영역)을 터치 → 보이는 카드가 선택되는지
  - 좌/중앙/우 카드 각각 선택 정확도
  - 카드 1장만 있을 때 정상 선택
  - 드래그로 교환 요청 화면 진입 시 전달되는 `giveItemId`가 선택 카드와 일치하는지

## 5. 변경 규모

- `_findCardAtPosition()` 약 15줄 → 약 20줄 (역회전 계산 추가)
- 다른 메서드·호출처·구조 변경 없음
- 신규 의존성 없음 (`dart:math`는 이미 import됨)
