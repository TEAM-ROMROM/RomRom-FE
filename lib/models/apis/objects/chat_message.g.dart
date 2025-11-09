// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  createdDate: json['createdDate'] == null
      ? null
      : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null
      ? null
      : DateTime.parse(json['updatedDate'] as String),
  chatMessageId: json['chatMessageId'] as String?,
  chatRoomId: json['chatRoomId'] as String?,
  senderId: json['senderId'] as String?,
  recipientId: json['recipientId'] as String?,
  content: json['content'] as String?,
  type: $enumDecodeNullable(_$MessageTypeEnumMap, json['type']),
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'createdDate': instance.createdDate?.toIso8601String(),
      'updatedDate': instance.updatedDate?.toIso8601String(),
      'chatMessageId': instance.chatMessageId,
      'chatRoomId': instance.chatRoomId,
      'senderId': instance.senderId,
      'recipientId': instance.recipientId,
      'content': instance.content,
      'type': _$MessageTypeEnumMap[instance.type],
    };

const _$MessageTypeEnumMap = {
  MessageType.text: 'TEXT',
  MessageType.image: 'IMAGE',
  MessageType.system: 'SYSTEM',
};
