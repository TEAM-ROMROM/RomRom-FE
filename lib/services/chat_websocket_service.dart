import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/models/user_info.dart';
import 'package:romrom_fe/services/apis/rom_auth_api.dart';
import 'package:romrom_fe/services/chat_message_frame_parser.dart';
import 'package:romrom_fe/services/chat_room_topic_registries.dart';
import 'package:romrom_fe/services/token_manager.dart';
import 'package:romrom_fe/utils/single_flight.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// STOMP + WebSocket 서비스 (stomp_dart_client 사용)
/// 연결은 회원 단위: 연결한 회원과 현재 회원이 다르면(로그아웃 후 다른 계정) 이전 연결·구독 정리 후 새로 연결
class ChatWebSocketService {
  static final ChatWebSocketService _instance = ChatWebSocketService._internal();
  factory ChatWebSocketService() => _instance;
  ChatWebSocketService._internal({
    Future<String?> Function()? readAccessToken,
    Future<String?> Function()? readCurrentMemberId,
    Future<bool> Function()? refreshAccessToken,
    StompClient Function(StompConfig config)? createStompClient,
  }) : _readAccessToken = readAccessToken ?? TokenManager().getAccessToken,
       _readCurrentMemberId = readCurrentMemberId ?? UserInfo().getCurrentMemberId,
       _refreshAccessToken = refreshAccessToken ?? RomAuthApi().refreshAccessToken,
       _createStompClient = createStompClient ?? ((config) => StompClient(config: config));

  /// 테스트용: 토큰·회원 ID 읽기, 토큰 재발급, STOMP 클라이언트 생성을 교체한 독립 인스턴스
  @visibleForTesting
  factory ChatWebSocketService.forTesting({
    required Future<String?> Function() readAccessToken,
    required Future<String?> Function() readCurrentMemberId,
    required Future<bool> Function() refreshAccessToken,
    required StompClient Function(StompConfig config) createStompClient,
  }) => ChatWebSocketService._internal(
    readAccessToken: readAccessToken,
    readCurrentMemberId: readCurrentMemberId,
    refreshAccessToken: refreshAccessToken,
    createStompClient: createStompClient,
  );

  final Future<String?> Function() _readAccessToken;
  final Future<String?> Function() _readCurrentMemberId;
  final Future<bool> Function() _refreshAccessToken;
  final StompClient Function(StompConfig config) _createStompClient;

  StompClient? _stompClient;
  // STOMP 연결 상태 원본 (값이 바뀔 때만 구독자 알림 > 채팅방 '연결 중' 표시)
  final ValueNotifier<bool> _connectionStatus = ValueNotifier<bool>(false);
  bool get _isConnected => _connectionStatus.value;
  set _isConnected(bool isConnected) => _connectionStatus.value = isConnected;
  final Map<String, StreamController<ChatMessage>> _subscriptions = {};
  final Map<String, StompUnsubscribe> _stompSubscriptions = {};

  // 구독 참조 카운팅 (여러 화면에서 같은 채팅방을 구독할 수 있도록)
  final Map<String, int> _subscriptionRefCounts = {};

  // 채팅방 부가 토픽 구독: 읽음, AI 추천, 메시지 변경
  final ChatRoomTopicRegistries _topicRegistries = ChatRoomTopicRegistries();

  // 토큰 갱신 중 중복 실행 방지
  bool _isRefreshingToken = false;

  // 최초 연결 이후 재연결 여부 판단 (true면 _onConnect가 재연결로 간주)
  bool _hasConnectedBefore = false;

  // 재연결 시 화면이 메시지 재동기화를 트리거하도록 알리는 브로드캐스트 스트림
  final StreamController<void> _reconnectController = StreamController<void>.broadcast();

  /// 재연결 이벤트 스트림. 화면은 이를 구독해 getChatMessages 재조회를 수행한다.
  Stream<void> get onReconnected => _reconnectController.stream;

  // 현재 연결(또는 연결 시도)을 만든 회원 ID
  String? _connectedMemberId;

  // 연결 세대 (새 StompClient마다 증가) > 정리된 이전 클라이언트의 늦은 콜백 무시
  int _connectionGeneration = 0;

