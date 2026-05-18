# ⚙️[기능추가][AgenticFlow] CLAUDE.md에 표준 작업 Flow 및 Skill 우회 금지 규칙 추가

**라벨**: 작업전
**담당자**: Cassiiopeia

---

📝 현재 문제점
---

- 이슈 기반 작업 시 어떤 skill을 어느 순서로 호출해야 하는지에 대한 표준이 CLAUDE.md에 명시되어 있지 않음
- Claude가 매번 다르게 판단하여 skill을 우회하고 `gh`/`curl`/`Invoke-RestMethod`/`git commit` 등을 직접 호출하는 사례 발생
- 설계·구현 단계에서 superpowers 3-skill 체인(brainstorming → writing-plans → subagent-driven-development) 없이 바로 코드 작성하는 경우 발생
- 표준 flow 부재로 인해 작업 단계 누락(예: 빌드 댓글, 테스트케이스 등록 누락) 발생

🛠️ 해결 방안 / 제안 기능
---

`D:/0-suh/project/RomRom-FE/CLAUDE.md`에 다음 내용을 추가한다.

### 표준 작업 Flow (이슈 기반 작업 시 무조건 이 순서)

- **Phase 1 — 이슈 + 워크트리**
  - 신규 이슈: `/cassiiopeia:issue` (이슈 작성·등록·브랜치명·worktree 옵션까지 한 방)
  - 이슈 이미 있고 브랜치만 분리: `/cassiiopeia:init-worktree`
  - 긴급 버그 등 신속 대응 케이스: worktree 생략 가능
- **Phase 2 — 설계 (무조건 superpowers)**
  - `/superpowers:brainstorming` (요구사항 → 디자인 → spec 문서 작성)
  - `/superpowers:writing-plans` (plan 문서 작성)
- **Phase 3 — 구현**
  - `/superpowers:subagent-driven-development` (Task별 implementer + spec/quality reviewer)
- **Phase 4 — Commit + PR**
  - `/cassiiopeia:commit` (사용자 승인 후 commit. push는 사용자 명시 요청 시)
  - `/cassiiopeia:github`로 PR 생성
- **Phase 5 — 빌드 + QA**
  - `/cassiiopeia:github`로 이슈 댓글 `@suh-lab app build` 추가
  - `/cassiiopeia:testcase`로 테스트케이스 MD 작성
  - `/cassiiopeia:github`로 테스트케이스 이슈 댓글 게시
- **Phase 6 — main 머지 후 배포**
  - `/cassiiopeia:changelog-deploy` (main push + deploy PR + 릴리스 노트 + automerge)

### 절대 규칙 — Skill 우회 금지

- GitHub 작업 (이슈/PR/댓글) → 무조건 `/cassiiopeia:github` 거치기. `gh`/`curl`/`Invoke-RestMethod` 직접 호출 금지
- Commit → 무조건 `/cassiiopeia:commit` 거치기. `git commit` 직접 호출 금지
- 설계/구현 → 무조건 superpowers 3-skill 체인 거치기. 바로 코드 작성 금지

### 본 flow 미적용 예외

- 단순 typo 수정 / 1줄 변경 같은 trivial fix는 brainstorming/plan 생략 가능. 단 commit/push/PR/댓글은 skill 거치기
- 긴급 버그는 worktree 생성 생략 가능

⚙️ 작업 내용
---

- `D:/0-suh/project/RomRom-FE/CLAUDE.md`에 위 내용 추가
- main에 직접 작업 (별도 worktree/브랜치 없이)
- 사용자 승인 후 commit + push

🙋‍♂️ 담당자
---

- 백엔드: -
- 프론트엔드: Cassiiopeia
- 디자인: -
