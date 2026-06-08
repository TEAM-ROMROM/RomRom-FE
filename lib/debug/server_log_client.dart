import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/debug/log_capture.dart';
import 'package:romrom_fe/debug/runtime_url_manager.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/utils/secured_api_utils.dart';

/// WebSocket 기반 서버 로그 스트리밍 클라이언트
///
/// BE가 기존 SSE(/api/app/debug/log-stream)를 WebSocket(/ws/debug-logs)으로 전환하여
/// 리버스 프록시(시놀로지 nginx)의 SSE 단절 문제를 우회한다.
/// 인증은 핸드셰이크 단계에서 HMAC 서명(X-Timestamp/X-Signature)으로 처리한다 — 로그인 불필요.
class ServerLogClient {
  /// baseUrl(http/https)을 WebSocket 스킴(ws/wss)으로 변환한 디버그 로그 엔드포인트
  static String get _endpoint {
    final base = AppUrls.baseUrl;
    final wsBase = base.replaceFirst(RegExp(r'^http'), 'ws'); // http→ws, https→wss
    return '$wsBase/ws/debug-logs';
  }

  static const Duration _reconnectDelay = Duration(seconds: 3);
  static const Duration _reconnectDelayOnCapacityExceeded = Duration(seconds: 15);
  static const int _maxBufferSize = 1000;

  final List<CapturedLog> _buffer = [];
  final StreamController<CapturedLog> _controller = StreamController<CapturedLog>.broadcast();

  WebSocket? _webSocket;
  StreamSubscription<dynamic>? _socketSubscription;
  bool _isConnected = false;
  bool _shouldReconnect = false;
  Timer? _reconnectTimer;
  // AOP 상세 로그(@LogMonitor 등) 수신 토글 — 재연결 시 서버에 다시 통보하기 위해 기억
  bool _aopEnabled = false;

  /// AOP 상세 로그 토글 상태
  bool get isAopEnabled => _aopEnabled;

  void _onUrlChanged(String _) {
    if (_shouldReconnect) {
      _addSystemLog('[서버 로그] URL 변경 감지 — 재연결 중...');
      _doConnect();
    }
  }

  /// 현재 버퍼의 로그 목록
  List<CapturedLog> get logs => List.unmodifiable(_buffer);

  /// 실시간 로그 스트림
  Stream<CapturedLog> get stream => _controller.stream;

  /// 연결 상태
  bool get isConnected => _isConnected;

  /// WebSocket 연결 시작
  Future<void> connect() async {
    _shouldReconnect = true;
    RuntimeUrlManager().addUrlChangeListener(_onUrlChanged);
    await _doConnect();
  }

