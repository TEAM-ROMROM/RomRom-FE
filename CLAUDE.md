# RomRom Flutter 프로젝트 Claude Code 설정

## 프로젝트 개요
Flutter 기반 중고거래 플랫폼 RomRom의 프론트엔드 프로젝트입니다.

## 코드 작성 규칙

### 중요 원칙
- **항상 코드 스타일 가이드라인을 참고**: `@prompts/코드_스타일_가이드라인.md` 파일을 모든 코드 작성 시 참고
- **텍스트 스타일은 항상 CustomTextStyles 사용**: 직접 TextStyle 정의 금지
- **색상은 항상 AppColors 사용**: 직접 Color 코드 사용 금지
- **파일명 규칙**: 위젯 파일명에 불필요한 `_widget` 접미사 사용 금지
- **모바일 전용 프로젝트**: iOS/Android 전용으로 웹 호환성 고려 불필요
- **화면 이동 시 팀 공통 확장 메서드 사용**: iOS 스와이프 제스처 지원을 위해 `context.navigateTo()` 사용 필수
- **Enum은 반드시 별도 파일로 분리**: 모든 enum은 `lib/enums/` 폴더에 개별 파일로 관리 (위젯/모델 파일 내 enum 정의 금지)

### 텍스트 스타일 사용 예시
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

### 색상 사용 예시
```dart
// ❌ 잘못된 예시
color: const Color(0x991D1E27)
color: Colors.black.withAlpha(153)

// ✅ 올바른 예시
color: AppColors.primaryBlack.withValues(alpha: 0.6)
color: AppColors.opacity60White
```

### 플랫폼 및 네비게이션 사용 예시
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

## 개발 시 확인 사항

### 린트 및 타입 체크
코드 작성 후 반드시 Flutter 분석 실행:

** 매우 중요한 CLI 명령어 사용법**:
```bash 
source ~/.zshrc &&
```
를 붙여서 모든 명령어를 실행해야지 작동함

**코드 변경 후 마지막에 꼭 실행**:
```bash
# 1. 코드 포매팅 (line-length 120 기준)
source ~/.zshrc && dart format --line-length=120 .

# 2. 린트 분석
source ~/.zshrc && flutter analyze
```

### 코드 포매팅 규칙
- **line-length**: 120 (팀 표준)
- **포매팅 도구**: `dart format` (Prettier와 동등한 공식 포매터)
- **코드 수정 후 반드시 포맷 적용**: 모든 dart 파일 변경 시 `dart format` 실행 필수
- **CI에서 자동 체크**: PR 시 포맷 미준수 코드는 자동 실패

```bash
# 전체 프로젝트 포맷 적용
source ~/.zshrc && dart format --line-length=120 .

# 특정 파일만 포맷 적용
source ~/.zshrc && dart format --line-length=120 lib/screens/example_screen.dart

# 포맷 체크만 (변경 없이 확인)
source ~/.zshrc && dart format --line-length=120 --set-exit-if-changed .
```

## 프로젝트 구조
- `/lib/enums/` - 모든 enum 정의 (enum은 반드시 이 폴더에 개별 파일로 관리)
- `/lib/models/` - 데이터 모델 및 상수 정의
  - `app_colors.dart` - 모든 색상 상수
  - `app_theme.dart` - 테마 및 텍스트 스타일
- `/lib/widgets/` - 재사용 가능한 위젯
  - `/common/` - 공통 위젯
- `/lib/screens/` - 화면 구성 파일
- `/prompts/` - 개발 가이드라인 문서

## Pre-commit Hook (lefthook)

### lefthook이란?
Git Hook 관리 도구로, 커밋/푸시할 때 자동으로 포맷 체크와 린트 분석을 실행합니다.

### 설치 방법 (1회)

**macOS:**
```bash
brew install lefthook
```

**Windows:**
```bash
# Scoop (권장)
scoop install lefthook

# 또는 Chocolatey
choco install lefthook

# 또는 npm
npm install -g lefthook
```

**프로젝트에서 활성화:**
```bash
cd RomRom-FE
lefthook install
```

### 작동 방식
| 시점 | 자동 실행 | 실패 시 |
|------|----------|---------|
| 커밋 시 | 포맷 체크 | 커밋 차단 |
| 푸시 시 | 린트 분석 | 푸시 차단 |

### 수동 실행 스크립트
```bash
# 포맷 적용
bash tool/format.sh

# 포맷 체크만
bash tool/format_check.sh

# 린트 체크만
bash tool/lint_check.sh

# 전체 체크 (포맷 + 린트)
bash tool/full_check.sh
```

## 주요 참고 파일
- `prompts/코드_스타일_가이드라인.md` - 필수 참고
- `lib/models/app_theme.dart` - 텍스트 스타일 정의
- `lib/models/app_colors.dart` - 색상 상수 정의

## Claude 자동 처리 규칙

### 코드 수정 후 필수 실행 (자동)
모든 코드 수정 작업 완료 후, Claude는 반드시 다음 순서로 실행합니다:

1. **코드 포매팅**
   ```bash
   source ~/.zshrc && dart format --line-length=120 .
   ```

2. **린트 분석**
   ```bash
   source ~/.zshrc && flutter analyze
   ```

3. **에러 발생 시**: 에러 수정 후 1-2번 재실행

### lefthook 통과 보장
- 위 단계를 모두 통과해야 작업 완료로 간주
- `flutter analyze`에서 에러 발생 시 반드시 수정
- 작업 완료 전 lefthook이 통과되는지 확인 필수