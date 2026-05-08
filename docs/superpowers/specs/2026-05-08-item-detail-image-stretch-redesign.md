# 물품 상세 이미지 Stretch 효과 재설계 (Issue #579)

## 배경

기존 구현은 `Transform.scale(alignment: Alignment.center)`로 이미지 영역을 중심 기준 균등 확대했다. 그 결과 두 가지 문제 발생:

1. 이미지 **하단**이 프로필 영역(인디케이터 라인 아래)을 침범한다.
2. 끝까지 당겨도 이미지 **상단**의 검은 여백(status bar 영역)이 메워지지 않는다.

요구사항: 당근마켓 방식으로 동작해야 한다. 즉, 이미지 하단 라인은 프로필 경계선에 고정되고 위로만 확장되어 status bar 영역까지 메운다.

## 목표

- 이미지 하단(인디케이터 라인) = 프로필 영역 시작점에 **절대 고정**
- 아래로 당기면 이미지 **상단**만 위로 확장
- 끝까지 당겼을 때 이미지 상단 = 화면 상단 0px (status bar 영역까지 메움)
- 손 떼면 부드러운 spring 애니메이션(300ms easeOutCubic)으로 1.0배 복귀

## 비목표

- 위로 스크롤(콘텐츠 위로 올림) 시 이미지 변형: 발생 안 함 (현재 동작 유지)
- 가로 PageView 스와이프, 좋아요, 공유, 메뉴, 지도 등 다른 기능: 변경 없음
- 거래완료 오버레이/그라데이션 별도 처리: 현재 구조(Stack 내부) 유지 → 자동으로 함께 stretch

## 변경 범위

**파일 1개**: `lib/screens/item_detail_description_screen.dart`

## 아키텍처

### 위젯 구조

변경 전:
```
SingleChildScrollView
└── Column
    ├── Transform.scale(alignment: Alignment.center)   ← 양쪽 확장
    │   └── Stack (PageView + 인디케이터 + 그라데이션 + 오버레이)
    └── Padding (프로필/설명/지도)
```

변경 후:
```
SingleChildScrollView
└── Column
    ├── ValueListenableBuilder<double>
    │   └── Transform.scale(alignment: Alignment.bottomCenter)  ← 위로만 확장
    │       └── Stack (PageView + 인디케이터 + 그라데이션 + 오버레이)
    └── Padding (프로필/설명/지도)   ← 절대 안 움직임
```

### 핵심 변경점

| 항목 | 변경 전 | 변경 후 |
|---|---|---|
| `Transform.scale` alignment | `Alignment.center` | `Alignment.bottomCenter` |
| Max scale | `1.0 + 0.2` 고정 (1.2배) | 동적 계산: `1.0 + statusBarHeight / imageH` |
| 복귀 방식 | physics 자체 (즉시 1.0) | `AnimationController` + `Curves.easeOutCubic` 300ms |
| State mixin | `State` | `State with SingleTickerProviderStateMixin` |

### 상태 추가

- `AnimationController _returnAnim` — duration 300ms, vsync: this
- `double _scaleAtRelease` — 손 뗀 시점의 scale 값 (애니메이션 시작점)
- `double _cachedMaxScale` — `didChangeDependencies`에서 갱신

### 데이터 흐름

1. 사용자가 아래로 당김 → ScrollController.position.pixels < 0
2. `_onScroll` 호출 → `_returnAnim` 진행 중이면 stop
3. `overscroll = -pixels`, `progress = (overscroll / threshold).clamp(0, 1)` 계산
4. `_stretchScaleVN.value = 1.0 + progress * (_cachedMaxScale - 1.0)`
5. `Transform.scale(alignment: bottomCenter)` 가 이미지 영역을 위로만 확장
6. 사용자 손 뗌 → BouncingScrollPhysics가 pixels을 0으로 되돌림
7. `_onScroll`에서 `pixels >= 0` 첫 진입 감지 → `_scaleAtRelease` 저장 후 `_returnAnim.forward(from: 0)`
8. 애니메이션 listener: `_stretchScaleVN.value = _scaleAtRelease + (1.0 - _scaleAtRelease) * easeOutCubic(t)`
9. 애니메이션 완료 → scale 1.0

