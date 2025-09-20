# RomRom 채팅 기능 구현 가이드

## 📋 개요

RomRom 앱의 1:1 채팅 기능 구현을 위한 종합 가이드입니다. 백엔드는 이미 완전히 구현되어 있으며, 프론트엔드(Flutter) 구현만 필요합니다.

## 🏗️ 백엔드 아키텍처 분석

### WebSocket + STOMP + RabbitMQ 구조
```
클라이언트 ←→ Spring WebSocket ←→ RabbitMQ STOMP Broker ←→ MongoDB (메시지 저장)
                    ↕
               PostgreSQL (채팅방 정보)
```

### 핵심 엔드포인트

#### REST API 엔드포인트
| 엔드포인트 | 메서드 | 설명 | Request | Response |
|-----------|--------|------|---------|----------|
| `/api/chat/rooms/create` | POST | 1:1 채팅방 생성 | ChatRoomRequest | ChatRoomResponse |
| `/api/chat/rooms/get` | POST | 본인 채팅방 목록 조회 | ChatRoomRequest | ChatRoomResponse |
| `/api/chat/rooms/delete` | POST | 채팅방 삭제 | ChatRoomRequest | Void |
| `/api/chat/rooms/messages/get` | POST | 메시지 히스토리 조회 | ChatRoomRequest | ChatRoomResponse |

#### WebSocket 엔드포인트
| 목적 | 경로 | 설명 |
|------|------|------|
| 연결 | `/ws-stomp` | WebSocket 연결 엔드포인트 |
| 메시지 전송 | `/app/chat.send` | 메시지 전송 |
| 메시지 구독 | `/exchange/chat.exchange/chat.room.{roomId}` | 특정 채팅방 메시지 구독 |

## 📊 데이터 모델 구조

### 1. ChatRoomRequest (백엔드)
```java
public class ChatRoomRequest {
    private Member member;                 // 인증된 사용자 (자동 설정)
    private UUID opponentMemberId;         // 대화 상대 ID
    private UUID chatRoomId;               // 채팅방 ID
    private UUID tradeRequestHistoryId;    // 거래 요청 ID (채팅방 생성 시)
    private int pageNumber = 0;            // 페이징
    private int pageSize = 30;             // 페이징
    private SortType sortType = CREATED_DATE;
    private Sort.Direction sortDirection = DESC;
}
```

### 2. ChatRoomResponse (백엔드)
```java
public class ChatRoomResponse {
    private ChatRoom chatRoom;             // 단일 채팅방 정보
    private Page<ChatMessage> messages;    // 메시지 목록 (페이징)
    private Page<ChatRoom> chatRooms;      // 채팅방 목록 (페이징)
}
```

### 3. ChatMessageRequest (백엔드)
```java
public class ChatMessageRequest {
    private UUID chatRoomId;     // 채팅방 ID
    private String content;      // 메시지 내용
    private MessageType type;    // TEXT, IMAGE, SYSTEM
}
```

### 4. ChatMessageResponse (백엔드)
```java
public class ChatMessageResponse {
    private UUID chatRoomId;     // 채팅방 ID
    private UUID senderId;       // 발신자 ID
    private UUID recipientId;    // 수신자 ID
    private String content;      // 메시지 내용
    private MessageType type;    // TEXT, IMAGE, SYSTEM
}
```

### 5. ChatRoom Entity (백엔드)
```java
@Entity
public class ChatRoom extends BasePostgresEntity {
    private UUID chatRoomId;
    private Member tradeReceiver;          // 거래 요청을 받은 사람
    private Member tradeSender;            // 거래 요청을 보낸 사람
    private TradeRequestHistory tradeRequestHistory;  // 연관된 거래 요청
}
```

### 6. ChatMessage Entity (백엔드)
```java
@Document  // MongoDB
public class ChatMessage extends BaseMongoEntity {
    private String chatMessageId;
    private UUID chatRoomId;
    private UUID senderId;
    private UUID recipientId;
    private String content;
    private MessageType type;  // TEXT, IMAGE, SYSTEM
}
```

## 🎯 프론트엔드 구현 가이드

### 1. 필요한 의존성 추가

#### pubspec.yaml
```yaml
dependencies:
  web_socket_channel: ^2.4.0
  stomp_dart_client: ^1.0.0
  json_annotation: ^4.8.1
  
dev_dependencies:
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
```

### 2. 데이터 모델 생성

