# CLAUDE.md에 표준 작업 Flow 및 Skill 우회 금지 규칙 추가

## 개요

이슈 기반 작업 시 따라야 할 표준 6 Phase Flow와 Skill 우회 금지 규칙을 RomRom-FE의 `CLAUDE.md`에 명문화했다. Claude가 매번 다르게 판단해 skill을 우회하고 `gh`/`curl`/`git commit` 등을 직접 호출하던 사례를 차단하고, 설계·구현·QA·배포까지 일관된 작업 흐름을 강제한다.

**이슈**: [#836](https://github.com/TEAM-ROMROM/RomRom-FE/issues/836)
**커밋**: `f769acb`
**브랜치**: `main` (사용자 지시로 별도 worktree/브랜치 없이 main에 직접 작업)

## 변경 사항

### 문서
- `CLAUDE.md`: `## 표준 작업 Flow (AgenticFlow)` 섹션 신규 추가 (37줄)
  - Phase 1~6 정의
  - 절대 규칙 — Skill 우회 금지 3개 항목
  - 본 flow 미적용 예외 2개
  - 위치: `## Pre-commit Hook (lefthook)` 다음, `## Git 커밋 규칙` 앞

### 이슈 산출물
- `docs/suh-template/issue/20260508_836_기능추가_AgenticFlow_CLAUDE_md_표준_작업_Flow_및_Skill_우회_금지_규칙_추가.md`: 신규 (65줄)

## 주요 구현 내용

### Phase 정의 (이슈 기반 작업 표준 순서)

| Phase | 단계 | 사용 Skill |
|-------|------|-----------|
| 1 | 이슈 + 워크트리 | `/cassiiopeia:issue` 또는 `/cassiiopeia:init-worktree` |
| 2 | 설계 | `/superpowers:brainstorming` → `/superpowers:writing-plans` |
| 3 | 구현 | `/superpowers:subagent-driven-development` |
| 4 | Commit + PR | `/cassiiopeia:commit` → `/cassiiopeia:github` |
| 5 | 빌드 + QA | `/cassiiopeia:github` (build 댓글) → `/cassiiopeia:testcase` → `/cassiiopeia:github` (testcase 댓글) |
| 6 | 머지 후 배포 | `/cassiiopeia:changelog-deploy` |

### 절대 규칙 — Skill 우회 금지

- **GitHub 작업** (이슈/PR/댓글): `/cassiiopeia:github` 거치기. `gh`/`curl`/`Invoke-RestMethod` 직접 호출 금지
- **Commit**: `/cassiiopeia:commit` 거치기. `git commit` 직접 호출 금지
- **설계/구현**: superpowers 3-skill 체인 거치기. 바로 코드 작성 금지

### 본 flow 미적용 예외

- 단순 typo/1줄 변경 같은 trivial fix는 brainstorming/plan 생략 가능 (단 commit/push/PR/댓글은 skill 거치기)
- 긴급 버그는 worktree 생성 생략 가능

## 주의사항

- 본 변경은 사용자 지시로 별도 worktree 없이 main에 직접 작업했다 (긴급/메타성 변경 예외 적용)
- 푸시 시도에서 `non-fast-forward` 거부 발생 — 원격 main에 v1.10.45 릴리즈 + #717 PR 등 9개 commit 존재. `git pull --rebase origin main` 후 충돌 없으면 재푸시 필요
- 본 commit은 코드 변경 없는 문서 변경이라 `flutter analyze`/빌드 영향 없음
- 다음부터 본 flow를 따르지 않으면 CLAUDE.md 위반 — 모든 세션에서 자동 적용됨
