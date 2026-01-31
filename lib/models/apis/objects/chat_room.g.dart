// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoom _$ChatRoomFromJson(Map<String, dynamic> json) => ChatRoom(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  chatRoomId: json['chatRoomId'] as String?,
  tradeReceiver: json['tradeReceiver'] == null ? null : Member.fromJson(json['tradeReceiver'] as Map<String, dynamic>),
  tradeSender: json['tradeSender'] == null ? null : Member.fromJson(json['tradeSender'] as Map<String, dynamic>),
  tradeRequestHistory: json['tradeRequestHistory'] == null
      ? null
      : TradeRequestHistory.fromJson(json['tradeRequestHistory'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChatRoomToJson(ChatRoom instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'chatRoomId': instance.chatRoomId,
  'tradeReceiver': instance.tradeReceiver?.toJson(),
  'tradeSender': instance.tradeSender?.toJson(),
  'tradeRequestHistory': instance.tradeRequestHistory?.toJson(),
};
