# CLAUDE.md Progressive Disclosure 리팩토링 설계

## 배경
- 현재 CLAUDE.md: 193줄, ~5.6KB (모든 세션에 전부 로드됨)
- 문제: 컨텍스트 윈도우 낭비, 확장성 한계, 팀 온보딩 어려움
- 참고: Muratcan Koylan의 "Agent Skills for Context Engineering" Progressive Disclosure 패턴

## 설계 원칙
1. **Progressive Disclosure**: 모든 정보를 한꺼번에 로드하지 않음. 라우터 → 모듈 (최대 2홉)
2. **최소 라우터**: CLAUDE.md는 절대 규칙 + 라우팅 테이블만 유지 (~15줄)
3. **모듈화**: 세부 가이드는 `.claude/instructions/` 디렉토리에 독립 파일로 분리

## 파일 구조

```
CLAUDE.md                              (라우터, ~15줄)
.claude/instructions/
  ├── code-style.md                    (코드 작성 규칙 + 예시)
  ├── build-lint.md                    (빌드, 린트, 포매팅)
  ├── project-structure.md             (프로젝트 구조)
  ├── git-rules.md                     (Git 커밋 규칙 + lefthook)
  └── auto-process.md                  (코드 수정 후 자동 프로세스)
```

## 상세 설계

### CLAUDE.md (라우터)

```markdown
# RomRom Flutter 프로젝트

Flutter 기반 중고거래 플랫폼. iOS/Android 전용 (웹 불필요).

## 절대 규칙
- 텍스트 스타일: `CustomTextStyles` 사용 (직접 TextStyle 금지)
- 색상: `AppColors` 사용 (직접 Color 코드 금지)
- 화면 이동: `context.navigateTo()` 사용 (MaterialPageRoute 금지)
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

### .claude/instructions/code-style.md
현재 CLAUDE.md에서 추출할 내용:
- "코드 작성 규칙 > 중요 원칙" 전체
- "텍스트 스타일 사용 예시" (✅/❌ 코드 블록)
- "색상 사용 예시" (✅/❌ 코드 블록)
- "플랫폼 및 네비게이션 사용 예시" (✅/❌ 코드 블록)
- `prompts/코드_스타일_가이드라인.md` 참조 안내
- 주요 참고 파일: `lib/models/app_theme.dart`, `lib/models/app_colors.dart`

### .claude/instructions/build-lint.md
현재 CLAUDE.md에서 추출할 내용:
- "개발 시 확인 사항 > 린트 및 타입 체크"
- "코드 포매팅 규칙" 전체
- `source ~/.zshrc &&` prefix 설명
- dart format / flutter analyze 명령어
- line-length 120 팀 표준

### .claude/instructions/project-structure.md
현재 CLAUDE.md에서 추출할 내용:
- "프로젝트 구조" 섹션 전체
- "주요 참고 파일" 섹션

### .claude/instructions/git-rules.md
현재 CLAUDE.md에서 추출할 내용:
- "Git 커밋 규칙 > 절대 자동 커밋 금지" 전체
- "Pre-commit Hook (lefthook)" 전체 (설치, 작동 방식, 수동 실행 스크립트)

### .claude/instructions/auto-process.md
현재 CLAUDE.md에서 추출할 내용:
- "Claude 자동 처리 규칙 > 코드 수정 후 필수 실행" 전체
- "lefthook 통과 보장" 전체

## 기대 효과
- CLAUDE.md: 193줄 → ~15줄 (**92% 감소**)
- 매 세션 기본 컨텍스트 로드: ~5.6KB → ~0.8KB
- 필요한 모듈만 on-demand 로드
- 새 모듈 추가 시 라우팅 테이블에 1줄만 추가하면 됨

## 리스크 & 완화
- **Claude가 모듈을 참조하지 않을 수 있음**: 절대 규칙에 핵심만 남겨 기본 동작은 보장
- **2홉 지연**: 모듈 파일 크기가 작으므로 (각 30-50줄) 실질적 지연 미미
