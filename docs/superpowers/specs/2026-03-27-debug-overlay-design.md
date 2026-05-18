# Debug Overlay 설계 문서

> 작성일: 2026-03-27

## 1. 개요

테스트 빌드(CI)에서만 활성화되는 앱 내 디버그 도구.
플로팅 버튼을 통해 로그 뷰어를 열고, 향후 자동 로그인/서버 로그 등 디버그 기능을 확장할 수 있는 구조.

### 목적

- 테스트 APK/TestFlight 빌드에서 시뮬레이터 콘솔 없이 앱 내에서 로그를 실시간으로 확인
- 프로덕션 빌드에는 일절 영향 없음

### 활성화 조건

- `.env` 파일에 `TEST_BUILD=true`가 있을 때만 동작
- CI 워크플로우(Android 테스트 APK, iOS 테스트 TestFlight)에서 `.env` 생성 시 자동 추가
- 프로덕션 워크플로우(`ROMROM-IOS-TESTFLIGHT.yaml`)에는 추가하지 않음

## 2. 아키텍처

```
┌─ CI 워크플로우 ─────────────────────┐
│ .env에 TEST_BUILD=true 한 줄 추가    │
└─────────────────────────────────────┘
              ↓
┌─ DebugConfig ───────────────────────┐
│ dotenv.get('TEST_BUILD') 읽기       │
│ → static bool isTestBuild 제공       │
└─────────────────────────────────────┘
              ↓
┌─ MyApp (main.dart) ─────────────────┐
│ if (DebugConfig.isTestBuild)         │
│   → DebugOverlayManager 초기화       │
│   → 플로팅 버튼 Overlay에 삽입        │
└─────────────────────────────────────┘
              ↓
┌─ DebugOverlayManager ──────────────┐
│ ├─ DebugFloatingButton (드래그 이동) │
│ └─ DebugMenuPanel (메뉴 목록)        │
│    ├─ 로그 뷰어 ← 1차 구현           │
│    ├─ 자동 로그인 ← 추후             │
│    └─ 서버 로그 ← 추후               │
└─────────────────────────────────────┘
              ↓
┌─ LogCapture ────────────────────────┐
│ Logger.root.onRecord 구독            │
│ 링버퍼(최근 1000개) 저장              │
│ StreamController.broadcast 실시간 전달│
└─────────────────────────────────────┘
              ↓
┌─ DebugLogPanel (리사이즈 패널) ──────┐
│ ├─ 실시간 스트리밍 (자동 스크롤)       │
│ ├─ 카테고리 필터 (체크박스)            │
│ ├─ 레벨 필터 (INFO/WARNING/SEVERE)   │
│ ├─ 텍스트 검색                       │
│ ├─ 로그 클리어                       │
│ └─ 클립보드 복사                     │
└─────────────────────────────────────┘
```

## 3. 파일 구조

```
lib/debug/
├─ debug_config.dart              # TEST_BUILD 플래그 읽기/관리
├─ debug_overlay_manager.dart     # Overlay 진입점 (버튼+메뉴+패널 생명주기)
├─ log_capture.dart               # Logger.root.onRecord 구독, 링버퍼, Stream
├─ widgets/
│  ├─ debug_floating_button.dart  # 드래그 가능한 원형 플로팅 버튼
│  ├─ debug_menu_panel.dart       # 메뉴 팝업 (로그뷰어/자동로그인/서버로그)
│  └─ debug_log_panel.dart        # 리사이즈 가능한 로그 뷰어 패널
```

## 4. 컴포넌트 상세

### 4.1 DebugConfig (`debug_config.dart`)

- `dotenv.get('TEST_BUILD', fallback: 'false')` 읽기
- `static bool isTestBuild` 제공
- 앱 초기화(`AppInitializer`) 시 1회 세팅, 이후 읽기 전용
- `TEST_BUILD=true`가 아닌 모든 경우 `false`

### 4.2 LogCapture (`log_capture.dart`)

- `Logger.root.onRecord.listen()`으로 **전체 로그** 캡처
- 링버퍼 (최근 1000개, 오래된 것부터 자동 제거 → 메모리 보호)
- `StreamController<LogRecord>.broadcast()`로 실시간 전달
- 각 LogRecord에서 사용하는 정보:
  - `time` — 타임스탬프
  - `level` — 로그 레벨 (INFO, WARNING, SEVERE 등)
  - `loggerName` — 카테고리 (http, app 등)
  - `message` — 로그 메시지
  - `error` — 에러 객체 (있을 경우)
  - `stackTrace` — 스택트레이스 (있을 경우)
- `start()` / `dispose()` 메서드로 구독 생명주기 관리
- `clear()` 메서드로 링버퍼 비우기

### 4.3 DebugFloatingButton (`debug_floating_button.dart`)

- 원형 버튼 (벌레 아이콘)
- `GestureDetector` + `Positioned`로 드래그 이동
- 화면 밖으로 나가지 않도록 `clamp` 처리
- 탭 → `DebugMenuPanel` 토글
- 초기 위치: 화면 우측 하단

### 4.4 DebugMenuPanel (`debug_menu_panel.dart`)

- 플로팅 버튼 옆에 나타나는 작은 메뉴 팝업
- 메뉴 항목:
  - "로그 뷰어" — 1차 구현, 탭 시 `DebugLogPanel` 열림
  - "자동 로그인" — 추후 구현 (비활성/회색 표시)
  - "서버 로그" — 추후 구현 (비활성/회색 표시)