  Future<void> _doConnect() async {
    disconnect(permanent: false);

    try {
      // 핸드셰이크 헤더에 HMAC 서명 첨부 (BE HmacLogHandshakeInterceptor가 검증)
      final headers = SecuredApiUtils.generateHeaders();

      final socket = await WebSocket.connect(_endpoint, headers: headers);
      _webSocket = socket;
      _isConnected = true;
      _addSystemLog('[서버 로그] 연결 성공');

      // 재연결 시 이전 AOP 토글 상태를 서버에 다시 통보 (서버는 세션별 상태라 새 세션은 기본 OFF)
      if (_aopEnabled) {
        _sendAopToggle(true);
      }

      // onDone에서 멤버 필드(_webSocket) 대신 이 연결의 socket을 직접 참조한다.
      // 빠른 재연결로 _webSocket이 새 소켓으로 교체된 뒤 늦게 실행되는 onDone이
      // 엉뚱한 소켓의 closeCode를 읽는 레이스를 방지한다.
      _socketSubscription = socket.listen(
        _onSocketMessage,
        onError: (error) {
          _addSystemLog('[서버 로그] 스트림 에러: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          // 서버가 닫은 코드로 구독자 초과(정책 위반) 여부 판별
          final closeCode = socket.closeCode;
          _isConnected = false;
          if (closeCode == WebSocketStatus.policyViolation) {
            // 최대 동시 접속 수 초과 — 슬롯이 해제될 때까지 더 길게 대기 후 재시도
            _addSystemLog('[서버 로그] 구독자 수 초과 — ${_reconnectDelayOnCapacityExceeded.inSeconds}초 후 재시도');
            _scheduleReconnect(delay: _reconnectDelayOnCapacityExceeded);
          } else {
            _addSystemLog('[서버 로그] 연결 종료');
            _scheduleReconnect();
          }
        },
      );
    } on WebSocketException catch (e) {
      // 핸드셰이크 거부(인증 실패 등) 포함
      _addSystemLog('[서버 로그] 연결 실패: ${e.message}');
      _isConnected = false;
      _scheduleReconnect();
    } catch (e) {
      _addSystemLog('[서버 로그] 연결 실패: $e');
      _isConnected = false;
      _scheduleReconnect();
    }
  }

  /// WebSocket 텍스트 메시지 수신 — BE가 JSON 한 건씩 텍스트 프레임으로 전송
  void _onSocketMessage(dynamic message) {
    if (message is! String) return;

    // 연결 직후 BE가 보내는 connected 알림은 시스템 로그로만 표시
    // (형식: {"level":"INFO","message":"connected"})
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      if (json['message'] == 'connected' && json['loggerName'] == null) {
        _addSystemLog('[서버 로그] 서버 연결 확인됨');
        return;
      }
    } catch (_) {
      // JSON이 아니면 아래 파싱에서 처리
    }
    _parseAndAddLog(message);
  }

  void _parseAndAddLog(String jsonStr) {
    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      final level = json['level'] as String? ?? '';
      final loggerName = json['loggerName'] as String? ?? '';
      final message = json['message'] as String? ?? '';
      final threadName = json['threadName'] as String? ?? '';
      final timestamp = json['timestamp'] as String? ?? '';
      final isAop = json['source'] == 'AOP';

      // AOP 상세 로그는 마커(⟫)로 일반 로그와 구분
      final prefix = isAop ? '⟫ ' : '';
      final displayMessage = '$prefix[$level] $loggerName ($threadName): $message';
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

  void _scheduleReconnect({Duration? delay}) {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay ?? _reconnectDelay, () {
      if (_shouldReconnect) _doConnect();
    });
  }

  /// 백그라운드 진입 시 연결 일시 중단 (슬롯 반환)
  void suspend() {
    disconnect(permanent: false);
    _addSystemLog('[서버 로그] 백그라운드 전환 — 연결 중단');
  }

  /// 포그라운드 복귀 시 연결 재개
  void resume() {
    if (_shouldReconnect) {
      _addSystemLog('[서버 로그] 포그라운드 복귀 — 재연결 중...');
      _doConnect();
    }
  }

  /// AOP 상세 로그(@LogMonitor 등) 수신 토글.
  /// 상태를 기억하고 서버에 통보한다 (연결 안 된 경우 다음 연결 성공 시 재전송).
  void setAopEnabled(bool enabled) {
    _aopEnabled = enabled;
    _sendAopToggle(enabled);
    _addSystemLog('[서버 로그] AOP 상세 로그 ${enabled ? "ON" : "OFF"}');
  }

  /// 현재 WebSocket으로 토글 명령 전송
  void _sendAopToggle(bool enabled) {
    final socket = _webSocket;
    if (socket != null && _isConnected) {
      socket.add(jsonEncode({'action': 'toggleAop', 'enabled': enabled}));
    }
  }

  /// 버퍼 비우기
  void clear() {
    _buffer.clear();
  }

  /// 연결 종료
  void disconnect({bool permanent = true}) {
    if (permanent) {
      _shouldReconnect = false;
      RuntimeUrlManager().removeUrlChangeListener(_onUrlChanged);
    }
    _reconnectTimer?.cancel();
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _webSocket?.close();
    _webSocket = null;
    _isConnected = false;
  }
}
