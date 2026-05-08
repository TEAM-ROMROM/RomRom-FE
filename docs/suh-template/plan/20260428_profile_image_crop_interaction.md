# 🎯 ProfileImageCropScreen 인터랙션 개선 전략

> 작성일: 2026-04-28

---

## 1. 요약

슬라이더 기반 줌을 핀치 제스처로 대체하고, 원형 크롭 오버레이를 코너 핸들 드래그로 크기 조정 가능하게 변경.
오버레이 크기가 작아질수록 이미지가 자동 줌인되어 최종 크롭 결과를 실시간 미리보기.

---

## 2. 배경 및 목적

**문제**: 슬라이더는 직관성이 낮고, 원형 오버레이 크기를 조정할 수 없어 원하는 영역을 선택하기 불편  
**목표**: 손가락 제스처로 줌 + 오버레이 크기 조정을 모두 처리하는 자연스러운 크롭 UX  
**범위**: `profile_image_crop_screen.dart` 파일 단일 수정, 저장 로직(_onConfirm) 오버레이 반지름 기준으로 변경

---

## 3. 요구사항

### P0 (필수)
- 슬라이더 완전 제거
- 초기 오버레이 = 이미지 크기에 맞게 자동 계산 (사진이 원 안에 꽉 차는 최대 크기)
- 코너 핸들 드래그 → 오버레이 크기 조정
- 오버레이 작아지면 이미지 자동 줌인 (비율 연동)
- 이미지 위 두 손가락 핀치 → 이미지 줌
- 오버레이 테두리 근처 두 손가락 핀치 → 오버레이 크기 조정

