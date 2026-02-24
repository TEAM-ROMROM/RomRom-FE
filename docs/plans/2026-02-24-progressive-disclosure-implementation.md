# CLAUDE.md Progressive Disclosure 리팩토링 구현 계획

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** CLAUDE.md를 Progressive Disclosure 패턴으로 리팩토링하여 193줄 → ~15줄로 축소하고, 세부 가이드를 5개 모듈로 분리

**Architecture:** CLAUDE.md를 라우팅 허브로만 유지하고, 모든 세부 내용을 `.claude/instructions/` 디렉토리의 독립 모듈 파일로 분리. 최대 2홉 (라우터 → 모듈) 구조.

**Tech Stack:** Markdown 파일, Claude Code `.claude/instructions/` 디렉토리

---

## Task 1: instructions 디렉토리 생성

**Files:**
- Create: `.claude/instructions/` (디렉토리)

**Step 1: 디렉토리 생성**

```bash
mkdir -p .claude/instructions
```

**Step 2: 확인**

```bash
ls -la .claude/instructions/
```

Expected: 빈 디렉토리가 존재

---

## Task 2: code-style.md 모듈 생성

**Files:**
- Create: `.claude/instructions/code-style.md`
- Source: `CLAUDE.md` 라인 6-61 (코드 작성 규칙 전체)

**Step 1: 파일 작성**

`.claude/instructions/code-style.md` 내용:

```markdown
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
｀｀｀dart
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
｀｀｀

## 색상 사용 예시
｀｀｀dart
// ❌ 잘못된 예시
color: const Color(0x991D1E27)
color: Colors.black.withAlpha(153)

// ✅ 올바른 예시
color: AppColors.primaryBlack.withValues(alpha: 0.6)
color: AppColors.opacity60White
｀｀｀

## 플랫폼 및 네비게이션 사용 예시
｀｀｀dart
// ✅ 올바른 화면 이동 (iOS 스와이프 제스처 지원)
context.navigateTo(screen: NewScreen());

// ❌ 잘못된 예시 - MaterialPageRoute 직접 사용 시 iOS 제스처 미작동
Navigator.push(context, MaterialPageRoute(builder: (_) => NewScreen()));

// ✅ 모바일 전용이므로 dart:io Platform 사용 가능
if (Platform.isIOS) {
  // iOS 전용 로직
}
｀｀｀

## 주요 참고 파일
- `prompts/코드_스타일_가이드라인.md` - 필수 참고
- `lib/models/app_theme.dart` - 텍스트 스타일 정의
- `lib/models/app_colors.dart` - 색상 상수 정의
```

**Step 2: 확인**

파일이 생성되었는지, 원본 CLAUDE.md 라인 6-61의 내용이 빠짐없이 포함되었는지 확인.

---

## Task 3: build-lint.md 모듈 생성

**Files:**
- Create: `.claude/instructions/build-lint.md`
- Source: `CLAUDE.md` 라인 63-98 (개발 시 확인 사항 + 코드 포매팅 규칙)

**Step 1: 파일 작성**

`.claude/instructions/build-lint.md` 내용:

```markdown
# 빌드, 린트, 포매팅 가이드

## CLI 명령어 필수 prefix
모든 명령어 앞에 반드시 `source ~/.zshrc &&`를 붙여서 실행해야 작동함.

## 코드 변경 후 마지막에 꼭 실행
｀｀｀bash
# 1. 코드 포매팅 (line-length 120 기준)
source ~/.zshrc && dart format --line-length=120 .

# 2. 린트 분석
source ~/.zshrc && flutter analyze
｀｀｀

## 코드 포매팅 규칙
- **line-length**: 120 (팀 표준)
- **포매팅 도구**: `dart format` (Prettier와 동등한 공식 포매터)
- **코드 수정 후 반드시 포맷 적용**: 모든 dart 파일 변경 시 `dart format` 실행 필수
- **CI에서 자동 체크**: PR 시 포맷 미준수 코드는 자동 실패

## 포매팅 명령어 모음
｀｀｀bash
# 전체 프로젝트 포맷 적용
source ~/.zshrc && dart format --line-length=120 .

# 특정 파일만 포맷 적용
source ~/.zshrc && dart format --line-length=120 lib/screens/example_screen.dart

# 포맷 체크만 (변경 없이 확인)
source ~/.zshrc && dart format --line-length=120 --set-exit-if-changed .
｀｀｀
```

