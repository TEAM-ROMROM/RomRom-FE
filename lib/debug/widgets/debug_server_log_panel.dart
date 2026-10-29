import 'package:flutter/material.dart';
import 'package:romrom_fe/debug/debug_overlay_manager.dart';
import 'package:romrom_fe/debug/server_log_client.dart';
import 'package:romrom_fe/debug/widgets/debug_log_viewer_panel.dart';

/// 서버 로그 뷰어 패널 (WebSocket 기반, 연결 상태·연결 토글·AOP 토글 추가)
class DebugServerLogPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;
  // null이면 DebugOverlayManager 싱글톤 클라이언트 (테스트 교체 지점)
  final ServerLogClient? serverLogClient;

  const DebugServerLogPanel({super.key, required this.onClose, required this.onMinimize, this.serverLogClient});

  @override
  State<DebugServerLogPanel> createState() => _DebugServerLogPanelState();
}

class _DebugServerLogPanelState extends State<DebugServerLogPanel> {
  // 서버 로그 클라이언트 (DebugOverlayManager 싱글톤 — 백그라운드 suspend/resume 공유)
  ServerLogClient get _client => widget.serverLogClient ?? DebugOverlayManager().serverLogClient;

  @override
  void initState() {
    super.initState();
    // 패널 열릴 때 연결 (패널 닫힘 시 disconnect하지 않음 — DebugOverlayManager.dispose()에서 관리)
    _client.connect();
  }

  void _toggleConnection() {
    if (_client.isConnected) {
      _client.disconnect();
    } else {
      _client.connect();
    }
    setState(() {});
  }

  // AOP 상세 로그(@LogMonitor 등) 토글 — 켜면 서버가 상세 진단 로그를 흘려보냄 (평소 OFF)
  void _toggleAop() {
    _client.setAopEnabled(!_client.isAopEnabled);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DebugLogViewerPanel(
      title: '서버 로그',
      emptyLogText: '서버 로그 없음',
      readLogs: () => _client.logs,
      logStream: _client.stream,
      clearLogs: _client.clear,
      buildTitleBarActions: _buildConnectionActions,
      onClose: widget.onClose,
      onMinimize: widget.onMinimize,
    );
  }

  /// 연결 상태 점 + 연결 토글 + AOP 토글
  List<Widget> _buildConnectionActions() {
    return [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(shape: BoxShape.circle, color: _client.isConnected ? Colors.green : Colors.red),
      ),
      const SizedBox(width: 4),
      DebugTitleBarButton(icon: _client.isConnected ? Icons.link : Icons.link_off, onTap: _toggleConnection),
      // AOP 상세 로그 토글 — 켜지면 주황색으로 강조
      DebugTitleBarButton(
        icon: _client.isAopEnabled ? Icons.bug_report : Icons.bug_report_outlined,
        color: _client.isAopEnabled ? Colors.orangeAccent : null,
        onTap: _toggleAop,
      ),
    ];
  }
}
