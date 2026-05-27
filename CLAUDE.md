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
- **공유 상태 갱신 (상태관리 — 필수)**: 한 화면의 액션(예: 채팅방 거래완료)이 **다른 화면이 들고 있는 목록/상태**(예: 홈 카드 덱·요청관리·마이페이지의 내 물건)에 영향을 주면, 그 화면들은 반드시 갱신되어야 한다. 다음을 지킨다.
  - **`MainScreen`은 `IndexedStack`이라 5개 탭이 항상 메모리에 생존한다** (`main_screen.dart`). 탭 전환은 `initState`를 다시 실행하지 않는다. 따라서 `initState`에서 1회만 로드하는 데이터는 다른 탭의 변경을 반영하지 못하고 **stale**해진다. "이 데이터는 앱이 떠 있는 동안 절대 안 바뀐다"가 확실한 경우에만 `initState` 1회 로드를 쓴다.
  - **바뀔 수 있는 공유 데이터는 전역 이벤트 버스로 갱신을 전파한다**: 단일 버스 `lib/services/app_event_bus.dart`(`AppEventBus`)와 타입 기반 이벤트(`lib/events/`의 `AppEvent` 하위 클래스)를 쓴다. 상태를 바꾸는 지점(API 성공/WebSocket 수신 직후)에서 `AppEventBus.instance.emit(const TradeCompletedEvent())`처럼 이벤트를 **발행**하고, 그 데이터를 보여주는 화면은 `initState`에서 **구독**해(`AppEventBus.instance.on<TradeCompletedEvent>().listen(...)`) 자신의 로드 함수를 재호출한다. `dispose`에서 `StreamSubscription.cancel()` 필수. **새 이벤트는 버스를 고치지 말고 `lib/events/`에 `AppEvent` 하위 클래스 파일만 추가**한다 (enum을 `lib/enums/`에 개별 파일로 두는 것과 동일한 컨벤션).
  - **목록 필터는 서버에 맡기고, 변경 시 재조회한다**: 클라이언트에서 항목을 수동으로 제거하지 말 것. 예) `getMyItems(itemStatus: AVAILABLE)`는 거래완료(EXCHANGED) 물건을 서버가 알아서 제외하므로, **재조회만 하면** 로컬 조작 없이 정확히 갱신된다.
  - **`GlobalKey`로 다른 화면의 메서드를 직접 호출하지 말 것**(예: A화면이 `B.globalKey.currentState.someMethod()` 호출). 화면 간 결합이 강해지고 깨지기 쉽다. 이벤트 버스 구독으로 대체한다.
  - **새 기능을 만들기 전에 "이 데이터를 누가 소유하고, 누가 구독하나"를 먼저 정한다.** 거래완료 카드 미갱신 버그(이슈 #875)가 이 규칙으로 정리되었다.
  - **새 이벤트 추가 / 구독 현황 / 4단계 레시피 → 상세: `.claude/instructions/state-management.md`** (버스는 절대 수정하지 말고 `lib/events/`에 이벤트 클래스만 추가). 설계 참고: `docs/superpowers/specs/2026-05-27-trade-completion-home-card-refresh-design.md`

- **API 중복 요청 방지**: 버튼/액션에서 API를 호출할 때 `Set<T> _pendingRequests` 패턴으로 진행 중인 요청 추적. 요청 시작 시 Set에 추가, `finally`에서 제거. 이미 Set에 있으면 early return.

- **iPad/대형기기 대응 (필수)**: 디자인 기준은 iPhone (393x852)이지만, iPad에서도 정상 동작해야 함.
  - **태블릿 여부 판별**: `lib/utils/device_type.dart`의 `isTablet` 전역 변수 사용. `MediaQuery.of(context).size.width > 600`을 직접 쓰지 말 것. `main.dart` 시작 시 `initDeviceType(context)`로 초기화되므로 앱 어디서든 `isTablet`으로 참조 가능
    ```dart
    // ✅ 올바른 사용
    import 'package:romrom_fe/utils/device_type.dart';
    final height = isTablet ? 88.0 : 64.0;

    // ❌ 금지
    final isTablet = MediaQuery.of(context).size.width > 600; // 매번 계산 금지
    ```
  - `SizedBox(height: N.h)` 같은 **고정 높이 컨테이너 안에 여러 위젯을 넣지 말 것** → overflow 발생. 대신 `IntrinsicHeight` 또는 고정 높이 제거
  - 이미지/정사각형 요소는 `height: N.h` 대신 **`height: N.w`** 사용 (너비 기준이 더 안전)
  - 위치 권한 거부 등 실패 케이스에서 **반드시 폴백 처리** (서울시청 좌표 등). `_currentPosition == null`인 채로 로딩 화면 유지 금지
  - `ScreenUtil` 설정: `minTextAdapt: true`, `splitScreenMode: true` 유지 필수
  - **모달/다이얼로그는 고정 픽셀값 사용** (`.w` `.h` 금지). 모달은 화면 크기에 비례하면 iPad에서 너무 커짐. `width: 312`, `height: 44` 같이 고정값 사용
  - **고정 높이 + 내부 Column 조합 금지**: `Container(height: N)` 안에 `Column`을 넣으면 내부 콘텐츠가 고정 높이를 초과할 때 overflow 발생. 대신 `Column(mainAxisSize: MainAxisSize.min)`으로 콘텐츠 크기에 맞게 자동 조절할 것
  - **`height: N.h` + `padding: vertical: N.h` 조합 절대 금지**: iPad에서 height와 padding 모두 1.6배로 커지면, padding만으로 height를 초과해 내용이 잘리거나 overflow 발생. 해결: `height` 제거 후 `const EdgeInsets.symmetric(vertical: 고정px)`만 사용. 컨테이너가 콘텐츠 크기에 맞게 자동 조절됨
    ```dart
    // ❌ 금지
    Container(height: 82.h, padding: EdgeInsets.symmetric(vertical: 16.h), child: ...)
    // ✅ 올바른
    Container(padding: const EdgeInsets.symmetric(vertical: 16), child: ...)
    ```
  - **시스템 UI 패딩 처리**: 하단 네비게이션바 등 시스템 영역과 맞닿는 위젯은 `height` 고정 대신 `MediaQuery.of(context).padding.bottom`을 `SizedBox`로 별도 처리. Android는 `padding.bottom=0`이 일반적이므로 iOS/Android 분기 처리 필요

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
| 상태관리 (화면 간 공유 상태 갱신, 이벤트 버스) | `.claude/instructions/state-management.md` |
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

## 표준 작업 Flow (AgenticFlow)

이슈 기반 작업 시 **무조건 이 순서**를 따른다. 관련 issue: [#836](https://github.com/TEAM-ROMROM/RomRom-FE/issues/836)

### Phase 1 — 이슈 + 워크트리
- **신규 이슈**: `/cassiiopeia:issue` (이슈 작성·등록·브랜치명 계산·worktree 옵션까지 한 방)
- **이슈 이미 있고 브랜치만 분리**: `/cassiiopeia:init-worktree`
- **긴급 버그 등 신속 대응 케이스**: worktree 생성 생략 가능 (main 또는 메인 작업 디렉터리에서 바로 진행)

### Phase 2 — 설계 (무조건 superpowers)
- `/superpowers:brainstorming` — 요구사항 명확화 → 디자인 → spec 문서 작성
- `/superpowers:writing-plans` — plan 문서 작성 (Task 단위로 분해)

### Phase 3 — 구현
- `/superpowers:subagent-driven-development` — Task별 implementer + spec reviewer + quality reviewer 디스패치

### Phase 4 — Commit + PR
- `/cassiiopeia:commit` — 사용자 승인 후 commit. push는 사용자 명시 요청 시
- `/cassiiopeia:github` — PR 생성

### Phase 5 — 빌드 + QA
- `/cassiiopeia:github` — 이슈에 `@suh-lab app build` 댓글 추가
- `/cassiiopeia:testcase` — 테스트케이스 MD 작성
- `/cassiiopeia:github` — 테스트케이스 이슈 댓글로 게시

### Phase 6 — main 머지 후 배포
- `/cassiiopeia:changelog-deploy` — main push + deploy PR 생성 + 릴리스 노트 작성 + automerge

### 절대 규칙 — Skill 우회 금지
- **GitHub 작업** (이슈/PR/댓글) → 무조건 `/cassiiopeia:github` 거치기. `gh`/`curl`/`Invoke-RestMethod` 직접 호출 금지
- **Commit** → 무조건 `/cassiiopeia:commit` 거치기. `git commit` 직접 호출 금지
- **설계/구현** → 무조건 superpowers 3-skill 체인 (`brainstorming` → `writing-plans` → `subagent-driven-development`) 거치기. 바로 코드 작성 금지

### 본 flow 미적용 예외
- 단순 typo 수정 / 1줄 변경 같은 trivial fix는 brainstorming/plan 생략 가능. 단 commit/push/PR/댓글은 skill 거치기
- 긴급 버그는 worktree 생성 생략 가능
- **메타성 / 문서성 변경** (CLAUDE.md, 리포트, plan/spec md, commands·skill 정리, 문서 오타 수정 등 앱 동작 영향 없는 변경)은 **Phase 5 생략** — `@suh-lab app build` 댓글 불필요, 테스트케이스 작성 불필요. Phase 4 commit/PR까지만 처리

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
