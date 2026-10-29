import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// 캡처된 로그 항목
class CapturedLog {
  final DateTime time;
  final String message;

  CapturedLog({required this.time, required this.message});
}

/// 앱 전체 debugPrint 출력을 캡처하여 링버퍼에 저장하고 실시간 스트림으로 전달
class LogCapture {
  // 로그 버퍼 최대 보관 건수 (초과 시 오래된 것부터 제거, 서버 로그 버퍼도 공용)
  static const int maximumBufferedLogCount = 1000;

  static final LogCapture _instance = LogCapture._internal();
  factory LogCapture() => _instance;
  LogCapture._internal();

  final ListQueue<CapturedLog> _buffer = ListQueue<CapturedLog>();
  final StreamController<CapturedLog> _controller = StreamController<CapturedLog>.broadcast();

  DebugPrintCallback? _originalDebugPrint;

  /// 현재 버퍼의 로그 목록 (읽기 전용)
  List<CapturedLog> get logs => _buffer.toList();

  /// 실시간 로그 스트림
  Stream<CapturedLog> get stream => _controller.stream;

  /// debugPrint를 오버라이드하여 로그 캡처 시작
  void start() {
    _originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      // 원래 콘솔 출력 유지
      _originalDebugPrint?.call(message, wrapWidth: wrapWidth);

      // 빈 메시지 무시
      if (message == null || message.isEmpty) return;

      final log = CapturedLog(time: DateTime.now(), message: message);
      if (_buffer.length >= maximumBufferedLogCount) {
        _buffer.removeFirst();
      }
      _buffer.addLast(log);
      _controller.add(log);
    };
  }

  /// 버퍼 비우기
  void clear() {
    _buffer.clear();
  }

  /// 캡처 중단 및 리소스 정리
  void dispose() {
    if (_originalDebugPrint != null) {
      debugPrint = _originalDebugPrint!;
      _originalDebugPrint = null;
    }
  }
}
