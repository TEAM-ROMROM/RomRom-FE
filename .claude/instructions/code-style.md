# 코드 스타일 가이드

## 중요 원칙
- **항상 코드 스타일 가이드라인을 참고**: `@prompts/코드_스타일_가이드라인.md` 파일을 모든 코드 작성 시 참고
- **텍스트 스타일은 항상 CustomTextStyles 사용**: 직접 TextStyle 정의 금지
- **색상은 항상 AppColors 사용**: 직접 Color 코드 사용 금지
- **파일명 규칙**: 위젯 파일명에 불필요한 `_widget` 접미사 사용 금지
- **모바일 전용 프로젝트**: iOS/Android 전용으로 웹 호환성 고려 불필요
- **화면 이동 시 팀 공통 확장 메서드 사용**: iOS 스와이프 제스처 지원을 위해 `context.navigateTo()` 사용 필수
- **Enum은 반드시 별도 파일로 분리**: 모든 enum은 `lib/enums/` 폴더에 개별 파일로 관리 (위젯/모델 파일 내 enum 정의 금지)

## 텍스트 스타일 사용 예시
```dart
// ❌ 잘못된 예시
Text(
  'AI',
  style: TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
  ),
)

// ✅ 올바른 예시
Text(
  'AI',
  style: CustomTextStyles.p3.copyWith(
    letterSpacing: -0.5.sp,
    color: AppColors.textColorWhite,
  ),
)
```

## 색상 사용 예시
```dart
// ❌ 잘못된 예시
color: const Color(0x991D1E27)
color: Colors.black.withAlpha(153)

// ✅ 올바른 예시
color: AppColors.primaryBlack.withValues(alpha: 0.6)
color: AppColors.opacity60White
```

## 플랫폼 및 네비게이션 사용 예시
```dart
// ✅ 올바른 화면 이동 (iOS 스와이프 제스처 지원)
context.navigateTo(screen: NewScreen());

// ❌ 잘못된 예시 - MaterialPageRoute 직접 사용 시 iOS 제스처 미작동
Navigator.push(context, MaterialPageRoute(builder: (_) => NewScreen()));

// ✅ 모바일 전용이므로 dart:io Platform 사용 가능
if (Platform.isIOS) {
  // iOS 전용 로직
}
```

## 모달/다이얼로그 사용 규칙
- **반드시 `CommonModal` 사용** (`lib/widgets/common/common_modal.dart`): `AlertDialog`, `showDialog` 직접 사용 금지
- 용도별 팩토리 메서드:
  - `CommonModal.success()` - 성공/안내 모달 (노란색 체크 아이콘, 1버튼)
  - `CommonModal.error()` - 에러 모달 (빨간색 경고 아이콘, 1버튼)
  - `CommonModal.confirm()` - 확인 모달 (빨간색 경고 아이콘, 2버튼: 취소/확인)
  - `CommonModal.showOnceAfterFrame()` - 특정 조건에서 1회만 노출하는 헬퍼
- 삭제 전용: `context.showDeleteDialog()` (내부적으로 `CommonModal.confirm()` 사용, `lib/utils/common_utils.dart`)

```dart
// ❌ 잘못된 예시 - AlertDialog 직접 사용
await showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('제목'),
    actions: [ElevatedButton(onPressed: () {}, child: Text('확인'))],
  ),
);

// ✅ 올바른 예시 - CommonModal 사용
await CommonModal.success(
  context: context,
  message: '처리가 완료되었습니다.',
  onConfirm: () => Navigator.of(context).pop(),
);

// ✅ 확인/취소 2버튼 모달
await CommonModal.confirm(
  context: context,
  message: '정말 삭제하시겠습니까?',
  confirmText: '삭제',
  onCancel: () => Navigator.of(context).pop(false),
  onConfirm: () => Navigator.of(context).pop(true),
);
```

## 주요 참고 파일
- `prompts/코드_스타일_가이드라인.md` - 필수 참고
- `lib/models/app_theme.dart` - 텍스트 스타일 정의
- `lib/models/app_colors.dart` - 색상 상수 정의