### P1 (중요)
- 오버레이 최소 크기 제한 (너무 작아지면 안 됨)
- rule of thirds 격자선 표시 (Image #2 참고)
- 오버레이 크기 변경 시 offset 재클램핑 (이미지가 원 밖으로 나가지 않도록)

---

## 4. 상태 설계

### 현재 State
```dart
double _scale = 1.0;       // 이미지 줌 (슬라이더 연동)
Offset _offset = Offset.zero;  // 이미지 패닝
double _cropSize = 0.0;    // 컨테이너 크기 (고정)
```

### 변경 후 State
```dart
double _scale = 1.0;           // 이미지 줌 (핀치 + 오버레이 연동)
double _baseScale = 1.0;       // 핀치 시작 시 기준값
Offset _offset = Offset.zero;  // 이미지 패닝
double _cropSize = 0.0;        // 컨테이너 크기 (고정)
double _overlayRadius = 0.0;   // 크롭 원 반지름 (사용자 조정 가능) ← 신규
double _baseRadius = 0.0;      // 오버레이 조정 시작 시 기준값 ← 신규
```

---

## 5. 초기 오버레이 반지름 계산

이미지가 `cropSize` 너비에 맞춰 표시될 때(scale=1.0), 이미지의 짧은 방향에 원이 꽉 차는 크기로 설정.

```
displayH = cropSize * (imageH / imageW)
initialRadius = min(cropSize, displayH) / 2
```

- **세로 이미지**: `displayH > cropSize` → `initialRadius = cropSize / 2` (가로 너비에 맞춤)
- **가로 이미지**: `displayH < cropSize` → `initialRadius = displayH / 2` (세로 높이에 맞춤)
- **정사각형**: `initialRadius = cropSize / 2`

---

## 6. 제스처 아키텍처

```
GestureDetector (이미지 영역 전체)
├── onScaleStart  → _baseScale = _scale, _baseRadius = _overlayRadius 저장
├── onScaleUpdate →
│   ├── pointerCount == 1  → pan: _offset 업데이트
│   └── pointerCount >= 2  →
│       ├── 두 손가락 평균 위치가 오버레이 경계 근처(radius ± 40px)?
│       │   └── YES → 오버레이 리사이즈: _baseRadius * scale.scale → _overlayRadius
│       │                              + 자동 _scale 연동
│       └── NO  → 이미지 줌: _baseScale * scale.scale → _scale
└── onScaleEnd    → 정리

Stack (오버레이 위)
└── 4개 코너 Handle (GestureDetector.onPanUpdate)
    └── 드래그 델타 → 반지름 변화 계산 → _onRadiusChanged()
```

### 핸들 위치 (4개)
| 핸들 | 위치 | 드래그 방향 → 반지름 변화 |
|------|------|--------------------------|
| TopLeft | (cx - r*0.707, cy - r*0.707) | 중심에서 멀어지면 +r |
| TopRight | (cx + r*0.707, cy - r*0.707) | 중심에서 멀어지면 +r |
| BottomLeft | (cx - r*0.707, cy + r*0.707) | 중심에서 멀어지면 +r |
| BottomRight | (cx + r*0.707, cy + r*0.707) | 중심에서 멀어지면 +r |

---

## 7. 오버레이 ↔ 이미지 줌 연동 공식

오버레이 반지름 변경 시 이미지 스케일 자동 조정:

```
새 scale = 현재 scale * (이전 radius / 새 radius)
```

- 반지름 작아짐 → scale 커짐 (이미지 줌인)
- 반지름 커짐 → scale 작아짐 (이미지 줌아웃)

```dart
void _onRadiusChanged(double newRadius) {
  final ratio = _overlayRadius / newRadius;
  final newScale = (_scale * ratio).clamp(_minScale, _maxScale);
  setState(() {
    _overlayRadius = newRadius.clamp(_minOverlayRadius, _cropSize / 2);
    _scale = newScale;
    _offset = _clampOffset(_offset, _cropSize);
  });
}
```

---

## 8. _clampOffset 업데이트

기존: cropSize 기준 클램핑 → **변경: overlayRadius 기준으로**

```dart
Offset _clampOffset(Offset offset, double cropSize) {
  final displayW = cropSize * _scale;
  final displayH = displayW * (imageH / imageW);
  final overlayDiam = _overlayRadius * 2;
  final maxDx = max(0.0, (displayW - overlayDiam) / 2);
  final maxDy = max(0.0, (displayH - overlayDiam) / 2);
  return Offset(offset.dx.clamp(-maxDx, maxDx), offset.dy.clamp(-maxDy, maxDy));
}
```

---

## 9. _onConfirm 크롭 계산 업데이트

기존: `_cropSize` 기준으로 크롭 영역 계산 → **변경: `_overlayRadius * 2` 기준**

```
오버레이 원 중심 = (cropSize/2, cropSize/2)  ← 항상 컨테이너 중앙
overlayLeft = cropSize/2 - _overlayRadius
overlayTop  = cropSize/2 - _overlayRadius

scaleRatio = imageW / displayW
srcLeft = (overlayLeft - imageLeft) * scaleRatio
srcTop  = (overlayTop  - imageTop)  * scaleRatio
srcSize = _overlayRadius * 2 * scaleRatio
```

---

## 10. UI 변경사항

| 항목 | 변경 |
|------|------|
| `_buildZoomSlider()` | 제거 |
| `_CircleOverlayPainter` | `radius`, `cropSize` 파라미터 추가, rule of thirds 격자선 추가 |
| GestureDetector | `onPanUpdate` → `onScaleUpdate`로 교체 (pan + pinch 통합) |
| 코너 핸들 4개 | Stack 위에 추가 (원 테두리 45° 위치에 배치) |

---

## 11. 위험요소 및 대응

| 위험 | 대응 |
|------|------|
| 핀치 vs 핸들 드래그 제스처 충돌 | 핸들은 별도 GestureDetector로 분리 → 충돌 없음 |
| 이미지 로드 완료 전 cropSize 없음 | _loadImage 후 `_cropSize != 0` 확인 후 initialRadius 계산 |
| scale 최솟값 강제 시 오버레이가 이미지보다 커지는 현상 | _minScale 대신 이미지 크기 기준으로 동적 minScale 계산 |
| srcSize 음수/0 발생 | .clamp(0, ...) 처리 유지 |

---

## 12. 성공 기준

- [ ] 슬라이더가 화면에서 완전히 제거됨
- [ ] 초기 진입 시 원형 오버레이가 이미지에 꽉 맞게 표시됨
- [ ] 두 손가락 핀치로 이미지 줌인/줌아웃 동작
- [ ] 코너 핸들 드래그로 오버레이 크기 조정 동작
- [ ] 오버레이 작아지면 이미지 자동 줌인 (연동 확인)
- [ ] 저장 시 오버레이 원 기준으로 정확히 크롭된 이미지 반환
- [ ] 이미지가 오버레이 원 밖으로 벗어나지 않음
