# 개발자 도구 개선 3종 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 개발자 도구 오버레이의 로그 복사 버그 수정(#792), SSE 재연결 지수 백오프 적용(#796), API Base URL 런타임 동적 변경 기능 추가(#793)를 하나의 브랜치에서 처리한다.

**Architecture:** 이슈 #792, #796은 기존 파일 수정만으로 완결된다. 이슈 #793은 `AppUrls.baseUrl`을 동적 getter로 전환하고, `DebugUrlConfig`(저장소)와 `DebugUrlPanel`(UI)을 신규 추가한 뒤 `DebugOverlayManager`에 연결한다. `SharedPreferences`는 이미 프로젝트에 포함되어 있어 별도 추가 불필요.

**Tech Stack:** Flutter, Dart, SharedPreferences (`^2.5.2`), 기존 디버그 오버레이 패턴(`DebugLogPanel` 스타일)

**워크트리 경로:** `D:/0-suh/project/RomRom-FE-Worktree/20260423_#793_API_Base_URL_런타임_동적_변경_기능_추가`

---

## 파일 맵

| 상태 | 파일 | 역할 |
|------|------|------|
| 수정 | `lib/debug/widgets/debug_log_panel.dart` | `_copyLogs()` async/await 수정 |
| 수정 | `lib/debug/widgets/debug_server_log_panel.dart` | `_copyLogs()` async/await 수정 + 재연결 상태 UI |
| 수정 | `lib/debug/server_log_client.dart` | 지수 백오프 로직, `reconnectCount`/`nextReconnectIn` getter |
| 수정 | `lib/models/app_urls.dart` | `baseUrl` 동적 getter 전환 |
| 수정 | `lib/services/apis/*.dart` (59곳) | `const String url` → `final String url` |
| 수정 | `lib/services/api_client.dart` (1곳) | `const String url` → `final String url` |
| 신규 | `lib/debug/debug_url_config.dart` | SharedPreferences로 URL 저장/복원 |
| 신규 | `lib/debug/widgets/debug_url_panel.dart` | URL 변경 패널 UI |
| 수정 | `lib/debug/debug_overlay_manager.dart` | "서버 URL 변경" 메뉴 항목 + 패널 연결 |
| 수정 | `lib/main.dart` | `DebugUrlConfig.restore()` 앱 시작 시 호출 |

---

## Task 1: 로그 복사 버튼 async/await 수정 (#792)

**Files:**
- Modify: `lib/debug/widgets/debug_log_panel.dart:96-111`
- Modify: `lib/debug/widgets/debug_server_log_panel.dart:98-113`

- [ ] **Step 1: `debug_log_panel.dart`의 `_copyLogs()` 수정**

`lib/debug/widgets/debug_log_panel.dart`의 `_copyLogs()` 를 아래로 교체한다:

```dart
Future<void> _copyLogs() async {
  final text = _filteredLogs
      .map((log) {
        final time =
            '${log.time.hour.toString().padLeft(2, '0')}:'
            '${log.time.minute.toString().padLeft(2, '0')}:'
            '${log.time.second.toString().padLeft(2, '0')}';
        return '$time ${log.message}';
      })
      .join('\n');
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _showCopiedFeedback = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCopiedFeedback = false);
    });
  } catch (_) {
    if (!mounted) return;
    setState(() => _showCopiedFeedback = false);
  }
}
```

- [ ] **Step 2: `debug_server_log_panel.dart`의 `_copyLogs()` 동일하게 수정**

`lib/debug/widgets/debug_server_log_panel.dart`의 `_copyLogs()` 를 아래로 교체한다:

```dart
Future<void> _copyLogs() async {
  final text = _filteredLogs
      .map((log) {
        final time =
            '${log.time.hour.toString().padLeft(2, '0')}:'
            '${log.time.minute.toString().padLeft(2, '0')}:'
            '${log.time.second.toString().padLeft(2, '0')}';
        return '$time ${log.message}';
      })
      .join('\n');
  try {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _showCopiedFeedback = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showCopiedFeedback = false);
    });
  } catch (_) {
    if (!mounted) return;
    setState(() => _showCopiedFeedback = false);
  }
}
```

