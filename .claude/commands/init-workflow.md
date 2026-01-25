# init-workflow

Git worktree를 자동으로 생성하는 커맨드입니다.

브랜치명을 입력받아 자동으로:
1. 브랜치가 없으면 생성 (현재 브랜치에서 분기)
2. 브랜치명의 특수문자를 `_`로 변환하여 폴더명 생성
3. `{프로젝트명}-Worktree` 폴더에 worktree 생성 (예: `RomRom-FE-Worktree`)
4. 이미 존재하면 경로만 출력

## 사용법

```
/init-workflow

20260120_#163_Github_Projects_에_대한_템플릿_개발_필요_및_관련_Sync_워크플로우_개발_필요
```

## 실행 로직

1. 사용자 입력에서 두 번째 줄의 브랜치명 추출
2. Python 스크립트 실행: `.cursor/scripts/worktree_manager.py` 또는 `.claude/scripts/worktree_manager.py`
3. 스크립트 출력을 사용자에게 전달
4. 성공 시 worktree 경로 안내

---

사용자 입력에서 두 번째 줄을 추출하여 브랜치명으로 사용하세요.

브랜치명이 제공되지 않은 경우:
- 사용법을 안내하세요.

브랜치명이 제공된 경우:
1. 프로젝트 루트로 이동
2. `.cursor/scripts/worktree_manager.py` 또는 `.claude/scripts/worktree_manager.py` 스크립트 실행
3. 스크립트에 브랜치명을 인자로 전달
4. 스크립트의 출력을 사용자에게 그대로 전달
5. Exit code가 0이면 성공, 1이면 실패

**중요**:
- 스크립트는 프로젝트 루트 디렉토리에서 실행되어야 합니다.
- 브랜치명에 공백이나 특수문자가 포함될 수 있으므로 따옴표로 감싸서 전달하세요.
- `.cursor/scripts/` 또는 `.claude/scripts/` 중 존재하는 경로를 사용하세요.

## 추가 작업: gitignore 설정 파일 복사

Worktree 생성 후, 원본 프로젝트에서 새 worktree로 `.gitignore`에 포함된 설정 파일들을 복사해야 합니다.

### ✅ 복사해야 할 파일

다음 파일들이 원본에 존재하면 새 worktree로 복사하세요:

| 카테고리 | 파일 패턴 | 설명 |
|---------|----------|------|
| 환경 설정 | `application-*.yml`, `.env*` | Spring/Node 환경 설정 |
| 인증/키 | `*.jks`, `*.p12`, `key.properties` | 서명 키 및 키스토어 |
| Firebase | `google-services.json`, `GoogleService-Info.plist` | Firebase 설정 |
| iOS | `*.xcconfig` (예: `Secrets.xcconfig`) | iOS 빌드 설정 |
| 로컬 설정 | `.claude/settings.local.json` | Claude 로컬 설정 |

### ❌ 복사 금지 파일

다음은 절대 복사하지 마세요:

| 경로 | 이유 |
|-----|------|
| `.report/` | 보고서 (worktree별로 별도 생성) |
| `build/`, `target/` | 빌드 산출물 |
| `node_modules/`, `Pods/` | 의존성 (새로 설치 필요) |
| `.idea/` | IDE 캐시 |

### 복사 실행 방법

```bash
# 원본 프로젝트 루트에서 실행
# {WORKTREE_PATH}는 생성된 worktree 경로

# Firebase (Flutter)
cp android/app/google-services.json {WORKTREE_PATH}/android/app/
cp ios/Runner/GoogleService-Info.plist {WORKTREE_PATH}/ios/Runner/

# iOS 설정
cp ios/Flutter/*.xcconfig {WORKTREE_PATH}/ios/Flutter/

# Android 키
cp android/key.properties {WORKTREE_PATH}/android/

# Claude 로컬 설정
cp .claude/settings.local.json {WORKTREE_PATH}/.claude/
```

**참고**: 파일이 존재하지 않으면 해당 복사는 건너뛰세요.