- 메뉴 외부 탭 시 자동 닫힘

### 4.5 DebugLogPanel (`debug_log_panel.dart`)

- `Positioned` + `GestureDetector`로 **드래그 이동 + 리사이즈** 가능
- 최소 크기 제한 (가로 280, 세로 200)

#### 레이아웃

```
┌─ 상단 바 ──────────────────────────┐
│ [드래그 핸들]  "로그 뷰어"  [최소화][닫기] │
├─ 필터 영역 ────────────────────────┤
│ 카테고리: [✓http] [✓app] [✓...]    │
│ 레벨: [INFO ▼]  검색: [________]   │
├─ 로그 영역 ────────────────────────┤
│ 12:34:56 [INFO] http: GET /api...  │
│ 12:34:57 [SEVERE] app: Error...    │
│ ...                                │
│          (자동 스크롤)              │
├─ 하단 바 ──────────────────────────┤
│ [클리어]  로그 수: 142    [전체 복사] │
└────────────────────────────────────┘
```

#### 기능 상세

| 기능 | 설명 |
|------|------|
| 실시간 스트리밍 | `LogCapture.stream` 구독, 새 로그 추가 시 자동 스크롤 |
| 카테고리 필터 | `loggerName` 기준 체크박스, 동적으로 카테고리 수집 |
| 레벨 필터 | ALL/INFO/WARNING/SEVERE 드롭다운 선택 |
| 텍스트 검색 | 메시지 내용 contains 필터링 |
| 로그 클리어 | 링버퍼 + UI 모두 비움 |
| 클립보드 복사 | 현재 필터링된 로그 전체를 텍스트로 복사 |

#### 로그 색상

| 레벨 | 색상 |
|------|------|
| INFO | 흰색 |
| WARNING | 노란색 |
| SEVERE | 빨간색 |
| FINE/FINER/FINEST | 회색 |

## 5. 데이터 흐름

```
[앱 시작]
  → AppInitializer.loadEnv()
  → DebugConfig.init()          // TEST_BUILD=true 확인
  → LogCapture.start()          // Logger.root.onRecord 구독 시작
  → MyApp build
    → if (DebugConfig.isTestBuild)
      → DebugOverlayManager를 Overlay에 삽입

[런타임]
  Logger.log("...") → Logger.root.onRecord
    → LogCapture 링버퍼에 저장
    → StreamController.broadcast
      → DebugLogPanel이 구독하여 UI 갱신

[플로팅 버튼 탭]
  → DebugMenuPanel 열림
    → "로그 뷰어" 탭 → DebugLogPanel 열림/닫힘
    → 필터/검색/클리어/복사 조작
```

## 6. 기존 코드 수정 포인트 (최소한)

| 파일 | 변경 내용 | 수정량 |
|------|----------|--------|
| `lib/services/app_initializer.dart` | `DebugConfig.init()` + `LogCapture.start()` 호출 | 2줄 |
| `lib/main.dart` | `DebugOverlayManager` 초기화 (조건부) | 3~4줄 |
| `.github/workflows/ROMROM-ANDROID-TEST-APK.yaml` | `.env`에 `TEST_BUILD=true` 추가 | 1줄 |
| `.github/workflows/ROMROM-IOS-TEST-TESTFLIGHT.yaml` | `.env`에 `TEST_BUILD=true` 추가 (생성 + 재생성 스텝) | 2줄 |

기존 Logger, ApiClient, 화면 코드는 **수정 없음**.

## 7. CI 워크플로우 변경

### ROMROM-ANDROID-TEST-APK.yaml

```yaml
# Create .env file 스텝
- name: Create .env file
  run: |
    echo "${{ secrets.ENV_FILE }}" > .env
    echo "TEST_BUILD=true" >> .env    # 추가
    echo ".env file created"
```

### ROMROM-IOS-TEST-TESTFLIGHT.yaml

```yaml
# Create .env file 스텝
- name: Create .env file
  run: |
    echo "${{ secrets.ENV_FILE }}" > .env
    echo "TEST_BUILD=true" >> .env    # 추가
    echo ".env file created"

# Ensure .env file exists 스텝 (재생성 시에도 추가)
- name: Ensure .env file exists
  run: |
    if [ ! -f .env ]; then
      echo "${{ secrets.ENV_FILE }}" > .env
      echo "TEST_BUILD=true" >> .env  # 추가
    fi
```

### 프로덕션 워크플로우 (변경 없음)

- `ROMROM-IOS-TESTFLIGHT.yaml` — 수정하지 않음
- `.env`에 `TEST_BUILD` 키가 없으면 `DebugConfig.isTestBuild = false`

## 8. 확장 계획 (추후)

| 기능 | 설명 | 우선순위 |
|------|------|---------|
| 자동 로그인 | 테스트 계정으로 소셜 로그인 스킵 | 2차 |
| 서버 로그 | 서버 로그 API 연동하여 앱에서 확인 | 3차 |
| 네트워크 인스펙터 | HTTP 요청/응답 상세 뷰 (Alice 스타일) | 3차 |

## 9. 제약 사항

- 링버퍼 크기 1000개 — 메모리 보호를 위해 제한, 필요 시 조정 가능
- `TEST_BUILD=true`가 아닌 빌드에서는 `LogCapture`, `DebugOverlayManager` 모두 초기화하지 않음
- 플로팅 버튼/패널은 Overlay 기반이므로 앱의 모든 화면 위에 표시됨
