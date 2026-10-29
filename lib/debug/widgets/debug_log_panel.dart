import 'package:flutter/material.dart';
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/debug/widgets/debug_log_viewer_panel.dart';

/// 리사이즈/드래그 가능한 로그 뷰어 패널 (앱 debugPrint 캡처 로그)
class DebugLogPanel extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onMinimize;

  const DebugLogPanel({super.key, required this.onClose, required this.onMinimize});

  @override
  Widget build(BuildContext context) {
    final logCapture = LogCapture();
    return DebugLogViewerPanel(
      title: '로그 뷰어',
      emptyLogText: '로그 없음',
      readLogs: () => logCapture.logs,
      logStream: logCapture.stream,
      clearLogs: logCapture.clear,
      onClose: onClose,
      onMinimize: onMinimize,
    );
  }
}
