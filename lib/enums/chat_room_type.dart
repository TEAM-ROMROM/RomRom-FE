import 'package:json_annotation/json_annotation.dart';

enum ChatRoomType {
  @JsonValue('REQUESTED')
  requested, // 내가 요청을 보낸 채팅방 (본인이 Sender)

  @JsonValue('RECEIVED')
  received, // 내가 요청을 받은 채팅방 (본인이 Receiver)
}

extension ChatRoomTypeExtension on ChatRoomType {
  String get serverName {
    switch (this) {
      case ChatRoomType.requested:
        return 'REQUESTED';
      case ChatRoomType.received:
        return 'RECEIVED';
    }
  }

  String get label {
    switch (this) {
      case ChatRoomType.requested:
        return '요청함';
      case ChatRoomType.received:
        return '받은 요청';
    }
  }

  static ChatRoomType fromServerName(String name) {
    return ChatRoomType.values.firstWhere((e) => e.serverName == name, orElse: () => ChatRoomType.requested);
  }
}
