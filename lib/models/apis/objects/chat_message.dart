// lib/models/apis/objects/chat_message.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'chat_message.g.dart';

/// 채팅 메시지 모델 (MongoDB)
@JsonSerializable()
class ChatMessage extends BaseEntity {
  final String? chatMessageId; // MongoDB ObjectId
  final String? chatRoomId; // UUID
  final String? senderId; // UUID
  final String? recipientId; // UUID
  final String? content;
  final List<String>? imageUrls;
  final MessageType? type;

  ChatMessage({
    super.createdDate,
    super.updatedDate,
    this.chatMessageId,
    this.chatRoomId,
    this.senderId,
    this.recipientId,
    this.content,
    this.imageUrls,
    this.type,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

/// ChatMessage 복사 및 수정용 확장 메서드
extension ChatMessageCopy on ChatMessage {
  ChatMessage copyWith({
    String? chatMessageId,
    String? chatRoomId,
    String? senderId,
    String? recipientId,
    String? content,
    List<String>? imageUrls,
    MessageType? type,
    DateTime? createdDate,
    DateTime? updatedDate,
  }) => ChatMessage(
    chatMessageId: chatMessageId ?? this.chatMessageId,
    chatRoomId: chatRoomId ?? this.chatRoomId,
    senderId: senderId ?? this.senderId,
    recipientId: recipientId ?? this.recipientId,
    content: content ?? this.content,
    imageUrls: imageUrls ?? this.imageUrls,
    type: type ?? this.type,
    createdDate: createdDate ?? this.createdDate,
    updatedDate: updatedDate ?? this.updatedDate,
  );
}
