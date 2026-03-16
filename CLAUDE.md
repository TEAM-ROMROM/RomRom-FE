# RomRom Flutter 프로젝트

Flutter 기반 중고거래 플랫폼. iOS/Android 전용 (웹 불필요).

## 절대 규칙
- 텍스트 스타일: `CustomTextStyles` 사용 (직접 TextStyle 금지)
- 색상: `AppColors` 사용 (직접 Color 코드 금지)
- 화면 이동: `context.navigateTo()` 사용 (MaterialPageRoute 금지)
- 모달/다이얼로그: `CommonModal` 사용 (AlertDialog 직접 사용 금지) → 상세: `.claude/instructions/code-style.md`
- Enum 분리: 모든 enum은 `lib/enums/` 폴더에 개별 파일로 관리
- CLI: 모든 명령어 앞에 `source ~/.zshrc &&` 필수
- Git: 사용자 허락 없이 절대 커밋 금지

## UI 패턴 규칙
- **API 중복 요청 방지**: 버튼/액션에서 API를 호출할 때 `Set<T> _pendingRequests` 패턴으로 진행 중인 요청 추적. 요청 시작 시 Set에 추가, `finally`에서 제거. 이미 Set에 있으면 early return.

- **iPad/대형기기 대응 (필수)**: 디자인 기준은 iPhone (393x852)이지만, iPad에서도 정상 동작해야 함.
  - `SizedBox(height: N.h)` 같은 **고정 높이 컨테이너 안에 여러 위젯을 넣지 말 것** → overflow 발생. 대신 `IntrinsicHeight` 또는 고정 높이 제거
  - 이미지/정사각형 요소는 `height: N.h` 대신 **`height: N.w`** 사용 (너비 기준이 더 안전)
  - 위치 권한 거부 등 실패 케이스에서 **반드시 폴백 처리** (서울시청 좌표 등). `_currentPosition == null`인 채로 로딩 화면 유지 금지
  - `ScreenUtil` 설정: `minTextAdapt: true`, `splitScreenMode: true` 유지 필수
  - **모달/다이얼로그는 고정 픽셀값 사용** (`.w` `.h` 금지). 모달은 화면 크기에 비례하면 iPad에서 너무 커짐. `width: 312`, `height: 44` 같이 고정값 사용

```dart
// ✅ 올바른 예시
final Set<NotificationType> _pendingMuteRequests = {};

Future<void> _onToggle(NotificationType type) async {
  if (_pendingMuteRequests.contains(type)) return; // 중복 클릭 무시
  setState(() => _pendingMuteRequests.add(type));
  try {
    await api.call();
    setState(() { /* 상태 업데이트 */ });
  } finally {
    if (mounted) setState(() => _pendingMuteRequests.remove(type));
  }
}
```

## 모듈별 상세 가이드
| 작업 | 참조 파일 |
|------|----------|
| 코드 스타일 & 예시 | `.claude/instructions/code-style.md` |
| 빌드, 린트, 포매팅 | `.claude/instructions/build-lint.md` |
| 프로젝트 구조 | `.claude/instructions/project-structure.md` |
| Git & 커밋 규칙 | `.claude/instructions/git-rules.md` |
| 코드 수정 후 자동 프로세스 | `.claude/instructions/auto-process.md` |

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
- `lib/widgets/common/common_modal.dart` - 공통 모달 위젯

## Git 커밋 규칙

### ⛔ 절대 자동 커밋 금지 (가장 중요한 규칙)
- **Claude는 절대로, 어떤 상황에서도, 어떤 스킬/워크플로우를 따르더라도 사용자 명시적 허락 없이 `git commit`을 실행하지 않는다**
- **`git add`도 사용자 확인 없이 절대 실행 금지**
- 코드 수정 후 반드시 사용자가 diff를 확인할 수 있도록 대기한다
- 커밋은 사용자가 명시적으로 "커밋해줘"라고 요청했을 때만 수행한다
- 스킬(skill)이 커밋을 지시하더라도 이 규칙이 우선한다
- 서브에이전트(subagent)에게도 커밋하지 말라고 명시적으로 지시한다

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
