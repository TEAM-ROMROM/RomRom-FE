// lib/services/chat_websocket_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/token_manager.dart';

/// 채팅 WebSocket 서비스 (STOMP over WebSocket)
class ChatWebSocketService {
  // 싱글톤 구현
  static final ChatWebSocketService _instance =
      ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  final TokenManager _tokenManager = TokenManager();

  StompClient? _stompClient;
  final Map<String, StreamController<ChatMessage>> _messageControllers = {};
  final Map<String, StompUnsubscribe?> _subscriptions = {};

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// WebSocket 연결
  Future<void> connect() async {
    if (_isConnected && _stompClient != null) {
      debugPrint('WebSocket already connected');
      return;
    }

    try {
      // JWT 토큰 가져오기
      final accessToken = await _tokenManager.getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // SockJS 연결 URL (HTTPS 프로토콜 사용, SockJS가 자동으로 WebSocket 업그레이드 처리)
      const wsUrl = '${AppUrls.baseUrl}/chat';

      debugPrint('Connecting to WebSocket: $wsUrl');

      _stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: _onConnect,
          onWebSocketError: (error) {
            debugPrint('WebSocket Error: $error');
            _isConnected = false;
          },
          onStompError: (frame) {
            debugPrint('STOMP Error: ${frame.body}');
            _isConnected = false;
          },
          onDisconnect: (frame) {
            debugPrint('STOMP Disconnected');
            _isConnected = false;
          },
          // 인증 헤더 추가
          stompConnectHeaders: {
            'Authorization': 'Bearer $accessToken',
          },
          webSocketConnectHeaders: {
            'Authorization': 'Bearer $accessToken',
          },
          // 재연결 설정
          reconnectDelay: const Duration(seconds: 5),
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      _isConnected = false;
      rethrow;
    }
  }

  /// 연결 성공 콜백
  void _onConnect(StompFrame frame) {
    debugPrint('STOMP Connected successfully');
    _isConnected = true;
  }

  /// 채팅방 구독
  Stream<ChatMessage> subscribeToChatRoom(String chatRoomId) {
    final destination = '/sub/chat.room.$chatRoomId';

    // 이미 구독 중이면 기존 스트림 반환
    if (_messageControllers.containsKey(chatRoomId)) {
      debugPrint('Already subscribed to $chatRoomId');
      return _messageControllers[chatRoomId]!.stream;
    }

    // 새 스트림 컨트롤러 생성
    _messageControllers[chatRoomId] =
        StreamController<ChatMessage>.broadcast();

    if (_stompClient == null || !_isConnected) {
      debugPrint('STOMP not connected, waiting...');
      // 연결될 때까지 대기
      Future.delayed(const Duration(seconds: 1), () {
        if (_isConnected) {
          _subscribeToDestination(chatRoomId, destination);
        }
      });
    } else {
      _subscribeToDestination(chatRoomId, destination);
    }

    return _messageControllers[chatRoomId]!.stream;
  }

  /// 실제 구독 로직
  void _subscribeToDestination(String chatRoomId, String destination) {
    try {
      final unsubscribe = _stompClient?.subscribe(
        destination: destination,
        callback: (frame) {
          if (frame.body != null) {
            try {
              final Map<String, dynamic> json = jsonDecode(frame.body!);
              final message = ChatMessage.fromJson(json);
              _messageControllers[chatRoomId]?.add(message);
              debugPrint('Message received in $chatRoomId: ${message.content}');
            } catch (e) {
              debugPrint('Error parsing message: $e');
            }
          }
        },
      );

      _subscriptions[chatRoomId] = unsubscribe;
      debugPrint('Subscribed to $destination');
    } catch (e) {
      debugPrint('Subscription error: $e');
    }
  }

  /// 메시지 전송
  void sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
  }) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('Cannot send message: STOMP not connected');
      return;
    }

    const destination = '/app/chat.send';

    final messageData = {
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last.toUpperCase(),
    };

    try {
      _stompClient!.send(
        destination: destination,
        body: jsonEncode(messageData),
      );
      debugPrint('Message sent to $chatRoomId: $content');
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(String chatRoomId) {
    try {
      _subscriptions[chatRoomId]?.call();
      _subscriptions.remove(chatRoomId);

      _messageControllers[chatRoomId]?.close();
      _messageControllers.remove(chatRoomId);

      debugPrint('Unsubscribed from $chatRoomId');
    } catch (e) {
      debugPrint('Error unsubscribing: $e');
    }
  }

  /// 연결 해제
  void disconnect() {
    try {
      // 모든 구독 해제
      _subscriptions.forEach((key, unsubscribe) {
        unsubscribe?.call();
      });
      _subscriptions.clear();

      // 모든 스트림 컨트롤러 종료
      _messageControllers.forEach((key, controller) {
        controller.close();
      });
      _messageControllers.clear();

      // STOMP 연결 해제
      _stompClient?.deactivate();
      _stompClient = null;

      _isConnected = false;
      debugPrint('WebSocket disconnected');
    } catch (e) {
      debugPrint('Error disconnecting: $e');
    }
  }
}
