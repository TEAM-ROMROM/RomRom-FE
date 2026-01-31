// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_room_detail_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomDetailDto _$ChatRoomDetailDtoFromJson(Map<String, dynamic> json) => ChatRoomDetailDto(
  chatRoomId: json['chatRoomId'] as String?,
  targetMember: json['targetMember'] == null ? null : Member.fromJson(json['targetMember'] as Map<String, dynamic>),
  targetMemberEupMyeonDong: json['targetMemberEupMyeonDong'] as String?,
  lastMessageContent: json['lastMessageContent'] as String?,
  lastMessageTime: ChatRoomDetailDto._fromIsoString(json['lastMessageTime']),
  unreadCount: (json['unreadCount'] as num?)?.toInt(),
  chatRoomType: $enumDecodeNullable(_$ChatRoomTypeEnumMap, json['chatRoomType']),
);

Map<String, dynamic> _$ChatRoomDetailDtoToJson(ChatRoomDetailDto instance) => <String, dynamic>{
  'chatRoomId': instance.chatRoomId,
  'targetMember': instance.targetMember?.toJson(),
  'targetMemberEupMyeonDong': instance.targetMemberEupMyeonDong,
  'lastMessageContent': instance.lastMessageContent,
  'lastMessageTime': ChatRoomDetailDto._toIsoString(instance.lastMessageTime),
  'unreadCount': instance.unreadCount,
  'chatRoomType': _$ChatRoomTypeEnumMap[instance.chatRoomType],
};

const _$ChatRoomTypeEnumMap = {ChatRoomType.requested: 'REQUESTED', ChatRoomType.received: 'RECEIVED'};
