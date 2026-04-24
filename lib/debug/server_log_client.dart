import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/utils/secured_api_utils.dart';

/// SSE 기반 서버 로그 스트리밍 클라이언트
class ServerLogClient {
  static String get _endpoint => '${AppUrls.baseUrl}/api/app/debug/log-stream';
  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const int _maxBufferSize = 1000;

  final List<CapturedLog> _buffer = [];
  final StreamController<CapturedLog> _controller = StreamController<CapturedLog>.broadcast();

  http.Client? _httpClient;
  StreamSubscription<String>? _sseSubscription;
  bool _isConnected = false;
  bool _shouldReconnect = false;
  Timer? _reconnectTimer;

  /// 현재 버퍼의 로그 목록
  List<CapturedLog> get logs => List.unmodifiable(_buffer);

  /// 실시간 로그 스트림
  Stream<CapturedLog> get stream => _controller.stream;

  /// 연결 상태
  bool get isConnected => _isConnected;

  /// SSE 연결 시작
  Future<void> connect() async {
    _shouldReconnect = true;
    await _doConnect();
  }

  Future<void> _doConnect() async {
    disconnect(permanent: false);

    try {
      final headers = SecuredApiUtils.generateHeaders();
      headers['Accept'] = 'text/event-stream';
      headers['Cache-Control'] = 'no-cache';

      final request = http.Request('GET', Uri.parse(_endpoint));
      request.headers.addAll(headers);

      _httpClient = http.Client();
      final response = await _httpClient!.send(request);

      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        _addSystemLog('[서버 로그] 연결 실패: ${response.statusCode} $body');
        _scheduleReconnect();
        return;
      }

      _isConnected = true;
      _addSystemLog('[서버 로그] 연결 성공');

      _sseSubscription = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            _onSseLine,
            onError: (error) {
              _addSystemLog('[서버 로그] 스트림 에러: $error');
              _isConnected = false;
              _scheduleReconnect();
            },
            onDone: () {
              _addSystemLog('[서버 로그] 연결 종료');
              _isConnected = false;
              _scheduleReconnect();
            },
          );
    } catch (e) {
      _addSystemLog('[서버 로그] 연결 실패: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  String _sseDataBuffer = '';

  void _onSseLine(String line) {
    if (line.startsWith('data:')) {
      _sseDataBuffer = line.substring(5).trim();
    } else if (line.isEmpty && _sseDataBuffer.isNotEmpty) {
      _parseAndAddLog(_sseDataBuffer);
      _sseDataBuffer = '';
    }
  }

  void _parseAndAddLog(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final level = json['level'] as String? ?? '';
      final loggerName = json['loggerName'] as String? ?? '';
      final message = json['message'] as String? ?? '';
      final threadName = json['threadName'] as String? ?? '';
      final timestamp = json['timestamp'] as String? ?? '';

      final displayMessage = '[$level] $loggerName ($threadName): $message';
      DateTime time;
      try {
        time = DateTime.parse(timestamp);
      } catch (_) {
        time = DateTime.now();
      }

      _addLog(CapturedLog(time: time, message: displayMessage));
    } catch (e) {
      debugPrint('[ServerLogClient] JSON 파싱 실패: $e');
    }
  }

  void _addLog(CapturedLog log) {
    if (_buffer.length >= _maxBufferSize) {
      _buffer.removeAt(0);
    }
    _buffer.add(log);
    _controller.add(log);
  }

  void _addSystemLog(String message) {
    _addLog(CapturedLog(time: DateTime.now(), message: message));
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_shouldReconnect) _doConnect();
    });
  }

  /// 버퍼 비우기
  void clear() {
    _buffer.clear();
  }

  /// 연결 종료
  void disconnect({bool permanent = true}) {
    if (permanent) _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _sseSubscription?.cancel();
    _sseSubscription = null;
    _httpClient?.close();
    _httpClient = null;
    _isConnected = false;
    _sseDataBuffer = '';
  }
}