- [ ] **Step 3: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/widgets/debug_log_panel.dart lib/debug/widgets/debug_server_log_panel.dart
```

---

## Task 2: SSE 재연결 지수 백오프 (#796)

**Files:**
- Modify: `lib/debug/server_log_client.dart`
- Modify: `lib/debug/widgets/debug_server_log_panel.dart`

- [ ] **Step 1: `server_log_client.dart` 필드 교체 및 로직 수정**

`lib/debug/server_log_client.dart`에서 기존 `_reconnectDelay` 상수와 `_scheduleReconnect()` 메서드를 아래로 교체한다.

기존 상수 제거:
```dart
// 제거할 줄
static const Duration _reconnectDelay = Duration(seconds: 3);
```

아래 필드 추가 (클래스 필드 영역에):
```dart
static const Duration _initialReconnectDelay = Duration(seconds: 3);
static const Duration _maxReconnectDelay = Duration(seconds: 60);

Duration _currentReconnectDelay = _initialReconnectDelay;
int _reconnectCount = 0;

int get reconnectCount => _reconnectCount;
Duration get nextReconnectIn => _currentReconnectDelay;
```

`_doConnect()` 내 `_isConnected = true;` 줄 바로 뒤에 리셋 코드 추가:
```dart
_isConnected = true;
_reconnectCount = 0;
_currentReconnectDelay = _initialReconnectDelay;
```

기존 `_scheduleReconnect()` 메서드를 아래로 교체:
```dart
void _scheduleReconnect() {
  if (!_shouldReconnect) return;
  _reconnectTimer?.cancel();
  _reconnectTimer = Timer(_currentReconnectDelay, () {
    if (_shouldReconnect) _doConnect();
  });
  _reconnectCount++;
  _currentReconnectDelay = Duration(
    seconds: (_currentReconnectDelay.inSeconds * 2).clamp(
      _initialReconnectDelay.inSeconds,
      _maxReconnectDelay.inSeconds,
    ),
  );
}
```

- [ ] **Step 2: `debug_server_log_panel.dart`에 재연결 상태 표시 UI 추가**

`lib/debug/widgets/debug_server_log_panel.dart`에서:

1. `_subscription` 리스너에 상태 갱신 추가 — `initState()`의 `_subscription = _client.stream.listen(...)` 안에 setState 추가:
```dart
_subscription = _client.stream.listen((log) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 100), () {
    if (mounted) setState(() {});  // 연결 상태 포함 전체 갱신
    _applyFilters();
    if (_autoScroll && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  });
});
```

2. `_buildTitleBar()` 내 연결 상태 표시 부분을 아래로 교체 (기존 초록/빨강 점 + 링크 버튼 영역):
```dart
// 기존: Container(width: 8, height: 8, decoration: ...) 와 SizedBox(width: 4) 제거하고 아래로 교체
if (!_client.isConnected && _client.reconnectCount > 0)
  Padding(
    padding: const EdgeInsets.only(right: 4),
    child: Text(
      '재연결 중... (${_client.reconnectCount}회 / ${_client.nextReconnectIn.inSeconds}s 후)',
      style: const TextStyle(color: Colors.orange, fontSize: 9),
    ),
  )
else
  Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _client.isConnected ? Colors.green : Colors.red,
        ),
      ),
      const SizedBox(width: 4),
    ],
  ),
```

- [ ] **Step 3: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/server_log_client.dart lib/debug/widgets/debug_server_log_panel.dart
```

---

## Task 3: `AppUrls.baseUrl` 동적 getter 전환 (#793)

**Files:**
- Modify: `lib/models/app_urls.dart`

- [ ] **Step 1: `app_urls.dart` 수정**

`lib/models/app_urls.dart`의 `baseUrl` 줄을 아래로 교체한다:

```dart
/// 프로젝트 내 URL 관리
class AppUrls {
  static const String _defaultBaseUrl = "https://api.romrom.suhsaechan.kr";
  static String _runtimeBaseUrl = _defaultBaseUrl;

  static String get baseUrl => _runtimeBaseUrl;

  // ignore: prefer_asserts_with_message
  static void setBaseUrl(String url) {
    assert(() {
      _runtimeBaseUrl = url;
      return true;
    }());
  }

  static void resetBaseUrl() => setBaseUrl(_defaultBaseUrl);

  static const String itemShareBaseUrl = "https://romrom-c4008.web.app";
  static const String imageBaseUrl = "https://suh-project.synology.me";
  static const String naverReverseGeoCodeApiUrl =
      "https://maps.apigw.ntruss.com/map-reversegeocode/v2/gc";
  static const String naverStaticMapApiUrl = 'https://maps.apigw.ntruss.com/map-static/v2/raster';

  static const String androidStoreUrl = "https://play.google.com/store/apps/details?id=com.alom.romrom&hl=ko";
  static const String iosStoreUrl = "https://apps.apple.com/kr/iphone/today";
}
```

- [ ] **Step 2: `server_log_client.dart`의 `_endpoint` getter화**

`lib/debug/server_log_client.dart`에서:
```dart
// 기존
static const String _endpoint = '${AppUrls.baseUrl}/api/app/debug/log-stream';

// 변경
static String get _endpoint => '${AppUrls.baseUrl}/api/app/debug/log-stream';
```

- [ ] **Step 3: 서비스 파일들의 `const String url` → `final String url` 일괄 변경**

아래 명령으로 `lib/services/` 하위의 모든 `const String url =` 을 `final String url =` 로 교체한다:

```bash
cd D:/0-suh/project/RomRom-FE && grep -rln "const String url = " lib/services/ | while read f; do
  sed -i 's/const String url = /final String url = /g' "$f"
  echo "fixed: $f"
done
```

교체 후 확인 (0이어야 함):
```bash
grep -rn "const String url = " lib/services/ | wc -l
```

- [ ] **Step 4: `api_client.dart` 1곳 수정**

```bash
grep -n "const String url" lib/services/api_client.dart
```

해당 줄을 `final String url`로 수정한다 (409번 줄 부근):
```dart
// 기존
const String url = '${AppUrls.baseUrl}/api/auth/reissue';
// 변경
final String url = '${AppUrls.baseUrl}/api/auth/reissue';
```

- [ ] **Step 5: 포매팅 및 린트 확인**

```bash
source ~/.zshrc && dart format --line-length=120 lib/models/app_urls.dart lib/debug/server_log_client.dart lib/services/api_client.dart
source ~/.zshrc && flutter analyze lib/models/app_urls.dart lib/debug/server_log_client.dart
```

---

## Task 4: `DebugUrlConfig` 신규 구현 (#793)

**Files:**
- Create: `lib/debug/debug_url_config.dart`

- [ ] **Step 1: `lib/debug/debug_url_config.dart` 생성**

```dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugUrlConfig {
  static const String _prefKey = 'debug_base_url';

  static Future<void> restore() async {
    assert(kDebugMode, 'DebugUrlConfig는 Debug 빌드 전용');
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      AppUrls.setBaseUrl(saved);
    }
  }

  static Future<void> save(String url) async {
    assert(kDebugMode, 'DebugUrlConfig는 Debug 빌드 전용');
    AppUrls.setBaseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, url);
  }

  static Future<void> reset() async {
    assert(kDebugMode, 'DebugUrlConfig는 Debug 빌드 전용');
    AppUrls.resetBaseUrl();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }
}
```

- [ ] **Step 2: `main.dart`에서 `DebugUrlConfig.restore()` 호출**

`lib/main.dart`에 import 추가:
```dart
import 'package:romrom_fe/debug/debug_url_config.dart';
```

`main()` 함수의 `await initialize();` 바로 뒤에 추가:
```dart
await initialize();
if (kDebugMode) await DebugUrlConfig.restore();
```

`kDebugMode`는 이미 `package:flutter/foundation.dart`에서 제공되며 `main.dart`에서 이미 import되어 있는지 확인. 없으면 추가:
```dart
import 'package:flutter/foundation.dart';
```

