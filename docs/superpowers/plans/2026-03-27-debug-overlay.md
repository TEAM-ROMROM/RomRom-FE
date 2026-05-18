# Debug Overlay 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 테스트 빌드에서만 활성화되는 앱 내 플로팅 디버그 오버레이(로그 뷰어) 구현

**Architecture:** `.env`의 `TEST_BUILD=true` 플래그로 활성화. `Logger.root.onRecord`를 구독하여 링버퍼에 저장하고, Overlay 기반 플로팅 버튼 → 메뉴 → 리사이즈 가능한 로그 뷰어 패널 순서로 UI 제공. 기존 코드 변경은 `app_initializer.dart`(2줄), `main.dart`(3~4줄), CI 워크플로우(각 1~2줄)만.

**Tech Stack:** Flutter, flutter_dotenv, logging (기존 사용 중), Overlay API

**GitHub Issue:** #715
**설계 문서:** `docs/superpowers/specs/2026-03-27-debug-overlay-design.md`
**브랜치:** `20260327_#715_테스트_빌드_전용_앱_내_디버그_오버레이_구현`

---

## 파일 구조

### 새로 생성할 파일

| 파일 | 역할 |
|------|------|
| `lib/debug/debug_config.dart` | `TEST_BUILD` 플래그 읽기, `static bool isTestBuild` 제공 |
| `lib/debug/log_capture.dart` | `Logger.root.onRecord` 구독, 링버퍼(1000개), `StreamController.broadcast` |
| `lib/debug/debug_overlay_manager.dart` | Overlay 진입점 — 플로팅 버튼 + 메뉴 + 패널 생명주기 관리 |
| `lib/debug/widgets/debug_floating_button.dart` | 드래그 가능한 원형 플로팅 버튼 |
| `lib/debug/widgets/debug_menu_panel.dart` | 메뉴 팝업 (로그 뷰어 / 자동로그인(비활성) / 서버로그(비활성)) |
| `lib/debug/widgets/debug_log_panel.dart` | 리사이즈/드래그 가능한 로그 뷰어 패널 (필터, 검색, 클리어, 복사) |

### 수정할 파일

| 파일 | 변경 내용 |
|------|----------|
| `lib/services/app_initializer.dart` | `DebugConfig.init()` + `LogCapture.start()` 호출 추가 |
| `lib/main.dart` | `DebugOverlayManager` 조건부 초기화 추가 |
| `.github/workflows/ROMROM-ANDROID-TEST-APK.yaml` | `.env` 생성 시 `TEST_BUILD=true` 추가 |
| `.github/workflows/ROMROM-IOS-TEST-TESTFLIGHT.yaml` | `.env` 생성 + 재생성 시 `TEST_BUILD=true` 추가 |

---

## Task 1: DebugConfig — TEST_BUILD 플래그 읽기

**Files:**
- Create: `lib/debug/debug_config.dart`

- [ ] **Step 1: `lib/debug/debug_config.dart` 생성**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 테스트 빌드 설정 관리
/// .env 파일의 TEST_BUILD=true 여부로 디버그 도구 활성화 결정
class DebugConfig {
  static bool _isTestBuild = false;

  /// 테스트 빌드 여부 (읽기 전용)
  static bool get isTestBuild => _isTestBuild;

  /// 앱 초기화 시 1회 호출 (.env 로드 이후)
  static void init() {
    final value = dotenv.get('TEST_BUILD', fallback: 'false');
    _isTestBuild = value.toLowerCase() == 'true';
  }
}
```

- [ ] **Step 2: `lib/services/app_initializer.dart` 수정 — DebugConfig.init() 호출 추가**

`initialize()` 함수의 `await loadEnv()` 다음 줄에 추가:

```dart
import 'package:romrom_fe/debug/debug_config.dart';

Future<void> initialize() async {
  await loadEnv(); // .env 파일 로딩
  DebugConfig.init(); // TEST_BUILD 플래그 확인 (loadEnv 직후)
  await initNaverMap(); // 네이버 지도 초기화
  await initGoogleSignIn(); // Google Sign-In 초기화 (v7 필수)
  initKakaoSdk(); // 카카오 sdk 초기화
  initLogger(); // logger 초기화
}
```

- [ ] **Step 3: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/debug_config.dart lib/services/app_initializer.dart
```