**Step 2: 확인**

파일이 생성되었는지, 원본 CLAUDE.md 라인 63-98의 내용이 빠짐없이 포함되었는지 확인.

---

## Task 4: project-structure.md 모듈 생성

**Files:**
- Create: `.claude/instructions/project-structure.md`
- Source: `CLAUDE.md` 라인 100-108 (프로젝트 구조) + 라인 161-164 (주요 참고 파일)

**Step 1: 파일 작성**

`.claude/instructions/project-structure.md` 내용:

```markdown
# 프로젝트 구조

## 디렉토리 구조
- `/lib/enums/` - 모든 enum 정의 (enum은 반드시 이 폴더에 개별 파일로 관리)
- `/lib/models/` - 데이터 모델 및 상수 정의
  - `app_colors.dart` - 모든 색상 상수
  - `app_theme.dart` - 테마 및 텍스트 스타일
- `/lib/widgets/` - 재사용 가능한 위젯
  - `/common/` - 공통 위젯
- `/lib/screens/` - 화면 구성 파일
- `/prompts/` - 개발 가이드라인 문서

## 주요 참고 파일
- `prompts/코드_스타일_가이드라인.md` - 필수 참고
- `lib/models/app_theme.dart` - 텍스트 스타일 정의
- `lib/models/app_colors.dart` - 색상 상수 정의
```

**Step 2: 확인**

파일이 생성되었는지, 원본의 프로젝트 구조 정보가 빠짐없이 포함되었는지 확인.

---

## Task 5: git-rules.md 모듈 생성

**Files:**
- Create: `.claude/instructions/git-rules.md`
- Source: `CLAUDE.md` 라인 110-159 (Pre-commit Hook) + 라인 166-172 (Git 커밋 규칙)

**Step 1: 파일 작성**

`.claude/instructions/git-rules.md` 내용:

```markdown
# Git & 커밋 규칙

## 절대 자동 커밋 금지
- **Claude는 절대로 사용자 허락 없이 `git commit`을 실행하지 않는다**
- 코드 수정 후 반드시 사용자가 diff를 확인할 수 있도록 대기한다
- 커밋은 사용자가 명시적으로 "커밋해줘"라고 요청했을 때만 수행한다
- `git add`도 사용자 확인 후 진행한다

## Pre-commit Hook (lefthook)

### lefthook이란?
Git Hook 관리 도구로, 커밋/푸시할 때 자동으로 포맷 체크와 린트 분석을 실행합니다.

### 설치 방법 (1회)

**macOS:**
｀｀｀bash
brew install lefthook
｀｀｀

**Windows:**
｀｀｀bash
# Scoop (권장)
scoop install lefthook

# 또는 Chocolatey
choco install lefthook

# 또는 npm
npm install -g lefthook
｀｀｀

**프로젝트에서 활성화:**
｀｀｀bash
cd RomRom-FE
lefthook install
｀｀｀

### 작동 방식
| 시점 | 자동 실행 | 실패 시 |
|------|----------|---------|
| 커밋 시 | 포맷 체크 | 커밋 차단 |
| 푸시 시 | 린트 분석 | 푸시 차단 |

### 수동 실행 스크립트
｀｀｀bash
# 포맷 적용
bash tool/format.sh

# 포맷 체크만
bash tool/format_check.sh

# 린트 체크만
bash tool/lint_check.sh

# 전체 체크 (포맷 + 린트)
bash tool/full_check.sh
｀｀｀
```

**Step 2: 확인**

파일이 생성되었는지, 원본의 Git 규칙 및 lefthook 정보가 빠짐없이 포함되었는지 확인.

---

## Task 6: auto-process.md 모듈 생성

**Files:**
- Create: `.claude/instructions/auto-process.md`
- Source: `CLAUDE.md` 라인 174-193 (Claude 자동 처리 규칙)

**Step 1: 파일 작성**

`.claude/instructions/auto-process.md` 내용:

