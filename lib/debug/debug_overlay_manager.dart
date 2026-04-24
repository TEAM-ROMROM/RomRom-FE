import 'package:flutter/material.dart';
import 'package:romrom_fe/debug/widgets/debug_log_panel.dart';
import 'package:romrom_fe/debug/widgets/debug_menu_panel.dart';
import 'package:romrom_fe/debug/widgets/debug_server_log_panel.dart';
import 'package:romrom_fe/debug/widgets/debug_url_panel.dart';
import 'package:romrom_fe/models/app_colors.dart';

/// 디버그 오버레이 전체 관리
/// 플로팅 버튼 + 메뉴 + 로그 패널의 표시/숨김 상태를 관리
class DebugOverlayManager {
  static final DebugOverlayManager _instance = DebugOverlayManager._internal();
  factory DebugOverlayManager() => _instance;
  DebugOverlayManager._internal();

  GlobalKey<NavigatorState>? _navigatorKey;
  OverlayEntry? _buttonEntry;
  OverlayEntry? _menuEntry;
  OverlayEntry? _logPanelEntry;
  OverlayEntry? _serverLogPanelEntry;

  OverlayEntry? _urlPanelEntry;

  double _buttonX = 0;
  double _buttonY = 0;

  bool _isMenuOpen = false;
  bool _isLogPanelOpen = false;
  bool _isServerLogPanelOpen = false;
  bool _isUrlPanelOpen = false;

  /// 디버그 오버레이 초기화 — navigatorKey의 overlay에 플로팅 버튼 삽입
  void init(GlobalKey<NavigatorState> navigatorKey) {
    // 기존 오버레이 정리 (중복 호출 방어)
    dispose();

    _navigatorKey = navigatorKey;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final overlay = navigatorKey.currentState?.overlay;
      if (overlay == null) return;

      _buttonEntry = OverlayEntry(
        builder: (context) {
          return _DebugButtonWrapper(
            onTap: _toggleMenu,
            onPositionChanged: (x, y) {
              _buttonX = x;
              _buttonY = y;
            },
          );
        },
      );
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
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    _menuEntry = OverlayEntry(
      builder: (context) {
        return DebugMenuPanel(
          x: _buttonX,
          y: _buttonY,
          onClose: _closeMenu,
          items: [
            DebugMenuItem(label: '로그 뷰어', icon: Icons.terminal, enabled: true, onTap: _toggleLogPanel),
            const DebugMenuItem(label: '자동 로그인', icon: Icons.login, enabled: false),
            DebugMenuItem(label: '서버 로그', icon: Icons.cloud, enabled: true, onTap: _toggleServerLogPanel),
            DebugMenuItem(label: '서버 URL 변경', icon: Icons.dns, enabled: true, onTap: _toggleUrlPanel),
          ],
        );
      },
    );
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
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    _logPanelEntry = OverlayEntry(
      builder: (context) {
        return DebugLogPanel(onClose: _closeLogPanel, onMinimize: _closeLogPanel);
      },
    );
    overlay.insert(_logPanelEntry!, below: _buttonEntry);
    _isLogPanelOpen = true;
  }

  void _closeLogPanel() {
    _logPanelEntry?.remove();
    _logPanelEntry = null;
    _isLogPanelOpen = false;
  }

  void _toggleServerLogPanel() {
    if (_isServerLogPanelOpen) {
      _closeServerLogPanel();
    } else {
      _openServerLogPanel();
    }
  }

  void _openServerLogPanel() {
    _closeServerLogPanel();
    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) return;

    _serverLogPanelEntry = OverlayEntry(
      builder: (context) {
        return DebugServerLogPanel(onClose: _closeServerLogPanel, onMinimize: _closeServerLogPanel);
      },
    );
    overlay.insert(_serverLogPanelEntry!, below: _buttonEntry);
    _isServerLogPanelOpen = true;
  }

  void _closeServerLogPanel() {
    _serverLogPanelEntry?.remove();
    _serverLogPanelEntry = null;
    _isServerLogPanelOpen = false;
  }

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
        return DebugUrlPanel(onClose: _closeUrlPanel);
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

  /// 리소스 정리
  void dispose() {
    _closeMenu();
    _closeLogPanel();
    _closeServerLogPanel();
    _closeUrlPanel();
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
            color: AppColors.primaryBlack.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.primaryYellow, width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: const Icon(Icons.bug_report, color: AppColors.primaryYellow, size: 24),
        ),
      ),
    );
  }
}
