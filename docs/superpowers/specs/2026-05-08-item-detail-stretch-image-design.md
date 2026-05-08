# 물품 상세 화면 이미지 Stretch 효과 설계 (iOS Photos 스타일)

이슈: [#579](https://github.com/TEAM-ROMROM/RomRom-FE/issues/579)
브랜치: `20260507_#579_최상단에서_아래로_스크롤시_이미지_여백_대신_이미지_살짝_확대하는것으로_UI_개선`
작성일: 2026-05-08

## 1. 배경 및 문제

물품 상세 화면(`item_detail_description_screen.dart`)에서 페이지 최상단에서 아래로 당길 때 두 가지 문제가 동시에 발생한다.

- **iOS**: 기본 `BouncingScrollPhysics` 동작으로 bounce는 발생하지만, 이미지가 통째로 아래로 내려가면서 상단에 검정 배경 여백이 노출된다.
- **Android**: 기본 `ClampingScrollPhysics`로 bounce 자체가 발생하지 않아 정적인 화면. pull-down 제스처에 아무 시각 피드백 없음.

이전 시도들(`df2dd53`, `02e13ff`, `ed091a5`)은 `AnimatedContainer(height: 동적)` 또는 parallax 방식으로 접근했으나, height 동적 변경이 layout 재계산을 유발해 bouncing physics와 충돌하면서 "지진 현상"(스크롤 진동 루프)을 발생시킨 이력이 있다.

## 2. 목표

iOS 사진 앱 / 당근마켓 상품 상세와 동일한 패턴 구현:

1. 사용자가 페이지 최상단에서 아래로 당길 때 이미지가 상단 위치를 유지한 채 **균등 확대**된다 (검정 여백 없음).
2. iOS · Android 양쪽에서 동일하게 동작한다.
3. 손을 떼면 부드럽게 원래 크기(1.0배)로 복귀한다.
4. 지진 현상이 재발하지 않는다.

## 3. 합의된 요구사항

| 항목 | 결정 |
|------|------|
| 효과 종류 | 균등 Scale (비율 유지, 중앙 기준 확대) |
| 최대 배율 | 1.0 → 1.2 |
| 확대 도달 거리 | 100px overscroll에서 최대 배율 도달 |
| 복귀 애니메이션 | `BouncingScrollPhysics`의 자체 스프링 복귀를 활용 (별도 `AnimationController` 없음) |
| Android 처리 | `BouncingScrollPhysics` 강제 적용으로 iOS와 동일 동작 |
| Offset 감지 방식 | `ScrollController.addListener`로 `position.pixels` 직접 읽기 |
| 적용 범위 | 이미지 영역(상단 `Stack`) 한정. 하단 description 영역은 영향 없음 |

## 4. 아키텍처

### 4.1 컴포넌트 구성

`_ItemDetailDescriptionScreenState`에 다음 요소를 추가한다.

| 요소 | 역할 |
|------|------|
| `ScrollController _scrollController` | `SingleChildScrollView`에 부착. `position.pixels` 직접 읽기 |
| `ValueNotifier<double> _stretchScaleVN` | 1.0 ~ 1.2 범위 scale 값 보관 |
| `_onScroll()` 콜백 | `addListener`로 등록. pixels < 0일 때만 scale 계산 |
| `_stretchThreshold` 상수 | 100.0 (px). 이 값에서 최대 배율 도달 |
| `_maxStretchScale` 상수 | 0.2. 1.0 + 0.2 = 1.2배 |

### 4.2 데이터 흐름

```
사용자가 최상단에서 아래로 당김 (offset = 0인 상태에서 pull-down)
  → BouncingScrollPhysics → ScrollController.position.pixels = 음수
  → addListener 콜백 발화
  → progress = (-pixels / 100).clamp(0, 1)
  → _stretchScaleVN.value = 1.0 + progress * 0.2
  → ValueListenableBuilder 리빌드 (이미지 영역만)
  → Transform.scale 적용 → 이미지 균등 확대

손을 뗌
  → BouncingScrollPhysics가 자체 스프링으로 pixels을 0으로 복귀
  → 복귀 과정에서 addListener 계속 호출 → scale도 1.0으로 자연 복귀
```

### 4.3 진동 회피 핵심 원리

이전 "지진 현상"의 근본 원인은 `AnimatedContainer(height: 동적변경)` ↔ `BouncingScrollPhysics`의 상호 영향이었다.

1. bounce → scroll offset 변동 → `OverscrollNotification` 발생
2. notification이 height 변경을 트리거 → **layout 재계산** 발생
3. layout 재계산 결과가 다시 scroll position에 영향 → 다시 notification → 무한 진동

이번 설계는 다음 원칙으로 해당 루프를 원천 차단한다.

- `Transform.scale`은 paint 단계만 영향. **layout 재계산 없음**
- `SizedBox` height/width를 동적으로 건드리지 않음
- scroll position이 scale 값에만 영향 → scale이 다시 scroll에 영향을 주지 않음 (단방향)

## 5. 구현 디테일

### 5.1 필드 및 라이프사이클

```dart
class _ItemDetailDescriptionScreenState extends State<...> {
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _stretchScaleVN = ValueNotifier<double>(1.0);
  static const double _stretchThreshold = 100.0;
  static const double _maxStretchScale = 0.2;

  @override
  void initState() {
    super.initState();
    // 기존 초기화 코드 ...
    _scrollController.addListener(_onScroll);
  }

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
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _stretchScaleVN.dispose();
    // 기존 dispose 코드 ...
    super.dispose();
  }
}
```

### 5.2 build() 변경점

`SingleChildScrollView`에 `controller`와 `physics` 부착. 이미지 `Stack` 영역만 `ValueListenableBuilder` + `Transform.scale`로 감싼다.

```dart
SingleChildScrollView(
  controller: _scrollController,           // 신규
  physics: const BouncingScrollPhysics(),  // 신규 (Android 포함)
  child: Column(
    children: [
      ValueListenableBuilder<double>(      // 신규 wrap
        valueListenable: _stretchScaleVN,
        builder: (_, scale, child) {
          return Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: child,
          );
        },
        child: Stack(
          children: [/* 기존 PageView, 인디케이터, 그라디언트 등 */],
        ),
      ),
      Padding(/* 기존 description 영역 - 변경 없음 */),
    ],
  ),
)
```

## 6. 엣지 케이스

| 케이스 | 처리 방식 |
|--------|----------|
| `isLoading == true` (skeleton 표시) | `_scrollController` / VN은 `initState`에서 1회 초기화. skeleton 영역에는 controller 부착 안 됨 → 영향 없음 |
| `hasError == true` | scroll 자체 없는 별도 화면 → 변경 없음 |
| 페이지 하단까지 스크롤 후 추가 당김 (pixels > 0) | `_onScroll`에서 분기 → scale 1.0 유지. 하단 bounce 시 효과 발생 안 함 |
| PageView 가로 스와이프 (이미지 변경) | PageView는 자체 controller 사용. `_scrollController`와 분리 → 영향 없음 |
| `imageUrls.isEmpty` (errorWidget 표시) | `Transform.scale`은 child 종류 무관 → errorWidget도 동일하게 확대 |
| Hero 애니메이션 (홈 → 상세 진입) | 진입 시점 scale=1.0 → Hero 영향 없음 |
| iPad / 태블릿 | `widget.imageSize`는 호출자에서 결정. scale은 비율 적용이라 device size 무관 |

## 7. 영향 범위

- **수정 파일 수**: 1개
- **수정 파일**: `lib/screens/item_detail_description_screen.dart`
- **수정 영역**:
  - `_ItemDetailDescriptionScreenState` 필드 추가 (controller, ValueNotifier, 상수)
  - `initState` / `dispose` 라이프사이클 추가
  - `build()` 내 `SingleChildScrollView`에 controller·physics 부착
  - 이미지 `Stack` 영역을 `ValueListenableBuilder` + `Transform.scale`로 감쌈
- **신규 파일**: 없음
- **API/모델/enum 변경**: 없음

## 8. 검증 계획

내부망 환경상 외부 패키지 다운로드/`flutter analyze`/`flutter build` 실행 불가. 자동 테스트 작성도 본 변경 범위에 비해 과도. 수동 검증으로 충분.

### 8.1 코드 수준 검증

- `dart format --line-length=120 .` 실행 (CLAUDE.md 규칙)
- 사용자 환경에서 별도로 `flutter analyze` 통과 확인

### 8.2 실기기 수동 검증 체크리스트

| 항목 | 기대 동작 |
|------|----------|
| iOS 실기기 - 최상단에서 pull-down | 이미지가 상단 고정한 채 1.0 → 1.2배 균등 확대. 검정 여백 안 보임 |
| iOS 실기기 - 손 뗌 | 부드럽게 1.0배로 복귀. 지진/떨림 없음 |
| Android 실기기 - 최상단에서 pull-down | iOS와 동일하게 확대 (Android에서도 bouncing 작동) |
| Android 실기기 - 손 뗌 | iOS와 동일한 자연스러운 복귀 |
| PageView 가로 스와이프 | 이미지 좌우 전환 정상 동작 |
| Hero 애니메이션 | 홈 → 상세 진입 시 깨짐 없음 |
| 페이지 하단까지 스크롤 후 추가 당김 | 효과 발생 안 함 (확대 X) |
| 거래 완료 상태 (overlay 적용) | 오버레이 함께 1.2배까지 확대됨 |
| iPad | overflow/레이아웃 깨짐 없음 |

## 9. YAGNI 적용 항목 (의도적 제외)

- `AnimationController` / `AnimatedBuilder` — 불필요. physics가 복귀 처리
- `AnimatedContainer(height: 동적)` — 진동 원인. 사용 금지
- Custom `ScrollPhysics` — 표준 `BouncingScrollPhysics`로 충분
- 별도 위젯 파일 분리 — 단일 파일 내 인라인 처리. 위젯 트리 단순 유지
- 자동 위젯 테스트 — 이번 변경에 비해 과도. 실기기 수동 검증으로 충분

## 10. 다음 단계

본 spec 사용자 승인 후 `writing-plans` skill로 구현 계획서(plan) 작성. 이후 별도 세션에서 plan 따라 구현 진행.
