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
    // StreamController는 싱글톤이므로 close하지 않음
    // 앱 생명주기와 함께 유지
  }
}
