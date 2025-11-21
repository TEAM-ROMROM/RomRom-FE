import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// STOMP + WebSocket 서비스 (stomp_dart_client 사용)
class ChatWebSocketService {
  static final ChatWebSocketService _instance =
      ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal();

  StompClient? _stompClient;
  bool _isConnected = false;
  final Map<String, StreamController<ChatMessage>> _subscriptions = {};
  final Map<String, StompUnsubscribe> _stompSubscriptions = {};
  
  // 구독 참조 카운팅 (여러 화면에서 같은 채팅방을 구독할 수 있도록)
  final Map<String, int> _subscriptionRefCounts = {};
  
  // 사용자 전체 메시지 구독 (채팅방 목록 업데이트용)
  StreamController<ChatMessage>? _userMessagesController;
  StompUnsubscribe? _userMessagesSubscription;
  
  final TokenManager _tokenManager = TokenManager();

  /// 연결 상태 확인
  bool get isConnected => _isConnected;

  ///  STOMP 연결
  Future<void> connect() async {
    if (_isConnected) {
      debugPrint('[WebSocket] Already connected');
      return;
    }

    try {
      debugPrint('[WebSocket] Starting connection...');

      // 1. JWT 토큰 가져오기
      final accessToken = await _tokenManager.getAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // 2. 엔드포인트 URL 생성
      // 🔧 TEST: HTTP로 시도 (stomp_dart_client의 HTTPS URL 파싱 버그 우회)
      const wsUrl = 'wss://api.romrom.xyz/chat';
      debugPrint('[WebSocket] ========================================');
      debugPrint('[WebSocket] 연결 시도 시작 (HTTP 테스트)');
      debugPrint('[WebSocket] AppUrls.baseUrl: ${AppUrls.baseUrl}');
      debugPrint('[WebSocket] wsUrl: $wsUrl');
      debugPrint(
        '[WebSocket] Access Token: ${accessToken.substring(0, 20)}...',
      );
      debugPrint('[WebSocket] ========================================');

      // 3. StompClient 생성
      _stompClient = StompClient(
        config: StompConfig(
          url: wsUrl,
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onStompError,
          onWebSocketError: _onWebSocketError,
          stompConnectHeaders: {'Authorization': 'Bearer $accessToken'},
          webSocketConnectHeaders: {'Authorization': 'Bearer $accessToken'},
          reconnectDelay: const Duration(seconds: 2),
          heartbeatIncoming: const Duration(seconds: 10),
          heartbeatOutgoing: const Duration(seconds: 10),
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
    // 사용자 전체 메시지 구독도 재연결
    if (_userMessagesController != null) {
      _subscribeToUserMessages();
    }
  }

  /// 채팅방 구독
  Stream<ChatMessage> subscribeToChatRoom(String chatRoomId) {
    // 참조 카운트 증가
    _subscriptionRefCounts[chatRoomId] = (_subscriptionRefCounts[chatRoomId] ?? 0) + 1;
    debugPrint('[WebSocket] Subscribe to $chatRoomId (refCount: ${_subscriptionRefCounts[chatRoomId]})');

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
      debugPrint(
        '[WebSocket] Not connected yet, will subscribe when connected',
      );
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

          // 1) STOMP 헤더 timestamp(ms) → DateTime
          DateTime? headerTs;
          final tsHdr = frame.headers['timestamp'];
          if (tsHdr != null) {
            final ms = int.tryParse(tsHdr);
            if (ms != null) {
              headerTs = DateTime.fromMillisecondsSinceEpoch(
                ms,
                isUtc: true,
              ).toLocal();
            }
          }

          // 2) 페이로드 시간 파싱(createdDate/clientSentAt)
          DateTime? payloadTs;
          final createdDate = jsonBody['createdDate'];
          if (createdDate is int) {
            payloadTs = DateTime.fromMillisecondsSinceEpoch(
              createdDate,
              isUtc: true,
            ).toLocal();
          } else if (createdDate is String) {
            final parsed = DateTime.tryParse(createdDate);
            if (parsed != null) payloadTs = parsed.toLocal();
          } else if (jsonBody['clientSentAt'] is int) {
            payloadTs = DateTime.fromMillisecondsSinceEpoch(
              jsonBody['clientSentAt'],
              isUtc: true,
            ).toLocal();
          }

          // 3) 최종 시간 확정: 헤더 → 페이로드 → 지금
          final finalCreated = headerTs ?? payloadTs ?? DateTime.now();

          // 모델로 변환
          final message = ChatMessage.fromJson(
            jsonBody,
          ).copyWith(createdDate: finalCreated);

          _subscriptions[chatRoomId]?.add(message);
        } catch (e) {
          debugPrint('[WebSocket] Failed to parse message: $e');
        }
      },
    );

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

    final now = DateTime.now()
        .toUtc()
        .millisecondsSinceEpoch; // epoch ms (UTC 권장)

    final payload = jsonEncode({
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last.toUpperCase(),
      'clientSentAt': now,
    });

    debugPrint('[WebSocket] Sending message to /app/chat.send');
    _stompClient!.send(
      destination: '/app/chat.send',
      body: payload,
      headers: {'content-type': 'application/json'},
    );
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(String chatRoomId) {
    try {
      // 참조 카운트 감소
      final currentCount = _subscriptionRefCounts[chatRoomId] ?? 0;
      if (currentCount <= 0) {
        debugPrint('[WebSocket] Already unsubscribed from $chatRoomId');
        return;
      }

      _subscriptionRefCounts[chatRoomId] = currentCount - 1;
      final newCount = _subscriptionRefCounts[chatRoomId]!;
      debugPrint('[WebSocket] Unsubscribe from $chatRoomId (refCount: $newCount)');

      // 참조 카운트가 0이 되면 실제로 구독 해제
      if (newCount <= 0) {
        _subscriptionRefCounts.remove(chatRoomId);

        // STOMP 구독 해제
        _stompSubscriptions[chatRoomId]?.call();
        _stompSubscriptions.remove(chatRoomId);

        // 스트림 컨트롤러 닫기
        _subscriptions[chatRoomId]?.close();
        _subscriptions.remove(chatRoomId);

        debugPrint('[WebSocket] ✅ Fully unsubscribed from $chatRoomId');
      } else {
        debugPrint('[WebSocket] Still $newCount active subscription(s) for $chatRoomId');
      }
    } catch (e) {
      debugPrint('[WebSocket] Unsubscribe error: $e');
    }
  }

  /// 사용자 전체 메시지 구독 (채팅방 목록 실시간 업데이트용)
  /// 모든 채팅방의 메시지를 받을 수 있음
  Stream<ChatMessage> subscribeToUserMessages(String userId) {
    // 이미 구독 중이면 기존 스트림 반환
    if (_userMessagesController != null) {
      return _userMessagesController!.stream;
    }

    // 새 스트림 컨트롤러 생성
    _userMessagesController = StreamController<ChatMessage>.broadcast();

    // 연결 상태 확인 후 구독
    if (_isConnected) {
      _subscribeToUserMessages();
    } else {
      debugPrint(
        '[WebSocket] Not connected yet, will subscribe to user messages when connected',
      );
    }

    return _userMessagesController!.stream;
  }

  /// 실제 사용자 전체 메시지 구독 실행
  void _subscribeToUserMessages() {
    if (_stompClient == null || !_isConnected || _userMessagesController == null) {
      debugPrint('[WebSocket] Cannot subscribe to user messages: not connected or no controller');
      return;
    }

    // TODO: 백엔드 엔드포인트 확인 필요
    // 예상: /sub/chat.user.{userId} 또는 /sub/chat.user.{userId}/messages
    // 현재는 userId를 가져올 수 없으므로, 일단 채팅방별 구독을 활용하는 방식으로 구현
    // 또는 백엔드에서 사용자별 전체 메시지 구독 엔드포인트를 제공하는 경우 사용
    debugPrint('[WebSocket] ⚠️ User messages subscription not implemented yet');
    debugPrint('[WebSocket] Using per-room subscriptions for now');
    
    // 백엔드에서 사용자 전체 메시지 구독을 지원한다면 아래 주석을 해제하고 수정
    /*
    final destination = '/sub/chat.user.$userId';
    debugPrint('[WebSocket] ✅ Subscribing to user messages: $destination');

    _userMessagesSubscription = _stompClient!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        if (frame.body == null) return;

        try {
          final jsonBody = jsonDecode(frame.body!);

          // 시간 파싱 (채팅방 구독과 동일한 로직)
          DateTime? headerTs;
          final tsHdr = frame.headers['timestamp'];
          if (tsHdr != null) {
            final ms = int.tryParse(tsHdr);
            if (ms != null) {
              headerTs = DateTime.fromMillisecondsSinceEpoch(
                ms,
                isUtc: true,
              ).toLocal();
            }
          }

          DateTime? payloadTs;
          final createdDate = jsonBody['createdDate'];
          if (createdDate is int) {
            payloadTs = DateTime.fromMillisecondsSinceEpoch(
              createdDate,
              isUtc: true,
            ).toLocal();
          } else if (createdDate is String) {
            final parsed = DateTime.tryParse(createdDate);
            if (parsed != null) payloadTs = parsed.toLocal();
          } else if (jsonBody['clientSentAt'] is int) {
            payloadTs = DateTime.fromMillisecondsSinceEpoch(
              jsonBody['clientSentAt'],
              isUtc: true,
            ).toLocal();
          }

          final finalCreated = headerTs ?? payloadTs ?? DateTime.now();

          final message = ChatMessage.fromJson(jsonBody).copyWith(createdDate: finalCreated);
          _userMessagesController?.add(message);
        } catch (e) {
          debugPrint('[WebSocket] Failed to parse user message: $e');
        }
      },
    );
    */
  }

  /// 사용자 전체 메시지 구독 해제
  void unsubscribeFromUserMessages() {
    try {
      _userMessagesSubscription?.call();
      _userMessagesSubscription = null;
      _userMessagesController?.close();
      _userMessagesController = null;
      debugPrint('[WebSocket] Unsubscribed from user messages');
    } catch (e) {
      debugPrint('[WebSocket] Unsubscribe user messages error: $e');
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

      // 사용자 전체 메시지 구독 해제
      unsubscribeFromUserMessages();

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

extension ChatMessageCopy on ChatMessage {
  ChatMessage copyWith({
    String? chatMessageId,
    String? chatRoomId,
    String? senderId,
    String? content,
    DateTime? createdDate,
  }) => ChatMessage(
    chatMessageId: chatMessageId ?? this.chatMessageId,
    chatRoomId: chatRoomId ?? this.chatRoomId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    createdDate: createdDate ?? this.createdDate,
  );
}