```markdown
# 코드 수정 후 자동 프로세스

## 코드 수정 후 필수 실행 (자동)
모든 코드 수정 작업 완료 후, Claude는 반드시 다음 순서로 실행합니다:

1. **코드 포매팅**
   ｀｀｀bash
   source ~/.zshrc && dart format --line-length=120 .
   ｀｀｀

2. **린트 분석**
   ｀｀｀bash
   source ~/.zshrc && flutter analyze
   ｀｀｀

3. **에러 발생 시**: 에러 수정 후 1-2번 재실행

## lefthook 통과 보장
- 위 단계를 모두 통과해야 작업 완료로 간주
- `flutter analyze`에서 에러 발생 시 반드시 수정
- 작업 완료 전 lefthook이 통과되는지 확인 필수
```

**Step 2: 확인**

파일이 생성되었는지, 원본의 자동 처리 규칙이 빠짐없이 포함되었는지 확인.

---

## Task 7: CLAUDE.md를 라우터로 교체

**Files:**
- Modify: `CLAUDE.md` (전체 교체)

**Step 1: 기존 CLAUDE.md 백업 확인**

Git으로 관리되므로 별도 백업 불필요. `git diff`로 변경 내용 확인 가능.

**Step 2: CLAUDE.md를 라우터 버전으로 교체**

```markdown
# RomRom Flutter 프로젝트

Flutter 기반 중고거래 플랫폼. iOS/Android 전용 (웹 불필요).

## 절대 규칙
- 텍스트 스타일: `CustomTextStyles` 사용 (직접 TextStyle 금지)
- 색상: `AppColors` 사용 (직접 Color 코드 금지)
- 화면 이동: `context.navigateTo()` 사용 (MaterialPageRoute 금지)
- Enum 분리: 모든 enum은 `lib/enums/` 폴더에 개별 파일로 관리
- CLI: 모든 명령어 앞에 `source ~/.zshrc &&` 필수
- Git: 사용자 허락 없이 절대 커밋 금지

## 모듈별 상세 가이드
| 작업 | 참조 파일 |
|------|----------|
| 코드 스타일 & 예시 | `.claude/instructions/code-style.md` |
| 빌드, 린트, 포매팅 | `.claude/instructions/build-lint.md` |
| 프로젝트 구조 | `.claude/instructions/project-structure.md` |
| Git & 커밋 규칙 | `.claude/instructions/git-rules.md` |
| 코드 수정 후 자동 프로세스 | `.claude/instructions/auto-process.md` |
```

**Step 3: 검증**

- `wc -l CLAUDE.md` → 약 18줄 예상
- 라우팅 테이블의 모든 경로가 실제 파일과 일치하는지 확인:
  ```bash
  ls .claude/instructions/
  ```
  Expected: `auto-process.md  build-lint.md  code-style.md  git-rules.md  project-structure.md`

---

## Task 8: 전체 무결성 검증

**Step 1: 원본 정보 누락 확인**

원본 CLAUDE.md의 모든 섹션이 어딘가에 존재하는지 체크리스트:
- [ ] 프로젝트 개요 → CLAUDE.md 라우터
- [ ] 코드 작성 규칙 > 중요 원칙 → code-style.md
- [ ] 텍스트 스타일 예시 → code-style.md
- [ ] 색상 예시 → code-style.md
- [ ] 네비게이션 예시 → code-style.md
- [ ] 린트 및 타입 체크 → build-lint.md
- [ ] 코드 포매팅 규칙 → build-lint.md
- [ ] 프로젝트 구조 → project-structure.md
- [ ] Pre-commit Hook → git-rules.md
- [ ] 주요 참고 파일 → project-structure.md + code-style.md
- [ ] Git 커밋 규칙 → git-rules.md
- [ ] Claude 자동 처리 규칙 → auto-process.md

**Step 2: 파일 크기 비교**

```bash
echo "=== Before ===" && echo "CLAUDE.md: 193 lines" && echo "" && echo "=== After ===" && wc -l CLAUDE.md .claude/instructions/*.md
```

Expected: CLAUDE.md ~18줄, 나머지 모듈 합산 ~175줄
