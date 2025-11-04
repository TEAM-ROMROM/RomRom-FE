// lib/models/apis/responses/chat_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';

part 'chat_response.g.dart';

/// 채팅방 응답 DTO
@JsonSerializable(explicitToJson: true)
class ChatRoomResponse {
  final ChatRoom? chatRoom; // 단일 채팅방
  final PagedChatMessage? messages; // 메시지 페이지
  final PagedChatRoom? chatRooms; // 채팅방 목록 페이지

  ChatRoomResponse({
    this.chatRoom,
    this.messages,
    this.chatRooms,
  });

  factory ChatRoomResponse.fromJson(Map<String, dynamic> json) =>
      _$ChatRoomResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ChatRoomResponseToJson(this);
}

/// Paged<ChatMessage>
@JsonSerializable(explicitToJson: true)
class PagedChatMessage {
  @JsonKey(fromJson: _chatMessageListFromJson, toJson: _chatMessageListToJson)
  final List<ChatMessage> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedChatMessage({
    required this.content,
    this.page,
  });

  factory PagedChatMessage.fromJson(Map<String, dynamic> json) =>
      _$PagedChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$PagedChatMessageToJson(this);
}

/// Paged<ChatRoom>
@JsonSerializable(explicitToJson: true)
class PagedChatRoom {
  @JsonKey(fromJson: _chatRoomListFromJson, toJson: _chatRoomListToJson)
  final List<ChatRoom> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedChatRoom({
    required this.content,
    this.page,
  });

  factory PagedChatRoom.fromJson(Map<String, dynamic> json) =>
      _$PagedChatRoomFromJson(json);
  Map<String, dynamic> toJson() => _$PagedChatRoomToJson(this);
}

// ---------- converters ----------

List<ChatMessage> _chatMessageListFromJson(Object? value) {
  if (value is List) {
    return value.map((e) => ChatMessage.fromJson(e)).toList();
  }
  return [];
}

List<Object?> _chatMessageListToJson(List<ChatMessage> messages) {
  return messages.map((e) => e.toJson()).toList();
}

List<ChatRoom> _chatRoomListFromJson(Object? value) {
  if (value is List) {
    return value.map((e) => ChatRoom.fromJson(e)).toList();
  }
  return [];
}

List<Object?> _chatRoomListToJson(List<ChatRoom> chatRooms) {
  return chatRooms.map((e) => e.toJson()).toList();
}