- [ ] **Step 3: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/debug_url_config.dart lib/main.dart
```

---

## Task 5: `DebugUrlPanel` 신규 구현 (#793)

**Files:**
- Create: `lib/debug/widgets/debug_url_panel.dart`

- [ ] **Step 1: `lib/debug/widgets/debug_url_panel.dart` 생성**

```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/debug/debug_url_config.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_urls.dart';

class DebugUrlPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const DebugUrlPanel({super.key, required this.onClose, required this.onMinimize});

  @override
  State<DebugUrlPanel> createState() => _DebugUrlPanelState();
}

class _DebugUrlPanelState extends State<DebugUrlPanel> {
  double _x = 16;
  double _y = 80;
  static const double _width = 340;

  late TextEditingController _urlController;
  bool _showAppliedFeedback = false;

  static const String _defaultUrl = "https://api.romrom.suhsaechan.kr";
  static const List<_UrlPreset> _presets = [
    _UrlPreset(label: 'Prod', url: _defaultUrl),
    _UrlPreset(label: 'PR Preview', url: 'http://romrom-pr-'),
  ];

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: AppUrls.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    await DebugUrlConfig.save(url);
    if (!mounted) return;
    setState(() => _showAppliedFeedback = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _showAppliedFeedback = false);
    });
  }

  Future<void> _reset() async {
    await DebugUrlConfig.reset();
    if (!mounted) return;
    setState(() => _urlController.text = _defaultUrl);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      left: _x,
      top: _y,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: _width,
          decoration: BoxDecoration(
            color: AppColors.primaryBlack.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.secondaryBlack2, width: 1),
            boxShadow: const [BoxShadow(color: Color(0x60000000), blurRadius: 16, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTitleBar(screenSize),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleBar(Size screenSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _x = (_x + details.delta.dx).clamp(0, screenSize.width - _width);
          _y = (_y + details.delta.dy).clamp(0.0, screenSize.height - 200);
        });
      },
      child: Container(
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Color(0xFF888888), size: 16),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                '서버 URL 변경',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            GestureDetector(
              onTap: widget.onMinimize,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.minimize, color: Color(0xFFCCCCCC), size: 16),
              ),
            ),
            GestureDetector(
              onTap: widget.onClose,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close, color: Color(0xFFCCCCCC), size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('현재 적용 중', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
          const SizedBox(height: 2),
          Text(
            AppUrls.baseUrl,
            style: const TextStyle(color: AppColors.primaryYellow, fontSize: 11, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 10),
          const Text('변경할 URL', style: TextStyle(color: Color(0xFF888888), fontSize: 10)),
          const SizedBox(height: 4),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            decoration: InputDecoration(
              hintText: 'https://...',
              hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              filled: true,
              fillColor: AppColors.secondaryBlack1,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: _presets.map((preset) {
              return GestureDetector(
                onTap: () => setState(() => _urlController.text = preset.url),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBlack1,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.secondaryBlack2),
                  ),
                  child: Text(preset.label, style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 10)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _reset,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBlack1,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: const Text('초기화', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: _apply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _showAppliedFeedback ? AppColors.primaryYellow : AppColors.secondaryBlack2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _showAppliedFeedback ? '적용됨!' : '적용',
                      style: TextStyle(
                        color: _showAppliedFeedback ? AppColors.primaryBlack : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UrlPreset {
  final String label;
  final String url;
  const _UrlPreset({required this.label, required this.url});
}
```

- [ ] **Step 2: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/widgets/debug_url_panel.dart
```

---

## Task 6: `DebugOverlayManager`에 URL 패널 연결 (#793)

**Files:**
- Modify: `lib/debug/debug_overlay_manager.dart`

- [ ] **Step 1: import 및 필드 추가**

`lib/debug/debug_overlay_manager.dart`에 import 추가:
```dart
import 'package:romrom_fe/debug/widgets/debug_url_panel.dart';
```

클래스 필드에 추가 (기존 `_isServerLogPanelOpen` 아래):
```dart
OverlayEntry? _urlPanelEntry;
bool _isUrlPanelOpen = false;
```

- [ ] **Step 2: 메뉴 항목 추가**

`_openMenu()`의 `items` 리스트에 항목 추가:
```dart
items: [
  DebugMenuItem(label: '로그 뷰어', icon: Icons.terminal, enabled: true, onTap: _toggleLogPanel),
  const DebugMenuItem(label: '자동 로그인', icon: Icons.login, enabled: false),
  DebugMenuItem(label: '서버 로그', icon: Icons.cloud, enabled: true, onTap: _toggleServerLogPanel),
  DebugMenuItem(label: '서버 URL 변경', icon: Icons.dns, enabled: true, onTap: _toggleUrlPanel),
],
```

- [ ] **Step 3: URL 패널 토글 메서드 추가**

`_closeServerLogPanel()` 메서드 아래에 추가:
```dart
void _toggleUrlPanel() {
  if (_isUrlPanelOpen) {
    _closeUrlPanel();
  } else {
    _openUrlPanel();
  }
}

void _openUrlPanel() {
  _closeUrlPanel();
  final overlay = _navigatorKey?.currentState?.overlay;
  if (overlay == null) return;

  _urlPanelEntry = OverlayEntry(
    builder: (context) {
      return DebugUrlPanel(onClose: _closeUrlPanel, onMinimize: _closeUrlPanel);
    },
  );
  overlay.insert(_urlPanelEntry!, below: _buttonEntry);
  _isUrlPanelOpen = true;
}

void _closeUrlPanel() {
  _urlPanelEntry?.remove();
  _urlPanelEntry = null;
  _isUrlPanelOpen = false;
}
```

- [ ] **Step 4: `dispose()`에 URL 패널 정리 추가**

기존 `dispose()`:
```dart
void dispose() {
  _closeMenu();
  _closeLogPanel();
  _closeServerLogPanel();
  _buttonEntry?.remove();
  _buttonEntry = null;
}
```

`_closeServerLogPanel();` 아래에 `_closeUrlPanel();` 추가:
```dart
void dispose() {
  _closeMenu();
  _closeLogPanel();
  _closeServerLogPanel();
  _closeUrlPanel();
  _buttonEntry?.remove();
  _buttonEntry = null;
}
```

- [ ] **Step 5: 포매팅 및 최종 린트**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/debug_overlay_manager.dart
source ~/.zshrc && flutter analyze lib/debug/ lib/models/app_urls.dart lib/main.dart
```

---

## Self-Review

**스펙 커버리지 체크:**
- [x] #792 `_copyLogs()` async/await + 실패 피드백 → Task 1
- [x] #796 지수 백오프 (3s→6s→12s→24s→60s 상한) → Task 2 Step 1
- [x] #796 재연결 상태 UI → Task 2 Step 2
- [x] #793 `AppUrls.baseUrl` 동적 getter → Task 3 Step 1
- [x] #793 `server_log_client._endpoint` getter화 → Task 3 Step 2
- [x] #793 `const String url` → `final String url` 59+1곳 → Task 3 Steps 3-4
- [x] #793 `DebugUrlConfig` 신규 → Task 4
- [x] #793 `main.dart`에 restore() 호출 → Task 4 Step 2
- [x] #793 `DebugUrlPanel` 신규 → Task 5
- [x] #793 `DebugOverlayManager` 연결 → Task 6
- [x] Debug 빌드 전용 가드 (`assert(kDebugMode)`, `setBaseUrl`의 `assert`) → Task 3, 4
- [x] 마지막 설정 유지 (SharedPreferences) → Task 4

**타입/메서드명 일관성:**
- `AppUrls.setBaseUrl(String)` — Task 3에서 정의, Task 4, 5에서 호출 ✓
- `AppUrls.resetBaseUrl()` — Task 3에서 정의, Task 4, 5에서 호출 ✓
- `DebugUrlConfig.restore()` — Task 4에서 정의, `main.dart`에서 호출 ✓
- `DebugUrlConfig.save(String)` — Task 4에서 정의, Task 5에서 호출 ✓
- `DebugUrlConfig.reset()` — Task 4에서 정의, Task 5에서 호출 ✓
- `ServerLogClient.reconnectCount` — Task 2 Step 1에서 정의, Step 2에서 참조 ✓
- `ServerLogClient.nextReconnectIn` — Task 2 Step 1에서 정의, Step 2에서 참조 ✓
