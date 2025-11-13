// lib/models/apis/responses/chat_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';

part 'chat_response.g.dart';

/// 채팅방 응답 DTO
@JsonSerializable(explicitToJson: true)
class ChatRoomResponse {
  final ChatRoom? chatRoom; // 단일 채팅방
  final PagedChatMessage? messages; // 메시지 페이지
  final PagedChatRoomDetail? chatRoomDetailDtoPage; // 채팅방 목록 페이지 (detail dto)

  ChatRoomResponse({
    this.chatRoom,
    this.messages,
    this.chatRoomDetailDtoPage,
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

/// Paged<ChatRoomDetailDto>
@JsonSerializable(explicitToJson: true)
class PagedChatRoomDetail {
  @JsonKey(fromJson: _chatRoomDetailListFromJson, toJson: _chatRoomDetailListToJson)
  final List<ChatRoomDetailDto> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedChatRoomDetail({
    required this.content,
    this.page,
  });

  factory PagedChatRoomDetail.fromJson(Map<String, dynamic> json) =>
      _$PagedChatRoomDetailFromJson(json);
  Map<String, dynamic> toJson() => _$PagedChatRoomDetailToJson(this);
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

List<ChatRoomDetailDto> _chatRoomDetailListFromJson(Object? value) {
  if (value is List) {
    return value.map((e) => ChatRoomDetailDto.fromJson(e)).toList();
  }
  return [];
}

List<Object?> _chatRoomDetailListToJson(List<ChatRoomDetailDto> chatRooms) {
  return chatRooms.map((e) => e.toJson()).toList();
}
