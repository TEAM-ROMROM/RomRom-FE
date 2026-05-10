# Loading Indicator Unification Design

**Issue:** #761  
**Date:** 2026-04-20  
**Branch:** 20260410_#761_로딩_인디케이터_통일_필요

---

## 문제

현재 `CircularProgressIndicator`가 32개 파일 40+ 군데에서 직접 사용되고 있으며, 색상·크기·strokeWidth가 제각각이다.

- `AppColors.primaryYellow` — 대부분
- `AppColors.textColorBlack` — 1곳 (trade_request_screen)
- `AppColors.opacity40White` — 1곳 (cached_image)
- 색상 없음 (기본값) — 4곳

공통 위젯이 없어 변경 시 전체 파일을 수동으로 수정해야 하고, 시각적 통일감이 없다.

---

## 해결 방향

`AppLoadingIndicator` 공통 위젯을 만들어 모든 `CircularProgressIndicator` 사용처를 교체한다.  
기존 스켈레톤 위젯(ChatRoomListSkeletonSliver 등)은 유지한다.

---

## 위젯 스펙

### 파일 위치
`lib/widgets/common/app_loading_indicator.dart`

### 스타일 enum
```dart
enum AppLoadingStyle { primary, onDark }
```

| 스타일 | 색상 | 용도 |
|--------|------|------|
| `primary` | `AppColors.primaryYellow` | 기본 (밝은 배경) |
| `onDark` | `AppColors.opacity40White` | 어두운 배경 (이미지, 채팅 등) |

### 위젯 파라미터
```dart
class AppLoadingIndicator extends StatelessWidget {
  final AppLoadingStyle style;   // 기본값: AppLoadingStyle.primary
  final double size;             // 기본값: 24.0
  final double strokeWidth;      // 기본값: 2.5
}
```

### 편의 생성자
```dart
const AppLoadingIndicator()            // primary 스타일
const AppLoadingIndicator.onDark()    // onDark 스타일
```

### static 헬퍼
```dart
// Center(child: AppLoadingIndicator()) 반복 제거용
static Widget centered({AppLoadingStyle style = AppLoadingStyle.primary, double size = 24.0})
```

---

## 변환 규칙

| 현재 패턴 | 변환 후 |
|-----------|---------|
| `CircularProgressIndicator(color: AppColors.primaryYellow)` | `AppLoadingIndicator()` |
| `CircularProgressIndicator(color: AppColors.opacity40White)` | `AppLoadingIndicator.onDark()` |
| `CircularProgressIndicator(color: AppColors.textColorBlack)` | `AppLoadingIndicator()` |
| `CircularProgressIndicator()` (색상 없음) | `AppLoadingIndicator()` |
| `Center(child: CircularProgressIndicator(color: AppColors.primaryYellow))` | `AppLoadingIndicator.centered()` |
| `SizedBox(width: N, height: N, child: CircularProgressIndicator(...))` | `AppLoadingIndicator(size: N)` |

### size 오버라이드 필요 목록
- `chat_image_bubble.dart`: 32px, 24px (버블 크기에 따라)
- `chat_location_bubble.dart`: 기본 size (SizedBox 제거)
- `item_card_option_chip.dart`: 기본 size

### textColorBlack → primaryYellow 통일
- `trade_request_screen.dart:404` — 버튼 내부 로딩, primaryYellow로 통일

---

## 제외 대상
- `lib/deprecated/` — 주석 처리된 코드, 변환 불필요
- `lib/widgets/skeletons/` — 스켈레톤은 별도 위젯, 유지
- `lib/widgets/common/completion_button.dart` — 이미 위젯 내부에 캡슐화됨, 유지

---

## 성공 기준
- 모든 `CircularProgressIndicator` 직접 사용이 `AppLoadingIndicator`로 교체됨
- `deprecated/` 및 스켈레톤 제외
- `flutter analyze` 에러 없음
- `dart format` 통과