---

## Task 2: LogCapture — 로그 캡처 및 링버퍼

**Files:**
- Create: `lib/debug/log_capture.dart`
- Modify: `lib/services/app_initializer.dart`

- [ ] **Step 1: `lib/debug/log_capture.dart` 생성**

```dart
import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';

/// 앱 전체 로그를 캡처하여 링버퍼에 저장하고 실시간 스트림으로 전달
class LogCapture {
  static const int _maxBufferSize = 1000;

  static final LogCapture _instance = LogCapture._internal();
  factory LogCapture() => _instance;
  LogCapture._internal();

  final ListQueue<LogRecord> _buffer = ListQueue<LogRecord>();
  final StreamController<LogRecord> _controller = StreamController<LogRecord>.broadcast();
  StreamSubscription<LogRecord>? _subscription;

  /// 현재 버퍼의 로그 목록 (읽기 전용)
  List<LogRecord> get logs => _buffer.toList();

  /// 실시간 로그 스트림
  Stream<LogRecord> get stream => _controller.stream;

  /// 현재 수집된 고유 카테고리(loggerName) 목록
  Set<String> get categories => _buffer.map((r) => r.loggerName).toSet();

  /// 로그 캡처 시작 (Logger.root.onRecord 구독)
  void start() {
    _subscription?.cancel();
    _subscription = Logger.root.onRecord.listen((record) {
      // 링버퍼: 최대 크기 초과 시 가장 오래된 로그 제거
      if (_buffer.length >= _maxBufferSize) {
        _buffer.removeFirst();
      }
      _buffer.addLast(record);
      _controller.add(record);
    });
  }

  /// 버퍼 비우기
  void clear() {
    _buffer.clear();
  }

  /// 캡처 중단 및 리소스 정리
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _controller.close();
  }
}
```

- [ ] **Step 2: `lib/services/app_initializer.dart` 수정 — LogCapture 조건부 시작**

`initLogger()` 함수 끝에 조건부 LogCapture 시작 추가:

```dart
import 'package:romrom_fe/debug/debug_config.dart';
import 'package:romrom_fe/debug/log_capture.dart';

/// Logger 초기화
void initLogger() {
  Logger.root.level = Level.ALL; // 모든 로그 출력
  Logger.root.onRecord.listen((record) {
    debugPrint('[${record.level.name}] ${record.time}: ${record.loggerName} - ${record.message}');
  });

  // 테스트 빌드인 경우 로그 캡처 시작
  if (DebugConfig.isTestBuild) {
    LogCapture().start();
  }
}
```

**주의:** `Logger.root.onRecord`는 여러 리스너를 허용하므로, 기존 `debugPrint` 리스너와 `LogCapture` 리스너가 동시에 동작함. 기존 동작에 영향 없음.

- [ ] **Step 3: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/log_capture.dart lib/services/app_initializer.dart
```

---

## Task 3: DebugFloatingButton — 드래그 가능한 플로팅 버튼

**Files:**
- Create: `lib/debug/widgets/debug_floating_button.dart`

- [ ] **Step 1: `lib/debug/widgets/debug_floating_button.dart` 생성**

```dart
import 'package:flutter/material.dart';

/// 드래그 가능한 디버그 플로팅 버튼
/// 화면 어디에서든 표시되며, 사용자가 자유롭게 위치를 이동할 수 있음
class DebugFloatingButton extends StatefulWidget {
  final VoidCallback onTap;

  const DebugFloatingButton({super.key, required this.onTap});

  @override
  State<DebugFloatingButton> createState() => _DebugFloatingButtonState();
}

class _DebugFloatingButtonState extends State<DebugFloatingButton> {
  static const double _buttonSize = 48;

