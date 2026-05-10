# 물품 상세 이미지 Stretch 효과 재설계 v2 (Issue #579)

## 배경

v1 spec(`2026-05-08-item-detail-image-stretch-redesign.md`) 구현 후 실기기 검증에서 "확대가 너무 조금 됨, 검은 영역 남음" 피드백 발생.

**v1 실패 원인:**
1. `_stretchThreshold = 100.0`로 clamp → 100px 이상 당겨도 progress 1.0에서 멈춤
2. max scale = `1.0 + statusBarHeight / imageH ≈ 1.11배` → 위로 약 47pt 확장이 한계 (status bar만 겨우 메움)
3. 사용자 의도 = "**당긴 만큼 비례하여 위로 늘어남**" — clamp/threshold 자체가 잘못된 추상화

**v2 핵심 통찰:**
ScrollController가 overscroll 양을 픽셀로 정확히 알고 있다. clamp/threshold 없이 **당긴 양 = 위로 확장 픽셀**로 1:1 매핑하면 사용자 손가락 움직임을 그대로 따라간다. 끝까지 당기는 한계는 `BouncingScrollPhysics`가 자체적으로 결정 (보통 화면 height의 1/3 수준).

## 목표

- 사용자가 당긴 픽셀 양 = 이미지가 위로 늘어나는 픽셀 양 (1:1)
- 이미지 하단 = 프로필 경계선 절대 고정 (alignment: bottomCenter 유지)
- 손 떼면 300ms `Curves.easeOutCubic` spring 복귀 (v1 그대로)
- 끝까지 당기면 위 검은 영역 + status bar 영역까지 충분히 메움

## 비목표

- max scale 상한선: 두지 않음 (BouncingScrollPhysics가 자연스럽게 한계 지어줌)
- 위로 스크롤(콘텐츠 위로 올림) 시 이미지 변형: 발생 안 함 (현재 동작 유지)
- 가로 PageView, 좋아요, 공유, 메뉴, 지도: 영향 없음
- 거래완료 오버레이/그라데이션: Stack 내부 위치 유지 → 자동으로 함께 stretch

## 변경 범위

**파일 1개**: `lib/screens/item_detail_description_screen.dart`

## 아키텍처

### 위젯 구조 (v1과 동일)
```
SingleChildScrollView
└── Column
    ├── ValueListenableBuilder<double>
    │   └── Transform.scale(alignment: Alignment.bottomCenter)
    │       └── Stack (PageView + 인디케이터 + 그라데이션 + 오버레이)
    └── Padding (프로필/설명/지도)
```

### v1 대비 변경

| 항목 | v1 | v2 |
|---|---|---|
| `_stretchThreshold` | `100.0` 상수 사용 | **제거** |
| `_cachedMaxScale` 필드 | 동적 계산 캐시 | **제거** |
| `_computeMaxScale()` 메서드 | status bar 기준 계산 | **제거** |
| `didChangeDependencies` 오버라이드 | `_cachedMaxScale` 갱신 | **제거** (불필요) |
| `_onScroll` scale 공식 | `1.0 + progress.clamp(0,1) * (_cachedMaxScale - 1.0)` | `1.0 + overscroll / imageH` |
| `Transform.scale` alignment | `bottomCenter` | `bottomCenter` (그대로) |
| spring 복귀 애니메이션 | 300ms easeOutCubic | 그대로 유지 |
| `_returnAnim`, `_scaleAtRelease`, `_returnAnimDuration`, `_onReturnAnimTick` | 존재 | 그대로 유지 |

### 단순화된 `_onScroll` (v2)

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
  final imageH = widget.imageSize.height;
  if (imageH <= 0) return;
  _stretchScaleVN.value = 1.0 + overscroll / imageH;
}
```

### 데이터 흐름 (v2)

1. 사용자가 N픽셀 당김 → `pixels = -N`
2. `_onScroll` → `_returnAnim` 진행 중이면 stop
3. `overscroll = N`, `scale = 1.0 + N / imageH`
4. `Transform.scale(alignment: bottomCenter)`이 위로 정확히 N픽셀 확장 (`imageH * (scale - 1.0) = N`)
5. 손 뗌 → `BouncingScrollPhysics`가 pixels을 0으로 되돌림
6. `_onScroll` `pixels >= 0` 진입 → `_returnAnim.forward(from: 0)` 트리거
7. animation listener: `_stretchScaleVN.value = _scaleAtRelease + (1.0 - _scaleAtRelease) * easeOutCubic(t)`
8. 300ms 후 scale = 1.0

### 왜 1:1 매핑이 정확한가

`Transform.scale(scale: s, alignment: bottomCenter)` 적용 시 위로 확장되는 픽셀:
```
확장량 = imageH * (s - 1.0)
       = imageH * (overscroll / imageH)
       = overscroll
```

즉 사용자가 손가락을 N픽셀 끌면 이미지 상단이 정확히 N픽셀 올라간다.

## 영향 범위

### 변경
- `_onScroll` 메서드 단순화
- 4개 식별자 제거 (`_stretchThreshold`, `_cachedMaxScale`, `_computeMaxScale`, `didChangeDependencies`)

### 영향 없음
- `_returnAnim`, `_scaleAtRelease`, `_onReturnAnimTick`, `_returnAnimDuration`, `with SingleTickerProviderStateMixin`
- `Transform.scale` alignment (bottomCenter)
- 가로 PageView, 인디케이터, 좋아요, 공유, 메뉴, 지도, 채팅/요청 버튼
- 거래완료 오버레이, 검정 그라데이션, errorWidget

## 검증 항목

### 핵심 동작
- 초기 진입 시 scale 1.0
- 아래로 N픽셀 당김 → 이미지 상단이 위로 정확히 N픽셀 확장
- 이미지 하단 위치 절대 안 움직임
- 끝까지 당김 (`BouncingScrollPhysics` 한계) → status bar 위 검은 영역 완전히 사라짐
- 손 뗌 → 300ms easeOutCubic으로 1.0 복귀, 떨림 없음

### 회귀
- 가로 PageView 스와이프, 인디케이터, 거래완료 오버레이/배지/그라데이션, errorWidget, 정상 스크롤 무효, 페이지 하단 도달 후 추가 당김 무효, 좋아요/공유/메뉴/뒤로가기/지도/채팅/요청 모두 정상

### 디바이스
- iPhone notch (15 Pro Max) — 끝까지 당김 시 status bar까지 메움
- iPhone 구형 (SE) — 동일
- Android 폰 — 동일
- iPad — overflow 없음, 하단 고정 정상
- 화면 회전 시 정상 동작 (`MediaQuery` 의존 제거됐으므로 자연스럽게 처리됨)

### 엣지
- 빠른 연속 pull-down → animation cancel 정상
- pull-down 중 위로 다시 스크롤 → 자연스럽게 1.0
- `imageH = 0` 케이스 → 가드 처리

### 성능
- 60fps 유지
- `_returnAnim` dispose 정상
- 메모리 leak 없음