  // 동시 connect 호출은 같은 연결 시도 공유 (채팅 탭·채팅방 동시 진입 시 중복 클라이언트 방지)
  final SingleFlight<void> _connectFlight = SingleFlight<void>();

  // 다음 CONNECTED 대기 (waitUntilConnected 호출부, 연결 시 전부 완료)
  final List<Completer<void>> _connectionWaiters = [];

  /// 연결 상태 확인
  bool get isConnected => _isConnected;

  /// 연결 상태 변화 구독 (true 연결, false 끊김·재연결 대기)
  ValueListenable<bool> get connectionStatus => _connectionStatus;

  /// STOMP 연결 완료 대기 (이미 연결이면 즉시 완료, 연결 해제(disconnect) 시 대기 폐기)
  Future<void> waitUntilConnected() {
    if (_isConnected) return Future<void>.value();
    final waiter = Completer<void>();
    _connectionWaiters.add(waiter);
    return waiter.future;
  }

  ///  STOMP 연결 (진행 중이면 같은 시도 공유)
  Future<void> connect() => _connectFlight.run(_connectForCurrentMember);

  /// 다른 회원 연결 정리 > 기존 연결 있으면 유지 > 없으면 새 연결
  Future<void> _connectForCurrentMember() async {
    final currentMemberId = await _readCurrentMemberId();
    // 연결 여부와 무관 (토큰 재발급 실패로 클라이언트만 비워진 경우도 이전 회원 구독 정리)
    final previousMemberId = _connectedMemberId;
    if (previousMemberId != null && previousMemberId != currentMemberId) {
      debugPrint('[WebSocket] Member changed > reset previous connection');
      await disconnect();
    }

    // _stompClient != null 이면 이미 연결 중이거나 재연결 대기 중
    // 이 경우 새 StompClient를 생성하면 중복 세션 문제가 발생하므로 early return
    if (_isConnected || _stompClient != null) {
      debugPrint('[WebSocket] Already connected or connecting');
      return;
    }

    try {
      debugPrint('[WebSocket] Starting connection...');

      // 1. JWT 토큰 가져오기
      final accessToken = await _readAccessToken();
      if (accessToken == null) {
        throw Exception('Access token not found');
      }

      // 2. 엔드포인트 URL 생성 (AppUrls.baseUrl 기준: https > wss, 디버그 URL 변경 반영)
      final wsUrl = AppUrls.chatWebSocketUrl;
      debugPrint('[WebSocket] 연결 시도: $wsUrl');

      // 3. StompClient 생성 (콜백은 이 연결 세대일 때만 처리)
      final connectionGeneration = ++_connectionGeneration;
      bool isCurrentConnection() => connectionGeneration == _connectionGeneration;
      _connectedMemberId = currentMemberId;
      _stompClient = _createStompClient(
        StompConfig(
          url: wsUrl,
          onConnect: (frame) {
            if (isCurrentConnection()) _onConnect(frame);
          },
          onDisconnect: (frame) {
            if (isCurrentConnection()) _onDisconnect(frame);
          },
          onStompError: (frame) {
            if (isCurrentConnection()) _onStompError(frame);
          },
          onWebSocketError: (error) {
            if (isCurrentConnection()) _onWebSocketError(error);
          },
          // 오류 없이 닫힌 소켓 (망 전환·앱 복귀·서버 재배포): onDisconnect는 직접 끊을 때만 호출됨
          onWebSocketDone: () {
            if (isCurrentConnection()) _onWebSocketDone();
          },
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
    _completeConnectionWaiters();

    // 최초 연결이 아니라면(= 재연결) 화면에 재동기화 신호를 보낸다.
    // 단절 구간에 브로드캐스트되어 유실된 메시지를 REST 재조회로 복구하기 위함.
    if (_hasConnectedBefore) {
      debugPrint('[WebSocket] 🔁 재연결 감지 → onReconnected 방송');
      if (!_reconnectController.isClosed) {
        _reconnectController.add(null);
      }
    }
    _hasConnectedBefore = true;
  }

  /// 연결 대기 전부 완료 (구독 재연결 이후)
  void _completeConnectionWaiters() {
    final waiters = [..._connectionWaiters];
    _connectionWaiters.clear();
    for (final waiter in waiters) {
      if (!waiter.isCompleted) waiter.complete();
    }
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
    // STOMP 에러 수신 즉시 연결 상태를 false로 설정
    // _onDisconnect 보다 먼저 처리하여 에러 발생 후 메시지 전송 시도를 차단
    _isConnected = false;
    // 토큰 만료로 인한 인증 오류일 수 있으므로 재발급 후 재연결 시도
    _refreshTokenAndReconnect();
  }

  /// WebSocket 에러 콜백
  void _onWebSocketError(dynamic error) {
    debugPrint('[WebSocket] ❌ WebSocket Error: $error');
    _isConnected = false;
  }

  /// 소켓 닫힘 콜백: 미연결 표시 (재연결은 StompClient가 reconnectDelay 후 시도 > CONNECTED 시 재구독)
  void _onWebSocketDone() {
    debugPrint('[WebSocket] socket closed > waiting for auto reconnect');
    _isConnected = false;
  }

  /// 토큰 재발급 후 WebSocket 재연결
  Future<void> _refreshTokenAndReconnect() async {
    if (_isRefreshingToken) return;
    _isRefreshingToken = true;

    try {
      debugPrint('[WebSocket] 토큰 재발급 시도...');

      // auto-reconnect가 구 토큰으로 재시도하지 않도록 먼저 비활성화 (이전 세대 콜백 무시)
      _connectionGeneration++;
      _stompClient?.deactivate();
      _stompClient = null;
      _isConnected = false;

      final success = await _refreshAccessToken();
      if (success) {
        debugPrint('[WebSocket] 토큰 재발급 성공 - WebSocket 재연결');
        await connect();
      } else {
        debugPrint('[WebSocket] 토큰 재발급 실패 (refresh 토큰 만료)');
      }
    } catch (e) {
      debugPrint('[WebSocket] 토큰 재발급 및 재연결 실패: $e');
    } finally {
      _isRefreshingToken = false;
    }
  }

  /// 기존 구독 재연결
  void _resubscribeAll() {
    for (var chatRoomId in _subscriptions.keys) {
      _subscribeToRoom(chatRoomId);
    }
    final stompClient = _stompClient;
    if (stompClient != null) _topicRegistries.resubscribeAll(stompClient);
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
      debugPrint('[WebSocket] Not connected yet, will subscribe when connected');
    }

    return controller.stream;
  }

  /// 읽음 이벤트 구독 (/sub/chat.read.{chatRoomId})
  Stream<ChatUserState> subscribeToReadEvents(String chatRoomId) =>
      _topicRegistries.readEvents.subscribe(chatRoomId, stompClient: _stompClient, isConnected: _isConnected);

  /// 읽음 이벤트 구독 해제
  void unsubscribeFromReadEvents(String chatRoomId) => _topicRegistries.readEvents.unsubscribe(chatRoomId);

  /// AI 행동 추천 구독 (/user/queue/chat.recommend.{chatRoomId}, 현재 사용자 전용)
  Stream<ChatActionRecommendation> subscribeToRecommendations(String chatRoomId) =>
      _topicRegistries.recommendations.subscribe(chatRoomId, stompClient: _stompClient, isConnected: _isConnected);

  /// AI 행동 추천 구독 해제
  void unsubscribeFromRecommendations(String chatRoomId) => _topicRegistries.recommendations.unsubscribe(chatRoomId);

  /// 메시지 변경 구독 (/sub/chat.update.{chatRoomId}: 삭제·약속 상태 변경본)
  Stream<ChatMessage> subscribeToMessageUpdates(String chatRoomId) =>
      _topicRegistries.messageUpdates.subscribe(chatRoomId, stompClient: _stompClient, isConnected: _isConnected);

  /// 메시지 변경 구독 해제
  void unsubscribeFromMessageUpdates(String chatRoomId) => _topicRegistries.messageUpdates.unsubscribe(chatRoomId);

  /// 실제 채팅방 구독 실행
  void _subscribeToRoom(String chatRoomId) {
    if (_stompClient == null || !_isConnected) {
      debugPrint('[WebSocket] Cannot subscribe: not connected');
      return;
    }

    final destination = '/sub/chat.room.$chatRoomId';
    debugPrint('[WebSocket] ✅ Subscribing to: $destination');

    try {
      _stompSubscriptions[chatRoomId] = _subscribeRoomOnStomp(chatRoomId, destination);
    } catch (error) {
      // 닫힌 소켓 감지 전 구독 (StompBadStateException) > 미연결 표시, 스트림 유지 > 재연결 시 재구독
      debugPrint('[WebSocket] subscribe failed, retry on reconnect : $error');
      _isConnected = false;
    }
  }

  /// STOMP 채팅방 구독 요청 + 프레임 > 메시지 변환 콜백
  StompUnsubscribe _subscribeRoomOnStomp(String chatRoomId, String destination) {
    return _stompClient!.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        final message = decodeChatRoomMessageFrame(frame, destination: destination);
        if (message == null) return;
        _subscriptions[chatRoomId]?.add(message);
        debugPrint('[WebSocket]   → StreamController 전달 완료');
      },
    );
  }

