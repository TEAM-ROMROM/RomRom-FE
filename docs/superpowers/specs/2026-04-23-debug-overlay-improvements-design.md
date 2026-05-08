# 설계 문서: 개발자 도구 개선 3종

**이슈**: #792, #793, #796  
**날짜**: 2026-04-23  
**브랜치**: 이슈 #793 기준 브랜치

---

## 1. 개요

디버그 오버레이(개발자 도구)의 세 가지 버그/기능을 하나의 브랜치에서 함께 처리한다.

| 이슈 | 종류 | 한 줄 요약 |
|------|------|-----------|
| #792 | 버그 수정 | 로그 복사 버튼 `await` 누락 + 실패 피드백 추가 |
| #796 | 버그 개선 | SSE 재연결 지수 백오프 + 상태 UI 표시 |
| #793 | 기능 추가 | API Base URL 런타임 동적 변경 (Debug 빌드 전용) |

---

## 2. 이슈 #792 — 로그 복사 버튼 수정

### 문제
`lib/debug/widgets/debug_log_panel.dart:96`의 `_copyLogs()`가 `async`가 아니고 `Clipboard.setData()`에 `await`가 없어서 복사 성공 여부와 무관하게 "복사됨!" 피드백이 표시된다.

### 수정 내용
- `_copyLogs()`를 `Future<void>`로 변경하고 `await Clipboard.setData(...)` 적용
- `try/catch`로 복사 실패 시 "복사 실패" 피드백 표시
- 동일 패턴이 `debug_server_log_panel.dart`에도 있으면 함께 수정

### 변경 파일
- `lib/debug/widgets/debug_log_panel.dart`
- `lib/debug/widgets/debug_server_log_panel.dart` (동일 패턴 존재 시)

---

## 3. 이슈 #796 — SSE 재연결 지수 백오프

### 문제
`server_log_client.dart`에서 연결 종료 시 항상 3초 후 재연결을 시도해 서버가 즉시 스트림을 닫는 상황에서 무한 루프가 발생한다.

### 수정 내용

**지수 백오프 로직:**
- 재연결 대기 시간: 3s → 6s → 12s → 24s → 최대 60s (2배씩 증가)
- 연결 성공 시 재연결 카운터 리셋
- `_reconnectDelay` 상수 제거 → `_currentReconnectDelay` + `_reconnectCount` 필드로 교체

**상태 UI 표시 (`debug_server_log_panel.dart`):**
- 재연결 중일 때 패널 상단에 "재연결 중... (N회차, Xs 후)" 표시
- 연결 성공 시 정상 상태로 복귀
- `ServerLogClient`에 `reconnectCount` getter 추가 (UI에서 읽기 위함)

### 변경 파일
- `lib/debug/server_log_client.dart`
- `lib/debug/widgets/debug_server_log_panel.dart`

---

## 4. 이슈 #793 — API Base URL 런타임 변경

### 제약 조건
- **Debug 빌드 전용** (`kDebugMode` 가드)
- 마지막 설정값 유지 (`SharedPreferences` 저장)
- 앱 재시작 시 저장된 값 복원 (저장값 없으면 prod URL 기본값)

### 아키텍처

#### 4-1. `AppUrls` 동적화

```dart
// 변경 전
static const String baseUrl = "https://api.romrom.suhsaechan.kr";

// 변경 후
static const String _defaultBaseUrl = "https://api.romrom.suhsaechan.kr";
static String _runtimeBaseUrl = _defaultBaseUrl;

static String get baseUrl => _runtimeBaseUrl;

static void setBaseUrl(String url) {
  assert(() { // Debug 빌드에서만 동작
    _runtimeBaseUrl = url;
    return true;
  }());
}

static void resetBaseUrl() {
  setBaseUrl(_defaultBaseUrl);
}
```

- `const String url = '${AppUrls.baseUrl}/...'` 패턴(59곳) → `final String url = '${AppUrls.baseUrl}/...'`로 일괄 변경 (`const` 제거)
- `server_log_client.dart`의 `static const String _endpoint` → `static String get _endpoint`로 변경

#### 4-2. URL 설정 저장소: `DebugUrlConfig`

신규 파일: `lib/debug/debug_url_config.dart`

- `SharedPreferences`로 마지막 설정 URL 저장/불러오기
- 앱 시작 시 `DebugUrlConfig.restore()`를 호출하여 저장된 URL을 `AppUrls`에 적용
- 프리셋 목록 관리 (prod + PR Preview URL 목록)

```dart
class DebugUrlConfig {
  static const String _prefKey = 'debug_base_url';
  static const String _defaultUrl = "https://api.romrom.suhsaechan.kr";

  static Future<void> restore() async { ... }        // 앱 시작 시 호출
  static Future<void> save(String url) async { ... } // URL 변경 시 호출
  static Future<void> reset() async { ... }          // 기본값으로 리셋
}
```

`main.dart`의 `initDeviceType()` 호출 근방에서 `await DebugUrlConfig.restore()` 호출.

#### 4-3. URL 변경 패널: `DebugUrlPanel`

신규 파일: `lib/debug/widgets/debug_url_panel.dart`

UI 구성:
- 현재 적용 중인 Base URL 표시
- 텍스트 입력창 (직접 입력)
- 프리셋 버튼 (Prod, PR Preview 입력 보조)
- "적용" 버튼 → `AppUrls.setBaseUrl()` + `DebugUrlConfig.save()` 호출
- "초기화" 버튼 → prod URL로 리셋

패널 외형은 기존 `DebugLogPanel` / `DebugServerLogPanel`과 동일한 드래그/리사이즈 스타일 적용.

#### 4-4. `DebugOverlayManager` 메뉴 항목 추가

`debug_overlay_manager.dart`의 `items` 리스트에 "서버 URL 변경" 항목 추가:

```dart
DebugMenuItem(label: '서버 URL 변경', icon: Icons.dns, enabled: true, onTap: _toggleUrlPanel),
```

`_urlPanelEntry`, `_isUrlPanelOpen`, `_toggleUrlPanel()`, `_openUrlPanel()`, `_closeUrlPanel()` 추가.

### 변경 파일
- `lib/models/app_urls.dart`
- `lib/services/apis/*.dart` (59곳 `const` → `final`)
- `lib/services/api_client.dart` (1곳)
- `lib/debug/server_log_client.dart` (`_endpoint` getter화)
- `lib/debug/debug_url_config.dart` (신규)
- `lib/debug/widgets/debug_url_panel.dart` (신규)
- `lib/debug/debug_overlay_manager.dart`
- `lib/main.dart` (`DebugUrlConfig.restore()` 호출)

---

## 5. 구현 순서

1. **#792** — 단순 버그 수정, 가장 먼저 처리
2. **#796** — `server_log_client.dart` 수정 (독립적)
3. **#793** — `AppUrls` 동적화 → `DebugUrlConfig` → `DebugUrlPanel` → `DebugOverlayManager` 연결

---

## 6. 체크리스트

- [ ] `_copyLogs()` async/await 수정 및 실패 피드백
- [ ] SSE 지수 백오프 로직 구현
- [ ] SSE 재연결 상태 UI 표시
- [ ] `AppUrls.baseUrl` 동적 getter 전환
- [ ] `const String url` → `final String url` 일괄 변경 (59곳 + api_client 1곳)
- [ ] `DebugUrlConfig` 신규 구현
- [ ] `main.dart`에 `DebugUrlConfig.restore()` 추가
- [ ] `DebugUrlPanel` 신규 구현
- [ ] `DebugOverlayManager`에 URL 패널 연결