#### lib/models/apis/requests/chat_room_request.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'chat_room_request.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatRoomRequest {
  final Member? member;
  final String? opponentMemberId;
  final String? chatRoomId;
  final String? tradeRequestHistoryId;
  final int pageNumber;
  final int pageSize;
  final String? sortType;
  final String? sortDirection;

  ChatRoomRequest({
    this.member,
    this.opponentMemberId,
    this.chatRoomId,
    this.tradeRequestHistoryId,
    this.pageNumber = 0,
    this.pageSize = 30,
    this.sortType = 'CREATED_DATE',
    this.sortDirection = 'DESC',
  });

  factory ChatRoomRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomRequestToJson(this);
}
```

#### lib/models/apis/responses/chat_room_response.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';

part 'chat_room_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatRoomResponse {
  final ChatRoom? chatRoom;
  final PagedChatMessage? messages;
  final PagedChatRoom? chatRooms;

  ChatRoomResponse({
    this.chatRoom,
    this.messages,
    this.chatRooms,
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PagedChatMessage {
  final List<ChatMessage> content;
  final ApiPage page;

  PagedChatMessage({required this.content, required this.page});

  factory PagedChatMessage.fromJson(Map<String, dynamic> json) =>
      _$PagedChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$PagedChatMessageToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PagedChatRoom {
  final List<ChatRoom> content;
  final ApiPage page;

  PagedChatRoom({required this.content, required this.page});

  factory PagedChatRoom.fromJson(Map<String, dynamic> json) =>
      _$PagedChatRoomFromJson(json);
  Map<String, dynamic> toJson() => _$PagedChatRoomToJson(this);
}
```

