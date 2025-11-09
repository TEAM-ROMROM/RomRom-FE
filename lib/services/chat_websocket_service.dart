import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// STOMP + SockJS WebSocket 서비스 (stomp_dart_client 사용)
class ChatWebSocketService {
  static final ChatWebSocketService _instance =
      ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  final Map<String, StreamController<ChatMessage>> _subscriptions = {};
  final Map<String, StompUnsubscribe> _stompSubscriptions = {};
  final TokenManager _tokenManager = TokenManager();

  /// 연결 상태 확인
  bool get isConnected => _isConnected;

  /// SockJS + STOMP 연결
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

      // 2. SockJS 엔드포인트 URL 생성
      // 🔧 TEST: HTTP로 시도 (stomp_dart_client의 HTTPS URL 파싱 버그 우회)
      const wsUrl = 'http://api.romrom.xyz/chat';
      debugPrint('[WebSocket] ========================================');
      debugPrint('[WebSocket] 연결 시도 시작 (HTTP 테스트)');
      debugPrint('[WebSocket] AppUrls.baseUrl: ${AppUrls.baseUrl}');
      debugPrint('[WebSocket] wsUrl: $wsUrl');
      debugPrint('[WebSocket] Access Token: ${accessToken.substring(0, 20)}...');
      debugPrint('[WebSocket] ========================================');

      // 3. StompClient 생성 (SockJS 자동 처리)
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onStompError,
          onWebSocketError: _onWebSocketError,
          stompConnectHeaders: {
            'Authorization': 'Bearer $accessToken',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      debugPrint('[WebSocket] StompClient 생성 완료');

      // 4. 연결 활성화
      _stompClient!.activate();
    } catch (e, stackTrace) {
      debugPrint('[WebSocket] ❌ Connection failed: $e');
      debugPrint('[WebSocket] Stack trace: $stackTrace');
      _isConnected = false;
      _stompClient = null;
      rethrow;
    }
  }

  /// STOMP 연결 성공 콜백
  void _onConnect(StompFrame frame) {
    debugPrint('[WebSocket] ✅ STOMP Connected');
    debugPrint('[WebSocket] Frame: ${frame.headers}');
    _isConnected = true;

    // 기존 구독 재연결
    _resubscribeAll();
  }

  /// 연결 해제 콜백
  void _onDisconnect(StompFrame frame) {
    debugPrint('[WebSocket] Disconnected');
    debugPrint('[WebSocket] Frame: ${frame.headers}');
    _isConnected = false;
  }

  /// STOMP 에러 콜백
  void _onStompError(StompFrame frame) {
    debugPrint('[WebSocket] ❌ STOMP Error');
    debugPrint('[WebSocket] Headers: ${frame.headers}');
    debugPrint('[WebSocket] Body: ${frame.body}');
  }

  /// WebSocket 에러 콜백
  void _onWebSocketError(dynamic error) {
    debugPrint('[WebSocket] ❌ WebSocket Error: $error');
    _isConnected = false;
  }

  /// 기존 구독 재연결
  void _resubscribeAll() {
    for (var chatRoomId in _subscriptions.keys) {
      _subscribeToRoom(chatRoomId);
    }
  }

  /// 채팅방 구독
  Stream<ChatMessage> subscribeToChatRoom(String chatRoomId) {
    // 이미 구독 중이면 기존 스트림 반환
    if (_subscriptions.containsKey(chatRoomId)) {
      return _subscriptions[chatRoomId]!.stream;
    }

    // 새 스트림 컨트롤러 생성
    final controller = StreamController<ChatMessage>.broadcast();
    _subscriptions[chatRoomId] = controller;

    // 연결 상태 확인 후 구독
    if (_isConnected) {
      _subscribeToRoom(chatRoomId);
    } else {
      debugPrint('[WebSocket] Not connected yet, will subscribe when connected');
    }

    return controller.stream;
  }

  /// 실제 채팅방 구독 실행
  void _subscribeToRoom(String chatRoomId) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('[WebSocket] Cannot subscribe: not connected');
      return;
    }

    final destination = '/sub/chat.room.$chatRoomId';
    debugPrint('[WebSocket] ✅ Subscribing to: $destination');

    final unsubscribe = _stompClient!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body == null) return;

        try {
          final jsonBody = jsonDecode(frame.body!);
          final message = ChatMessage.fromJson(jsonBody);

          // 해당 채팅방 스트림에 메시지 전달
          _subscriptions[chatRoomId]?.add(message);
        } catch (e) {
          debugPrint('[WebSocket] Failed to parse message: $e');
        }
      },
    );

    // 구독 해제 함수 저장
    _stompSubscriptions[chatRoomId] = unsubscribe;
  }

  /// 메시지 전송
  void sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
  }) {
    if (!_isConnected || _stompClient == null) {
      debugPrint('[WebSocket] Cannot send message: Not connected');
      throw Exception('STOMP not connected');
    }

    final payload = jsonEncode({
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last.toUpperCase(),
    });

    debugPrint('[WebSocket] Sending message to /app/chat.send');
    _stompClient!.send(
      destination: '/app/chat.send',
      body: payload,
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(String chatRoomId) {
    try {
      // STOMP 구독 해제
      _stompSubscriptions[chatRoomId]?.call();
      _stompSubscriptions.remove(chatRoomId);

      // 스트림 컨트롤러 닫기
      _subscriptions[chatRoomId]?.close();
      _subscriptions.remove(chatRoomId);

      debugPrint('[WebSocket] Unsubscribed from $chatRoomId');
    } catch (e) {
      debugPrint('[WebSocket] Unsubscribe error: $e');
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    if (!_isConnected && _stompClient == null) return;

    try {
      debugPrint('[WebSocket] Disconnecting...');

      // StompClient 비활성화
      _stompClient?.deactivate();
      _isConnected = false;
      _stompClient = null;

      // 모든 STOMP 구독 해제
      for (var unsubscribe in _stompSubscriptions.values) {
        unsubscribe();
      }
      _stompSubscriptions.clear();

      // 모든 스트림 컨트롤러 닫기
      for (var controller in _subscriptions.values) {
        await controller.close();
      }
      _subscriptions.clear();

      debugPrint('[WebSocket] ✅ Disconnected');
    } catch (e) {
      debugPrint('[WebSocket] Disconnect error: $e');
    }
  }
}