  // 초기 위치: 화면 우측 하단 (build 시 화면 크기 기반으로 초기화)
  double _x = -1;
  double _y = -1;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 최초 1회 위치 초기화 (화면 우측 하단)
    if (!_initialized) {
      _x = screenSize.width - _buttonSize - 16;
      _y = screenSize.height - _buttonSize - 100;
      _initialized = true;
    }

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x = (_x + details.delta.dx).clamp(0, screenSize.width - _buttonSize);
            _y = (_y + details.delta.dy).clamp(0, screenSize.height - _buttonSize);
          });
        },
        onTap: widget.onTap,
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            color: const Color(0xCC1D1E27),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFC300), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.bug_report, color: Color(0xFFFFC300), size: 24),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/widgets/debug_floating_button.dart
```

---

## Task 4: DebugMenuPanel — 메뉴 팝업

**Files:**
- Create: `lib/debug/widgets/debug_menu_panel.dart`

- [ ] **Step 1: `lib/debug/widgets/debug_menu_panel.dart` 생성**

```dart
import 'package:flutter/material.dart';

/// 디버그 메뉴 항목 정의
class DebugMenuItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;

  const DebugMenuItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.enabled = true,
  });
}

/// 디버그 메뉴 팝업 패널
/// 플로팅 버튼 탭 시 표시되는 메뉴 목록
class DebugMenuPanel extends StatelessWidget {
  final List<DebugMenuItem> items;
  final VoidCallback onClose;
  final double x;
  final double y;