## 세부 구현 명세

### Max scale 계산

```dart
double _computeMaxScale() {
  final topGap = MediaQuery.of(context).padding.top; // status bar 높이
  final imageH = widget.imageSize.height;
  if (imageH <= 0) return 1.0;
  return 1.0 + (topGap / imageH);
}
```

`didChangeDependencies`에서 호출하여 `_cachedMaxScale`에 저장. orientation 변경 시 자동 재계산.

### Threshold

`_stretchThreshold = 100.0` 유지. 100px 당기면 `progress = 1.0`이 되어 `_cachedMaxScale` 도달.

### `_onScroll` 로직

```dart
void _onScroll() {
  if (!_scrollController.hasClients) return;
  final pixels = _scrollController.position.pixels;

  if (pixels >= 0) {
    if (_stretchScaleVN.value > 1.0 && !_returnAnim.isAnimating) {
      _scaleAtRelease = _stretchScaleVN.value;
      _returnAnim.forward(from: 0.0);
    }
    return;
  }

  if (_returnAnim.isAnimating) _returnAnim.stop();

  final overscroll = -pixels;
  final progress = (overscroll / _stretchThreshold).clamp(0.0, 1.0);
  _stretchScaleVN.value = 1.0 + progress * (_cachedMaxScale - 1.0);
}
```

### Animation listener

```dart
_returnAnim.addListener(() {
  final t = Curves.easeOutCubic.transform(_returnAnim.value);
  _stretchScaleVN.value = _scaleAtRelease + (1.0 - _scaleAtRelease) * t;
});
```

### dispose 추가

```dart
_returnAnim.dispose();
```

## 영향 범위

### 변경되는 동작
- 이미지 영역의 alignment·max scale·복귀 애니메이션

### 영향 없는 동작
- 가로 PageView 스와이프, 인디케이터 dot 표시
- 거래완료 검정 50% 오버레이 + "교환 완료" 글라스 배지 (Stack 안에 있어 함께 확장)
- 검정 그라데이션 (Stack 안에 있어 함께 확장)
- 좋아요·공유·메뉴 버튼 (Positioned, Stack 외부)
- 프로필·설명·지도 영역 (Transform 외부)
- 채팅하기/요청하기 floating 버튼

## 검증 항목

### 핵심 동작
- 초기 진입 시 scale 1.0, 이미지 하단 = 인디케이터 라인 = 프로필 경계선
- 아래로 당김 → 이미지 상단만 위로 확장
- 당김 중 이미지 하단 위치 절대 안 움직임 (저지선 보장)
- 끝까지 당김 → status bar 영역 검은 여백 완전 사라짐 (이미지가 화면 최상단까지 도달)
- 손 뗌 → 300ms easeOutCubic으로 부드럽게 1.0 복귀
- 복귀 중 떨림/지진 없음

### 회귀 (기존 기능)
- 가로 PageView 좌우 스와이프 정상
- 인디케이터 dot 표시 정상
- 거래완료 오버레이·"교환 완료" 배지 함께 stretch
- 검정 그라데이션 함께 stretch
- errorWidget도 stretch 적용
- 정상 스크롤(콘텐츠 위로) 시 stretch 발생 안 함
- 페이지 하단 도달 후 추가 당김 → stretch 발생 안 함
- 좋아요·공유·메뉴·뒤로가기·지도·채팅/요청 버튼 정상

### 디바이스 / 엣지
- iOS notch (iPhone 15 Pro Max) — status bar ~47pt 메움
- iOS 구형 (iPhone SE) — status bar ~20pt 메움
- Android — status bar ~24dp 메움
- iPad — overflow 없음, 하단 고정 정상
- 화면 회전 시 `_cachedMaxScale` 재계산 (didChangeDependencies)
- 빠른 연속 pull-down → animation cancel 정상
- pull-down 중 위로 다시 스크롤 → 자연스럽게 1.0

### 성능
- 60fps 유지
- `_returnAnim` dispose 정상
- memory leak 없음