  /// 메시지 전송
  void sendMessage({
    required String chatRoomId,
    required String content,
    MessageType type = MessageType.text,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
  }) {
    if (type == MessageType.image && (imageUrls == null || imageUrls.isEmpty)) {
      throw Exception('imageUrls is required for image messages');
    }
    if (type == MessageType.location && (latitude == null || longitude == null)) {
      throw Exception('latitude and longitude are required for location messages');
    }
    if (!_isConnected || _stompClient == null) {
      debugPrint('[WebSocket] Cannot send message: Not connected');
      throw Exception('STOMP not connected');
    }

    final Map<String, dynamic> payload = {
      'chatRoomId': chatRoomId,
      'content': content,
      'type': type.toString().split('.').last.toUpperCase(),
    };

    if (type == MessageType.image && imageUrls != null) {
      payload['imageUrls'] = imageUrls;
    }

    if (type == MessageType.location) {
      payload['latitude'] = latitude;
      payload['longitude'] = longitude;
    }

    debugPrint('[WebSocket] Sending message to /app/chat.send\n$payload');
    try {
      _stompClient!.send(
        destination: '/app/chat.send',
        body: jsonEncode(payload),
        headers: {'content-type': 'application/json'},
      );
    } on StompBadStateException catch (error) {
      // 닫힌 소켓 감지 전 전송 > 미연결 표시 (호출부는 전송 실패 처리)
      debugPrint('[WebSocket] send failed, socket closed : $error');
      _isConnected = false;
      throw Exception('STOMP not connected');
    }
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

  /// 연결 해제: 클라이언트·구독·스트림·참조 카운트·연결 대기·재연결 판정 전부 초기화 (다음 connect는 최초 연결)
  /// 첫 await 전에 상태·목록을 비움 > 정리 도중 새로 들어온 구독은 닫지 않고 다음 연결 때 구독
  Future<void> disconnect() async {
    debugPrint('[WebSocket] Disconnecting...');

    // 동기 구간: 클라이언트 비활성화 (이전 세대 콜백 무시), 상태 초기화, 정리 대상 목록 복사 후 비움
    _connectionGeneration++;
    try {
      _stompClient?.deactivate();
    } catch (e) {
      debugPrint('[WebSocket] Deactivate error: $e');
    }
    _isConnected = false;
    _stompClient = null;
    _connectedMemberId = null;
    _hasConnectedBefore = false;
    _connectionWaiters.clear();
    _subscriptionRefCounts.clear();
    final stompUnsubscribes = _stompSubscriptions.values.toList();
    _stompSubscriptions.clear();
    final roomControllers = _subscriptions.values.toList();
    _subscriptions.clear();

    // STOMP 구독 해제 (건별 실패 무시)
    for (final unsubscribe in stompUnsubscribes) {
      try {
        unsubscribe();
      } catch (e) {
        debugPrint('[WebSocket] Unsubscribe error: $e');
      }
    }

    // 읽음·추천·메시지 변경 구독, 채팅방 스트림 닫기
    await _topicRegistries.closeAll();
    for (final controller in roomControllers) {
      await controller.close();
    }
    debugPrint('[WebSocket] ✅ Disconnected');
  }
}