#### lib/models/apis/objects/chat_room.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'chat_room.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatRoom extends BaseEntity {
  final String chatRoomId;
  final Member tradeReceiver;
  final Member tradeSender;
  // TradeRequestHistory는 필요 시 추가

  ChatRoom({
    required this.chatRoomId,
    required this.tradeReceiver,
    required this.tradeSender,
    super.createdDate,
    super.updatedDate,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatRoomToJson(this);
}
```

#### lib/models/apis/objects/chat_message.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'chat_message.g.dart';

enum MessageType { TEXT, IMAGE, SYSTEM }

@JsonSerializable(explicitToJson: true)
class ChatMessage extends BaseEntity {
  final String chatMessageId;
  final String chatRoomId;
  final String senderId;
  final String recipientId;
  final String content;
  final MessageType type;

  ChatMessage({
    required this.chatMessageId,
    required this.chatRoomId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.type,
    super.createdDate,
    super.updatedDate,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
```

#### lib/models/apis/requests/chat_message_request.dart
```dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';

part 'chat_message_request.g.dart';

@JsonSerializable(explicitToJson: true)
class ChatMessageRequest {
  final String chatRoomId;
  final String content;
  final MessageType type;

  ChatMessageRequest({
    required this.chatRoomId,
    required this.content,
    required this.type,
  });

  factory ChatMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageRequestToJson(this);
}
```

### 3. API 서비스 구현

#### lib/services/apis/chat_api.dart
```dart
import 'package:dio/dio.dart';
import 'package:romrom_fe/models/apis/requests/chat_room_request.dart';
import 'package:romrom_fe/models/apis/responses/chat_room_response.dart';

class ChatApi {
  final Dio _dio;

  ChatApi(this._dio);

  /// 1:1 채팅방 생성
  Future<ChatRoomResponse> createChatRoom({
    required String opponentMemberId,
    required String tradeRequestHistoryId,
  }) async {
    final formData = FormData.fromMap({
      'opponentMemberId': opponentMemberId,
      'tradeRequestHistoryId': tradeRequestHistoryId,
    });

    final response = await _dio.post(
      '/api/chat/rooms/create',
      data: formData,
    );

    return ChatRoomResponse.fromJson(response.data);
  }

  /// 본인 채팅방 목록 조회
  Future<ChatRoomResponse> getChatRooms({
    int pageNumber = 0,
    int pageSize = 30,
  }) async {
    final formData = FormData.fromMap({
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });

    final response = await _dio.post(
      '/api/chat/rooms/get',
      data: formData,
    );

    return ChatRoomResponse.fromJson(response.data);
  }

  /// 채팅방 삭제
  Future<void> deleteChatRoom(String chatRoomId) async {
    final formData = FormData.fromMap({
      'chatRoomId': chatRoomId,
    });

    await _dio.post(
      '/api/chat/rooms/delete',
      data: formData,
    );
  }

  /// 메시지 히스토리 조회
  Future<ChatRoomResponse> getChatMessages({
    required String chatRoomId,
    int pageNumber = 0,
    int pageSize = 30,
  }) async {
    final formData = FormData.fromMap({
      'chatRoomId': chatRoomId,
      'pageNumber': pageNumber,
      'pageSize': pageSize,
    });

    final response = await _dio.post(
      '/api/chat/rooms/messages/get',
      data: formData,
    );

    return ChatRoomResponse.fromJson(response.data);
  }
}
```

### 4. WebSocket 서비스 구현

#### lib/services/chat_websocket_service.dart
```dart
import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:romrom_fe/models/apis/requests/chat_message_request.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';

class ChatWebSocketService {
  StompClient? _stompClient;
  String? _accessToken;
  
  // 메시지 수신 콜백
  Function(ChatMessage)? onMessageReceived;
  Function()? onConnected;
  Function(String)? onError;

  /// WebSocket 연결
  Future<void> connect(String accessToken) async {
    _accessToken = accessToken;
    
    _stompClient = StompClient(
      config: StompConfig(
        url: 'ws://your-backend-url/ws-stomp',
        onConnect: (frame) {
          print('Connected to WebSocket');
          onConnected?.call();
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket error: $error');
          onError?.call(error.toString());
        },
        stompConnectHeaders: {
          'Authorization': 'Bearer $_accessToken',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $_accessToken',
        },
      ),
    );

    _stompClient!.activate();
  }

  /// 특정 채팅방 구독
  void subscribeToChatRoom(String chatRoomId) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('WebSocket not connected');
      return;
    }

    _stompClient!.subscribe(
      destination: '/exchange/chat.exchange/chat.room.$chatRoomId',
      callback: (frame) {
        if (frame.body != null) {
          try {
            final messageData = jsonDecode(frame.body!);
            final message = ChatMessage.fromJson(messageData);
            onMessageReceived?.call(message);
          } catch (e) {
            print('Error parsing message: $e');
          }
        }
      },
    );
  }

  /// 메시지 전송
  void sendMessage(ChatMessageRequest request) {
    if (_stompClient == null || !_stompClient!.connected) {
      print('WebSocket not connected');
      return;
    }

    _stompClient!.send(
      destination: '/app/chat.send',
      body: jsonEncode(request.toJson()),
    );
  }

  /// 채팅방 구독 해제
  void unsubscribeFromChatRoom(String chatRoomId) {
    // STOMP 구독 해제 로직
  }

  /// WebSocket 연결 해제
  void disconnect() {
    _stompClient?.deactivate();
    _stompClient = null;
  }

  /// 연결 상태 확인
  bool get isConnected => _stompClient?.connected ?? false;
}
```

### 5. 채팅 화면 구현

#### lib/screens/chat_list_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/widgets/common/custom_app_bar.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatApi _chatApi = ChatApi(/* dio instance */);
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    try {
      final response = await _chatApi.getChatRooms();
      setState(() {
        _chatRooms = response.chatRooms?.content ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading chat rooms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: '채팅'),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _chatRooms.length,
              itemBuilder: (context, index) {
                final chatRoom = _chatRooms[index];
                return ChatRoomTile(
                  chatRoom: chatRoom,
                  onTap: () => _openChatRoom(chatRoom),
                );
              },
            ),
    );
  }

  void _openChatRoom(ChatRoom chatRoom) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(chatRoom: chatRoom),
      ),
    );
  }
}

class ChatRoomTile extends StatelessWidget {
  final ChatRoom chatRoom;
  final VoidCallback onTap;

  const ChatRoomTile({
    Key? key,
    required this.chatRoom,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        // 상대방 프로필 이미지
      ),
      title: Text(
        // 상대방 닉네임
        _getOpponentName(),
      ),
      subtitle: Text(
        // 마지막 메시지 (추가 구현 필요)
        '마지막 메시지...',
      ),
      trailing: Text(
        // 마지막 메시지 시간 (추가 구현 필요)
        '오후 2:30',
      ),
      onTap: onTap,
    );
  }

  String _getOpponentName() {
    // 현재 사용자와 상대방 구분 로직 필요
    return 'Opponent Name';
  }
}
```

#### lib/screens/chat_screen.dart
```dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/requests/chat_message_request.dart';
import 'package:romrom_fe/services/apis/chat_api.dart';
import 'package:romrom_fe/services/chat_websocket_service.dart';

