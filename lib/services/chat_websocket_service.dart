import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/services/token_manager.dart';

/// SockJS + STOMP WebSocket 서비스 (수동 구현)
class ChatWebSocketService {
  static final ChatWebSocketService _instance =
      ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  WebSocket? _socket;
  bool _isConnected = false;
  final Map<String, StreamController<ChatMessage>> _subscriptions = {};
  final TokenManager _tokenManager = TokenManager();

  // STOMP 프레임 ID 생성
  int _messageIdCounter = 0;
  String _generateId() => 'msg-${_messageIdCounter++}';

  /// 연결 상태 확인
  bool get isConnected => _isConnected;

  /// SockJS 연결 및 STOMP 연결
  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }

    try {
      debugPrint('[WebSocket] Starting SockJS connection...');

      // 1. JWT 토큰 가져오기
      final accessToken = await _tokenManager.getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // 2. SockJS WebSocket URL 생성
      final serverId = _generateServerId();
      final sessionId = _generateSessionId();

      // URI 생성 (wss:// 스킴 사용)
      final uri = Uri.parse(AppUrls.baseUrl).replace(
        scheme: 'wss',
        path: '/chat/$serverId/$sessionId/websocket',
      );

      debugPrint('[WebSocket] Connecting to: $uri');

      // 3. HttpClient를 사용하여 WebSocket 업그레이드 직접 처리
      final httpClient = HttpClient();
      try {
        final request = await httpClient.openUrl('GET', uri).timeout(
          const Duration(seconds: 10),
          onTimeout: () => throw TimeoutException('Connection timeout'),
        );

        // WebSocket 업그레이드 헤더 설정
        request.headers.set('Connection', 'Upgrade');
        request.headers.set('Upgrade', 'websocket');
        request.headers.set('Sec-WebSocket-Version', '13');
        request.headers.set('Sec-WebSocket-Key',
            _generateWebSocketKey()); // WebSocket 키 생성
        request.headers.set('Authorization', 'Bearer $accessToken');

        final response = await request.close();

        if (response.statusCode != 101) {
          throw WebSocketException(
              'WebSocket upgrade failed: ${response.statusCode}');
        }

        _socket = await response.detachSocket()
            .then((socket) => WebSocket.fromUpgradedSocket(
                  socket,
                  serverSide: false,
                ));

        debugPrint('[WebSocket] ✅ WebSocket connected');
      } finally {
        httpClient.close(force: false);
      }

      // 4. 연결 완료 대기를 위한 Completer
      final connectionCompleter = Completer<void>();
      var connectionTimeout = Timer(const Duration(seconds: 5), () {
        if (!connectionCompleter.isCompleted) {
          connectionCompleter.completeError('SockJS handshake timeout');
        }
      });

      // 5. WebSocket 메시지 리스너 설정
      _socket!.listen(
        (dynamic message) {
          final msg = message.toString();

          // SockJS open frame 수신 시 연결 성공으로 간주
          if (msg.startsWith('o')) {
            if (!connectionCompleter.isCompleted) {
              connectionCompleter.complete();
              connectionTimeout.cancel();
            }
          }

          _handleMessage(msg);
        },
        onError: (error) {
          debugPrint('[WebSocket] Stream error: $error');
          _isConnected = false;
          if (!connectionCompleter.isCompleted) {
            connectionCompleter.completeError(error);
            connectionTimeout.cancel();
          }
        },
        onDone: () {
          debugPrint('[WebSocket] Stream closed');
          _isConnected = false;
        },
      );

      // 6. SockJS handshake 대기
      await connectionCompleter.future;
      debugPrint('[WebSocket] ✅ SockJS handshake complete');

      // 7. STOMP CONNECT 전송
      final connectFrame = '''CONNECT
accept-version:1.1,1.0
heart-beat:10000,10000
Authorization:Bearer $accessToken

\x00''';

      debugPrint('[WebSocket] Sending STOMP CONNECT frame');
      _socket!.add(connectFrame);

      // STOMP CONNECTED 응답은 _processStompFrame에서 처리
      debugPrint('[WebSocket] Waiting for STOMP CONNECTED...');
    } catch (e, stackTrace) {
      debugPrint('[WebSocket] ❌ Connection failed: $e');
      debugPrint('[WebSocket] Stack trace: $stackTrace');
      _isConnected = false;
      _socket = null;
      rethrow;
    }
  }

  /// 메시지 수신 처리
  void _handleMessage(String rawMessage) {
    debugPrint('[WebSocket] Received: $rawMessage');

    // SockJS 프레임 처리 (o, h, a 등)
    if (rawMessage.startsWith('o')) {
      debugPrint('[WebSocket] SockJS open frame received');
      return;
    }
    if (rawMessage.startsWith('h')) {
      debugPrint('[WebSocket] SockJS heartbeat received');
      return;
    }
    if (rawMessage.startsWith('a')) {
      // SockJS 데이터 프레임 - JSON 배열 형태
      final jsonData = rawMessage.substring(1); // 'a' 제거
      try {
        final List<dynamic> frames = jsonDecode(jsonData);
        for (var frame in frames) {
          _processStompFrame(frame.toString());
        }
      } catch (e) {
        debugPrint('[WebSocket] Failed to parse SockJS frame: $e');
      }
      return;
    }

    // 일반 STOMP 프레임 처리
    _processStompFrame(rawMessage);
  }

  /// STOMP 프레임 처리
  void _processStompFrame(String frame) {
    if (frame.startsWith('CONNECTED')) {
      debugPrint('[WebSocket] ✅ STOMP CONNECTED');
      _isConnected = true;
      return;
    }

    if (frame.startsWith('MESSAGE')) {
      // STOMP MESSAGE 프레임 파싱
      final lines = frame.split('\n');
      String? destination;
      String? body;

      bool isBody = false;
      final bodyLines = <String>[];

      for (var line in lines) {
        if (line.startsWith('destination:')) {
          destination = line.substring('destination:'.length);
        } else if (line.isEmpty && !isBody) {
          isBody = true;
        } else if (isBody && line != '\x00') {
          bodyLines.add(line);
        }
      }

      body = bodyLines.join('\n');

      if (destination != null && body.isNotEmpty) {
        try {
          final jsonBody = jsonDecode(body);
          final message = ChatMessage.fromJson(jsonBody);

          // 구독 중인 채팅방에 메시지 전달
          for (var entry in _subscriptions.entries) {
            if (destination.contains(entry.key)) {
              entry.value.add(message);
            }
          }
        } catch (e) {
          debugPrint('[WebSocket] Failed to parse message body: $e');
        }
      }
    }
  }

  /// 채팅방 구독
  Stream<ChatMessage> subscribeToChatRoom(String chatRoomId) {
    if (_subscriptions.containsKey(chatRoomId)) {
      return _subscriptions[chatRoomId]!.stream;
    }

    final controller = StreamController<ChatMessage>.broadcast();
    _subscriptions[chatRoomId] = controller;

    // 연결 상태 확인 후 구독
    _subscribeWhenReady(chatRoomId);

    return controller.stream;
  }

  /// 연결 준비 시 구독 실행
  Future<void> _subscribeWhenReady(String chatRoomId) async {
    // 최대 10초 대기
    for (var i = 0; i < 20; i++) {
      if (_isConnected && _socket != null) {
        final subscribeFrame = '''SUBSCRIBE
id:sub-$chatRoomId
destination:/sub/chat.room.$chatRoomId

\x00''';

        debugPrint('[WebSocket] ✅ Subscribing to: /sub/chat.room.$chatRoomId');
        _socket!.add(subscribeFrame);
        return;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }

    debugPrint('[WebSocket] ⚠️ Failed to subscribe: not connected after 10s');
  }

  /// 메시지 전송
  void sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
  }) {
    if (!_isConnected) {
      debugPrint('[WebSocket] Cannot send message: Not connected');
      throw Exception('STOMP not connected');
    }

    final messageId = _generateId();
    final payload = jsonEncode({
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last.toUpperCase(),
    });

    final sendFrame = '''SEND
destination:/app/chat.send
content-type:application/json
content-length:${payload.length}

$payload\x00''';

    debugPrint('[WebSocket] Sending message (id: $messageId)');
    _socket!.add(sendFrame);
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(String chatRoomId) {
    try {
      if (_subscriptions.containsKey(chatRoomId)) {
        final unsubscribeFrame = '''UNSUBSCRIBE
id:sub-$chatRoomId

\x00''';
        _socket?.add(unsubscribeFrame);

        _subscriptions[chatRoomId]?.close();
        _subscriptions.remove(chatRoomId);
        debugPrint('[WebSocket] Unsubscribed from $chatRoomId');
      }
    } catch (e) {
      debugPrint('[WebSocket] Unsubscribe error: $e');
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    if (!_isConnected) return;

    try {
      debugPrint('[WebSocket] Disconnecting...');

      const disconnectFrame = '''DISCONNECT
receipt:disconnect-1

\x00''';

      _socket?.add(disconnectFrame);
      await Future.delayed(const Duration(milliseconds: 500));
      await _socket?.close();

      _isConnected = false;
      _socket = null;

      // 모든 구독 스트림 닫기
      for (var controller in _subscriptions.values) {
        await controller.close();
      }
      _subscriptions.clear();

      debugPrint('[WebSocket] ✅ Disconnected');
    } catch (e) {
      debugPrint('[WebSocket] Disconnect error: $e');
    }
  }

  /// SockJS 서버 ID 생성 (000-999)
  String _generateServerId() {
    final random = Random();
    return random.nextInt(1000).toString().padLeft(3, '0');
  }

  /// SockJS 세션 ID 생성
  String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }

  /// WebSocket 핸드셰이크 키 생성 (Base64 인코딩된 16바이트 난수)
  String _generateWebSocketKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }
}
