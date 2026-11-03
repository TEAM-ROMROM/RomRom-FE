import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 테스트용 STOMP 클라이언트: 실제 소켓 없이 활성화·비활성화·구독 기록
class _FakeStompClient extends StompClient {
  _FakeStompClient(StompConfig config) : super(config: config);

  bool isActivated = false;
  bool isDeactivated = false;
  final List<String> subscribedDestinations = [];

  @override
  void activate() => isActivated = true;

  @override
  void deactivate() => isDeactivated = true;

  @override
  StompUnsubscribe subscribe({
    required String destination,
    required StompFrameCallback callback,
    Map<String, String>? headers,
  }) {
    subscribedDestinations.add(destination);
    return ({Map<String, String>? unsubscribeHeaders}) {};
  }

  /// 서버 연결 성공 흉내 (config 콜백 호출)
  void simulateConnected() => config.onConnect(StompFrame(command: 'CONNECTED'));

  /// 연결 끊김 흉내
  void simulateDisconnected() => config.onDisconnect(StompFrame(command: 'DISCONNECT'));

  /// STOMP 에러 흉내 (토큰 만료 등 > 서비스가 재발급 후 재연결)
  void simulateStompError() => config.onStompError(StompFrame(command: 'ERROR'));
}

/// 웹소켓 회원 단위 연결 검증: 같은 회원 재사용, 회원 변경 시 이전 연결·구독 정리 후 새 토큰으로 연결, 이전 클라이언트 늦은 콜백 무시
void main() {
  late String currentMemberId;
  late String currentAccessToken;
  late List<_FakeStompClient> createdClients;
  late ChatWebSocketService webSocketService;
  late bool isTokenRefreshSuccessful;

  setUp(() {
    isTokenRefreshSuccessful = true;
    currentMemberId = 'member-a';
    currentAccessToken = 'token-a';
    createdClients = [];
    webSocketService = ChatWebSocketService.forTesting(
      readAccessToken: () async => currentAccessToken,
      readCurrentMemberId: () async => currentMemberId,
      refreshAccessToken: () async => isTokenRefreshSuccessful,
      createStompClient: (config) {
        final client = _FakeStompClient(config);
        createdClients.add(client);
        return client;
      },
    );
  });

  test('같은 회원 connect 두 번 > 클라이언트 1개 유지', () async {
    await webSocketService.connect();
    createdClients.single.simulateConnected();
    await webSocketService.connect();

    expect(createdClients, hasLength(1));
    expect(createdClients.single.isActivated, isTrue);
    expect(webSocketService.isConnected, isTrue);
  });

  test('동시 connect 여러 건 > 클라이언트 1개', () async {
    await Future.wait([webSocketService.connect(), webSocketService.connect(), webSocketService.connect()]);

    expect(createdClients, hasLength(1));
  });

  test('다른 회원으로 connect > 이전 클라이언트 비활성화, 이전 구독 스트림 종료, 새 토큰으로 새 클라이언트', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    var isPreviousRoomStreamDone = false;
    webSocketService.subscribeToChatRoom('room-of-a').listen((_) {}, onDone: () => isPreviousRoomStreamDone = true);

    currentMemberId = 'member-b';
    currentAccessToken = 'token-b';
    await webSocketService.connect();
    await Future<void>.delayed(Duration.zero);

    expect(createdClients, hasLength(2));
    expect(createdClients.first.isDeactivated, isTrue);
    expect(isPreviousRoomStreamDone, isTrue);
    expect(createdClients.last.config.stompConnectHeaders?['Authorization'], 'Bearer token-b');
    expect(webSocketService.isConnected, isFalse, reason: '새 연결 CONNECTED 전');
  });

  test('회원 변경 후 이전 클라이언트의 늦은 끊김 콜백 > 새 연결 상태에 영향 없음', () async {
    await webSocketService.connect();
    final previousClient = createdClients.first..simulateConnected();

    currentMemberId = 'member-b';
    await webSocketService.connect();
    createdClients.last.simulateConnected();
    previousClient.simulateDisconnected();

    expect(webSocketService.isConnected, isTrue);
  });

  test('회원 변경 후 첫 연결 > 재연결 신호 없음, 새 회원 구독만 재구독', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    webSocketService.subscribeToChatRoom('room-of-a');
    var reconnectSignalCount = 0;
    webSocketService.onReconnected.listen((_) => reconnectSignalCount++);

    currentMemberId = 'member-b';
    await webSocketService.connect();
    webSocketService.subscribeToChatRoom('room-of-b');
    createdClients.last.simulateConnected();
    await Future<void>.delayed(Duration.zero);

    expect(reconnectSignalCount, 0);
    expect(createdClients.last.subscribedDestinations, ['/sub/chat.room.room-of-b']);
  });

  test('disconnect 후 같은 방 재구독 > 해제 1회로 완전 해제 (참조 카운트 초기화)', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    webSocketService.subscribeToChatRoom('room-1');
    await webSocketService.disconnect();

    var isRoomStreamDone = false;
    webSocketService.subscribeToChatRoom('room-1').listen((_) {}, onDone: () => isRoomStreamDone = true);
    webSocketService.unsubscribeFromChatRoom('room-1');
    await Future<void>.delayed(Duration.zero);

    expect(isRoomStreamDone, isTrue);
  });

  test('disconnect 연속 2회 (로그아웃 + 세션 종료 정리) > 오류 없음, 이후 connect는 새 클라이언트', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    webSocketService.subscribeToChatRoom('room-1');

    await webSocketService.disconnect();
    await webSocketService.disconnect();
    await webSocketService.connect();

    expect(webSocketService.isConnected, isFalse);
    expect(createdClients.length, 2);
    expect(createdClients.first.isDeactivated, isTrue);
  });

  test('토큰 재발급 실패로 클라이언트가 비워진 뒤 다른 회원 connect > 이전 회원 구독 정리', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    var isPreviousRoomStreamDone = false;
    webSocketService.subscribeToChatRoom('room-of-a').listen((_) {}, onDone: () => isPreviousRoomStreamDone = true);

    isTokenRefreshSuccessful = false;
    createdClients.first.simulateStompError();
    await pumpEventQueue();
    expect(createdClients, hasLength(1), reason: '재발급 실패 > 재연결 안 함');

    currentMemberId = 'member-b';
    await webSocketService.connect();
    createdClients.last.simulateConnected();
    await pumpEventQueue();

    expect(isPreviousRoomStreamDone, isTrue);
    expect(createdClients.last.subscribedDestinations, isEmpty, reason: '이전 회원 방 재구독 안 함');
  });

  test('토큰 재발급 성공 > 같은 회원 구독 유지한 채 새 클라이언트로 재연결', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    webSocketService.subscribeToChatRoom('room-1');

    createdClients.first.simulateStompError();
    await pumpEventQueue();
    createdClients.last.simulateConnected();

    expect(createdClients, hasLength(2));
    expect(createdClients.first.isDeactivated, isTrue);
    expect(createdClients.last.subscribedDestinations, ['/sub/chat.room.room-1']);
  });

  test('disconnect 정리 도중 새 구독 > 정리 대상에서 빠지고 다음 연결 때 구독', () async {
    await webSocketService.connect();
    createdClients.first.simulateConnected();
    webSocketService.subscribeToChatRoom('room-old').listen((_) {});
    webSocketService.subscribeToReadEvents('room-old').listen((_) {});

    final disconnecting = webSocketService.disconnect();
    var isNewRoomStreamDone = false;
    webSocketService.subscribeToChatRoom('room-new').listen((_) {}, onDone: () => isNewRoomStreamDone = true);
    await disconnecting;

    await webSocketService.connect();
    createdClients.last.simulateConnected();
    await pumpEventQueue();

    expect(isNewRoomStreamDone, isFalse);
    expect(createdClients.last.subscribedDestinations, ['/sub/chat.room.room-new']);
  });
}
