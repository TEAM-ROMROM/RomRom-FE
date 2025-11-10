// lib/models/apis/objects/chat_message.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'chat_message.g.dart';

/// 채팅 메시지 타입 (백엔드 MessageType Enum)
enum MessageType {
  @JsonValue('TEXT')
  text,
  @JsonValue('IMAGE')
  image,
  @JsonValue('SYSTEM')
  system,
}

/// 채팅 메시지 모델 (MongoDB)
@JsonSerializable()
class ChatMessage extends BaseEntity {
  final String? chatMessageId; // MongoDB ObjectId
  final String? chatRoomId; // UUID
  final String? senderId; // UUID
  final String? recipientId; // UUID
  final String? content;
  final MessageType? type;

  ChatMessage({
    super.createdDate,
    super.updatedDate,
    this.chatMessageId,
    this.chatRoomId,
    this.senderId,
    this.recipientId,
    this.content,
    this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}