class ChatScreen extends StatefulWidget {
  final ChatRoom chatRoom;

  const ChatScreen({Key? key, required this.chatRoom}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatApi _chatApi = ChatApi(/* dio instance */);
  final ChatWebSocketService _webSocketService = ChatWebSocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // WebSocket 연결
    _webSocketService.onMessageReceived = (message) {
      setState(() {
        _messages.insert(0, message);
      });
      _scrollToBottom();
    };

    _webSocketService.onConnected = () {
      _webSocketService.subscribeToChatRoom(widget.chatRoom.chatRoomId);
    };

    await _webSocketService.connect('your-access-token');
    
    // 기존 메시지 로드
    await _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final response = await _chatApi.getChatMessages(
        chatRoomId: widget.chatRoom.chatRoomId,
      );
      
      setState(() {
        _messages = response.messages?.content.reversed.toList() ?? [];
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading messages: $e');
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final request = ChatMessageRequest(
      chatRoomId: widget.chatRoom.chatRoomId,
      content: content,
      type: MessageType.TEXT,
    );

    _webSocketService.sendMessage(request);
    _messageController.clear();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getOpponentName()),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessageBubble(
                        message: message,
                        isMe: _isMyMessage(message),
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  String _getOpponentName() {
    // 상대방 이름 반환 로직
    return 'Opponent Name';
  }

  bool _isMyMessage(ChatMessage message) {
    // 현재 사용자의 메시지인지 확인 로직
    return message.senderId == 'current-user-id';
  }

  @override
  void dispose() {
    _webSocketService.disconnect();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
```

## 🔧 구현 단계별 가이드

### Phase 1: 기본 설정 및 모델 생성
1. **의존성 추가** - pubspec.yaml에 WebSocket 관련 패키지 추가
2. **데이터 모델 생성** - 위에서 제공된 모든 모델 클래스 생성
3. **코드 생성** - `flutter packages pub run build_runner build` 실행

### Phase 2: API 서비스 구현
1. **ChatApi 클래스 생성** - REST API 호출 로직 구현
2. **API 클라이언트에 ChatApi 추가** - 기존 api_client.dart에 통합

### Phase 3: WebSocket 서비스 구현
1. **ChatWebSocketService 생성** - STOMP WebSocket 연결 및 메시지 처리
2. **연결 관리 로직** - 자동 재연결, 에러 핸들링 추가

### Phase 4: UI 구현
1. **채팅방 목록 화면** - ChatListScreen 구현
2. **채팅 화면** - ChatScreen 구현
3. **메시지 버블 컴포넌트** - ChatMessageBubble 구현

### Phase 5: 통합 및 테스트
1. **네비게이션 연결** - 기존 화면에서 채팅 화면으로의 연결점 추가
2. **상태 관리** - Provider 또는 Riverpod으로 채팅 상태 관리
3. **알림 기능** - FCM과 연동하여 채팅 알림 기능 추가

## 🚨 주의사항

### 1. 인증 토큰 관리
- WebSocket 연결 시 Authorization 헤더에 Bearer 토큰 필수
- 토큰 만료 시 자동 재연결 로직 필요

### 2. 메모리 관리
- WebSocket 연결은 화면을 벗어날 때 반드시 해제
- 메시지 목록이 길어질 경우 메모리 최적화 필요

### 3. 네트워크 상태 관리
- 네트워크 연결 상태 모니터링
- 오프라인 상태에서 메시지 임시 저장 기능

### 4. 백엔드 URL 설정
- 개발/프로덕션 환경에 따른 WebSocket URL 분리
- HTTPS 환경에서는 WSS 사용 필수

## 📱 사용자 경험 고려사항

### 1. 실시간 기능
- 메시지 전송 시 즉시 UI 업데이트
- 상대방 온라인 상태 표시
- 읽음 확인 기능 (추가 백엔드 작업 필요)

### 2. 성능 최적화
- 메시지 무한 스크롤 구현
- 이미지 메시지 지연 로딩
- 채팅방 목록 캐싱

### 3. 접근성
- 스크린 리더 지원
- 키보드 네비게이션
- 고대비 모드 지원

이 가이드를 따라 구현하면 백엔드와 완벽하게 연동되는 채팅 기능을 구현할 수 있습니다. 추가 질문이나 특정 부분에 대한 상세한 설명이 필요하시면 언제든 문의해주세요.