  const DebugMenuPanel({
    super.key,
    required this.items,
    required this.onClose,
    required this.x,
    required this.y,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // 메뉴 위치 계산: 버튼 왼쪽 위에 표시, 화면 밖으로 나가지 않도록 보정
    final menuWidth = 180.0;
    final menuHeight = items.length * 48.0 + 16;
    final menuX = (x - menuWidth - 8).clamp(8.0, screenSize.width - menuWidth - 8);
    final menuY = (y - menuHeight / 2).clamp(8.0, screenSize.height - menuHeight - 8);

    return Stack(
      children: [
        // 배경 탭 시 메뉴 닫기
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // 메뉴 패널
        Positioned(
          left: menuX,
          top: menuY,
          child: Container(
            width: menuWidth,
            decoration: BoxDecoration(
              color: const Color(0xF01D1E27),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4C4E54), width: 1),
              boxShadow: const [
                BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) => _buildMenuItem(item)).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem(DebugMenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.enabled ? () {
          onClose();
          item.onTap?.call();
        } : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 20,
                color: item.enabled ? const Color(0xFFFFC300) : const Color(0xFF4C4E54),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    color: item.enabled ? Colors.white : const Color(0xFF4C4E54),
                    fontSize: 14,
                  ),
                ),
              ),
              if (!item.enabled)
                const Text(
                  '추후',
                  style: TextStyle(color: Color(0xFF4C4E54), fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/widgets/debug_menu_panel.dart
```

---

## Task 5: DebugLogPanel — 리사이즈 가능한 로그 뷰어

**Files:**
- Create: `lib/debug/widgets/debug_log_panel.dart`

이 파일이 가장 큰 컴포넌트. 상세 구현 내용:

- [ ] **Step 1: `lib/debug/widgets/debug_log_panel.dart` 생성**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:romrom_fe/debug/log_capture.dart';

/// 리사이즈/드래그 가능한 로그 뷰어 패널
class DebugLogPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const DebugLogPanel({super.key, required this.onClose, required this.onMinimize});

  @override
  State<DebugLogPanel> createState() => _DebugLogPanelState();
}

class _DebugLogPanelState extends State<DebugLogPanel> {
  // 패널 위치/크기
  double _x = 16;
  double _y = 80;
  double _width = 360;
  double _height = 400;
  static const double _minWidth = 280;
  static const double _minHeight = 200;

  // 로그 데이터
  final LogCapture _logCapture = LogCapture();
  StreamSubscription<LogRecord>? _subscription;
  List<LogRecord> _filteredLogs = [];

  // 필터 상태
  final Set<String> _enabledCategories = {};
  Level _minLevel = Level.ALL;
  String _searchQuery = '';
  bool _autoScroll = true;

  // 컨트롤러
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // 필터 영역 표시 여부
  bool _showFilters = true;

  @override
  void initState() {
    super.initState();
    // 초기 카테고리 전부 활성화
    _enabledCategories.addAll(_logCapture.categories);
    _applyFilters();

    // 실시간 로그 구독
    _subscription = _logCapture.stream.listen((record) {
      // 새 카테고리 자동 추가
      if (!_enabledCategories.contains(record.loggerName)) {
        _enabledCategories.add(record.loggerName);
      }
      _applyFilters();
      if (_autoScroll && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (!mounted) return;
    setState(() {
      _filteredLogs = _logCapture.logs.where((record) {
        // 카테고리 필터
        if (_enabledCategories.isNotEmpty && !_enabledCategories.contains(record.loggerName)) {
          return false;
        }
        // 레벨 필터
        if (record.level < _minLevel) return false;
        // 검색 필터
        if (_searchQuery.isNotEmpty) {
          final message = record.message.toLowerCase();
          final query = _searchQuery.toLowerCase();
          if (!message.contains(query)) return false;
        }
        return true;
      }).toList();
    });
  }

  void _clearLogs() {
    _logCapture.clear();
    _applyFilters();
  }

  void _copyLogs() {
    final text = _filteredLogs.map((r) {
      final time = '${r.time.hour.toString().padLeft(2, '0')}:'
          '${r.time.minute.toString().padLeft(2, '0')}:'
          '${r.time.second.toString().padLeft(2, '0')}';
      var line = '$time [${r.level.name}] ${r.loggerName}: ${r.message}';
      if (r.error != null) line += '\n  Error: ${r.error}';
      if (r.stackTrace != null) line += '\n  ${r.stackTrace}';
      return line;
    }).join('\n');
    Clipboard.setData(ClipboardData(text: text));
  }

  Color _levelColor(Level level) {
    if (level >= Level.SEVERE) return const Color(0xFFFF5656);
    if (level >= Level.WARNING) return const Color(0xFFFFC300);
    if (level >= Level.INFO) return Colors.white;
    return const Color(0xFF888888); // FINE/FINER/FINEST
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
          height: _height,
          decoration: BoxDecoration(
            color: const Color(0xF01D1E27),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF4C4E54), width: 1),
            boxShadow: const [
              BoxShadow(color: Color(0x60000000), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Column(
            children: [
              _buildTitleBar(screenSize),
              if (_showFilters) _buildFilterBar(),
              Expanded(child: _buildLogList()),
              _buildBottomBar(),
              _buildResizeHandle(screenSize),
            ],
          ),
        ),
      ),
    );
  }

  /// 상단 타이틀 바 (드래그 핸들 + 제목 + 버튼)
  Widget _buildTitleBar(Size screenSize) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _x = (_x + details.delta.dx).clamp(0, screenSize.width - _width);
          _y = (_y + details.delta.dy).clamp(0, screenSize.height - _height);
        });
      },
      child: Container(
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFF34353D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Icon(Icons.drag_indicator, color: Color(0xFF888888), size: 16),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                '로그 뷰어',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            // 필터 토글
            _titleBarButton(
              icon: _showFilters ? Icons.filter_list : Icons.filter_list_off,
              onTap: () => setState(() => _showFilters = !_showFilters),
            ),
            // 자동 스크롤 토글
            _titleBarButton(
              icon: _autoScroll ? Icons.vertical_align_bottom : Icons.pause,
              onTap: () => setState(() => _autoScroll = !_autoScroll),
            ),
            // 최소화
            _titleBarButton(icon: Icons.minimize, onTap: widget.onMinimize),
            // 닫기
            _titleBarButton(icon: Icons.close, onTap: widget.onClose),
          ],
        ),
      ),
    );
  }

  Widget _titleBarButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, color: const Color(0xFFCCCCCC), size: 16),
      ),
    );
  }

  /// 필터 영역
  Widget _buildFilterBar() {
    final allCategories = _logCapture.categories.toList()..sort();
    final levels = [Level.ALL, Level.FINE, Level.INFO, Level.WARNING, Level.SEVERE];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF4C4E54), width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카테고리 필터 (체크박스)
          if (allCategories.isNotEmpty)
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: allCategories.map((cat) {
                final enabled = _enabledCategories.contains(cat);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (enabled) {
                        _enabledCategories.remove(cat);
                      } else {
                        _enabledCategories.add(cat);
                      }
                    });
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: enabled ? const Color(0x33FFC300) : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: enabled ? const Color(0xFFFFC300) : const Color(0xFF4C4E54),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      cat.isEmpty ? '(root)' : cat,
                      style: TextStyle(
                        color: enabled ? const Color(0xFFFFC300) : const Color(0xFF888888),
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 4),
          // 레벨 + 검색
          Row(
            children: [
              // 레벨 드롭다운
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF34353D),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Level>(
                    value: _minLevel,
                    isDense: true,
                    dropdownColor: const Color(0xFF34353D),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    items: levels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level == Level.ALL ? 'ALL' : level.name, style: const TextStyle(fontSize: 11)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _minLevel = value);
                        _applyFilters();
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 검색 입력
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                    decoration: InputDecoration(
                      hintText: '검색...',
                      hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 11),
                      prefixIcon: const Icon(Icons.search, size: 14, color: Color(0xFF888888)),
                      prefixIconConstraints: const BoxConstraints(minWidth: 28),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      filled: true,
                      fillColor: const Color(0xFF34353D),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      _searchQuery = value;
                      _applyFilters();
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 로그 목록
  Widget _buildLogList() {
    if (_filteredLogs.isEmpty) {
      return const Center(
        child: Text('로그 없음', style: TextStyle(color: Color(0xFF888888), fontSize: 12)),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      itemCount: _filteredLogs.length,
      itemBuilder: (context, index) {
        final record = _filteredLogs[index];
        final time = '${record.time.hour.toString().padLeft(2, '0')}:'
            '${record.time.minute.toString().padLeft(2, '0')}:'
            '${record.time.second.toString().padLeft(2, '0')}';
        final color = _levelColor(record.level);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$time ',
                      style: const TextStyle(color: Color(0xFF888888), fontSize: 10, fontFamily: 'monospace'),
                    ),
                    TextSpan(
                      text: '[${record.level.name}] ',
                      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                    TextSpan(
                      text: '${record.loggerName}: ',
                      style: const TextStyle(color: Color(0xFF88AAFF), fontSize: 10, fontFamily: 'monospace'),
                    ),
                    TextSpan(
                      text: record.message,
                      style: TextStyle(color: color, fontSize: 10, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              if (record.error != null)
                Text(
                  '  Error: ${record.error}',
                  style: const TextStyle(color: Color(0xFFFF5656), fontSize: 10, fontFamily: 'monospace'),
                ),
              if (record.stackTrace != null)
                Text(
                  '  ${record.stackTrace}',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 9, fontFamily: 'monospace'),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        );
      },
    );
  }

  /// 하단 바 (클리어 + 로그 수 + 복사)
  Widget _buildBottomBar() {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF4C4E54), width: 0.5)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _clearLogs,
            child: const Row(
              children: [
                Icon(Icons.delete_outline, size: 14, color: Color(0xFFCCCCCC)),
                SizedBox(width: 4),
                Text('클리어', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
              ],
            ),
          ),
          const Spacer(),
          Text(
            '${_filteredLogs.length}건',
            style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _copyLogs,
            child: const Row(
              children: [
                Icon(Icons.copy, size: 14, color: Color(0xFFCCCCCC)),
                SizedBox(width: 4),
                Text('복사', style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 리사이즈 핸들 (우측 하단)
  Widget _buildResizeHandle(Size screenSize) {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _width = (_width + details.delta.dx).clamp(_minWidth, screenSize.width - _x);
            _height = (_height + details.delta.dy).clamp(_minHeight, screenSize.height - _y);
          });
        },
        child: Container(
          width: 20,
          height: 20,
          alignment: Alignment.bottomRight,
          child: const Icon(Icons.drag_handle, size: 14, color: Color(0xFF888888)),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/widgets/debug_log_panel.dart
```

---

## Task 6: DebugOverlayManager — Overlay 관리 및 통합

**Files:**
- Create: `lib/debug/debug_overlay_manager.dart`

- [ ] **Step 1: `lib/debug/debug_overlay_manager.dart` 생성**

```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/debug/widgets/debug_floating_button.dart';
import 'package:romrom_fe/debug/widgets/debug_log_panel.dart';
import 'package:romrom_fe/debug/widgets/debug_menu_panel.dart';

/// 디버그 오버레이 전체 관리
/// 플로팅 버튼 + 메뉴 + 로그 패널의 표시/숨김 상태를 관리
class DebugOverlayManager {
  static final DebugOverlayManager _instance = DebugOverlayManager._internal();
  factory DebugOverlayManager() => _instance;
  DebugOverlayManager._internal();

  OverlayEntry? _buttonEntry;
  OverlayEntry? _menuEntry;
  OverlayEntry? _logPanelEntry;

  // 플로팅 버튼 위치 (메뉴 위치 계산에 사용)
  double _buttonX = 0;
  double _buttonY = 0;

  bool _isMenuOpen = false;
  bool _isLogPanelOpen = false;

  /// 디버그 오버레이 초기화 — navigatorKey의 overlay에 플로팅 버튼 삽입
  void init(GlobalKey<NavigatorState> navigatorKey) {
    // 네비게이터가 준비될 때까지 대기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null) return;

      _buttonEntry = OverlayEntry(builder: (context) {
        return _DebugButtonWrapper(
          onTap: _toggleMenu,
          onPositionChanged: (x, y) {
            _buttonX = x;
            _buttonY = y;
          },
        );
      });
      overlay.insert(_buttonEntry!);
    });
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    _closeMenu();
    final overlay = _buttonEntry?.overlay;
    if (overlay == null) return;

    _menuEntry = OverlayEntry(builder: (context) {
      return DebugMenuPanel(
        x: _buttonX,
        y: _buttonY,
        onClose: _closeMenu,
        items: [
          DebugMenuItem(
            label: '로그 뷰어',
            icon: Icons.terminal,
            enabled: true,
            onTap: _toggleLogPanel,
          ),
          const DebugMenuItem(
            label: '자동 로그인',
            icon: Icons.login,
            enabled: false,
          ),
          const DebugMenuItem(
            label: '서버 로그',
            icon: Icons.cloud,
            enabled: false,
          ),
        ],
      );
    });
    overlay.insert(_menuEntry!);
    _isMenuOpen = true;
  }

  void _closeMenu() {
    _menuEntry?.remove();
    _menuEntry = null;
    _isMenuOpen = false;
  }

  void _toggleLogPanel() {
    if (_isLogPanelOpen) {
      _closeLogPanel();
    } else {
      _openLogPanel();
    }
  }

  void _openLogPanel() {
    _closeLogPanel();
    final overlay = _buttonEntry?.overlay;
    if (overlay == null) return;

    _logPanelEntry = OverlayEntry(builder: (context) {
      return DebugLogPanel(
        onClose: _closeLogPanel,
        onMinimize: _closeLogPanel,
      );
    });
    overlay.insert(_logPanelEntry!, below: _buttonEntry);
    _isLogPanelOpen = true;
  }

  void _closeLogPanel() {
    _logPanelEntry?.remove();
    _logPanelEntry = null;
    _isLogPanelOpen = false;
  }

  /// 리소스 정리
  void dispose() {
    _closeMenu();
    _closeLogPanel();
    _buttonEntry?.remove();
    _buttonEntry = null;
  }
}

/// 플로팅 버튼 래퍼 (위치 추적 포함)
class _DebugButtonWrapper extends StatefulWidget {
  final VoidCallback onTap;
  final void Function(double x, double y) onPositionChanged;

  const _DebugButtonWrapper({required this.onTap, required this.onPositionChanged});

  @override
  State<_DebugButtonWrapper> createState() => _DebugButtonWrapperState();
}

class _DebugButtonWrapperState extends State<_DebugButtonWrapper> {
  static const double _buttonSize = 48;
  double _x = -1;
  double _y = -1;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (!_initialized) {
      _x = screenSize.width - _buttonSize - 16;
      _y = screenSize.height - _buttonSize - 100;
      _initialized = true;
      widget.onPositionChanged(_x, _y);
    }

    return Positioned(
      left: _x,
      top: _y,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _x = (_x + details.delta.dx).clamp(0, screenSize.width - _buttonSize);
            _y = (_y + details.delta.dy).clamp(0, screenSize.height - _buttonSize);
          });
          widget.onPositionChanged(_x, _y);
        },
        onTap: widget.onTap,
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            color: const Color(0xCC1D1E27),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFC300), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.bug_report, color: Color(0xFFFFC300), size: 24),
        ),
      ),
    );
  }
}
```

**주의:** `DebugOverlayManager`가 자체적으로 `_DebugButtonWrapper`를 포함하므로, Task 3에서 만든 `debug_floating_button.dart`는 독립 사용을 위한 백업으로 남겨둠. 실제로 Overlay에서는 `_DebugButtonWrapper`가 위치 추적까지 통합 처리.

- [ ] **Step 2: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/debug_overlay_manager.dart
```

---

## Task 7: main.dart 통합 — 조건부 디버그 오버레이 삽입

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: `lib/main.dart` 수정 — import 및 DebugOverlayManager 초기화 추가**

파일 상단에 import 추가:

```dart
import 'package:romrom_fe/debug/debug_config.dart';
import 'package:romrom_fe/debug/debug_overlay_manager.dart';
```

`_MyAppState.initState()` 메서드에 디버그 오버레이 초기화 추가:

```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  // 테스트 빌드인 경우 디버그 오버레이 초기화
  if (DebugConfig.isTestBuild) {
    DebugOverlayManager().init(navigatorKey);
  }
}
```

`_MyAppState.dispose()` 메서드에 디버그 오버레이 정리 추가:

```dart
@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  if (DebugConfig.isTestBuild) {
    DebugOverlayManager().dispose();
  }
  super.dispose();
}
```

- [ ] **Step 2: 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/main.dart
```

---

## Task 8: CI 워크플로우 변경 — TEST_BUILD 플래그 추가

**Files:**
- Modify: `.github/workflows/ROMROM-ANDROID-TEST-APK.yaml:216`
- Modify: `.github/workflows/ROMROM-IOS-TEST-TESTFLIGHT.yaml:117,367`

- [ ] **Step 1: `ROMROM-ANDROID-TEST-APK.yaml` 수정**

216줄 `echo "${{ secrets.ENV_FILE }}" > .env` 다음에 한 줄 추가:

```yaml
      - name: Create .env file
        run: |
          echo "${{ secrets.ENV_FILE }}" > .env
          echo "TEST_BUILD=true" >> .env
          echo ".env file created"
```

- [ ] **Step 2: `ROMROM-IOS-TEST-TESTFLIGHT.yaml` 수정 — Create .env file 스텝 (117줄 부근)**

```yaml
      - name: Create .env file
        run: |
          echo "${{ secrets.ENV_FILE }}" > .env
          echo "TEST_BUILD=true" >> .env
          echo ".env file created"
```

- [ ] **Step 3: `ROMROM-IOS-TEST-TESTFLIGHT.yaml` 수정 — Ensure .env file exists 스텝 (367줄 부근)**

```yaml
      - name: Ensure .env file exists
        run: |
          if [ ! -f .env ]; then
            echo "⚠️ .env 파일이 아티팩트에서 복원되지 않았습니다. 재생성합니다."
            echo "${{ secrets.ENV_FILE }}" > .env
            echo "TEST_BUILD=true" >> .env
          fi
          echo "✅ .env 파일 확인됨 (크기: $(wc -c < .env) bytes)"
```

---

## Task 9: 포매팅 및 최종 확인

- [ ] **Step 1: 전체 debug 폴더 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/debug/
```

- [ ] **Step 2: 수정된 기존 파일 포매팅**

```bash
source ~/.zshrc && dart format --line-length=120 lib/main.dart lib/services/app_initializer.dart
```

- [ ] **Step 3: 린트 분석**

```bash
source ~/.zshrc && flutter analyze
```

에러 발생 시 수정 후 재실행.

---

## 구현 순서 요약

| Task | 내용 | 의존성 |
|------|------|--------|
| 1 | DebugConfig (플래그 읽기) | 없음 |
| 2 | LogCapture (로그 캡처) | Task 1 |
| 3 | DebugFloatingButton (플로팅 버튼) | 없음 |
| 4 | DebugMenuPanel (메뉴 팝업) | 없음 |
| 5 | DebugLogPanel (로그 뷰어 패널) | Task 2 |
| 6 | DebugOverlayManager (통합 관리) | Task 3, 4, 5 |
| 7 | main.dart 통합 | Task 1, 6 |
| 8 | CI 워크플로우 변경 | 없음 (독립) |
| 9 | 포매팅 및 최종 확인 | 전체 |
