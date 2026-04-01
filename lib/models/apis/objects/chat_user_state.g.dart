// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_user_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatUserState _$ChatUserStateFromJson(Map<String, dynamic> json) => ChatUserState(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  chatUserStateId: json['chatUserStateId'] as String?,
  chatRoomId: json['chatRoomId'] as String?,
  memberId: json['memberId'] as String?,
  leftAt: json['leftAt'] == null ? null : DateTime.parse(json['leftAt'] as String),
  removedAt: json['removedAt'] == null ? null : DateTime.parse(json['removedAt'] as String),
  deleted: json['deleted'] as bool? ?? false,
  isPresent: json['isPresent'] as bool? ?? false,
);

Map<String, dynamic> _$ChatUserStateToJson(ChatUserState instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'chatUserStateId': instance.chatUserStateId,
  'chatRoomId': instance.chatRoomId,
  'memberId': instance.memberId,
  'leftAt': instance.leftAt?.toIso8601String(),
  'removedAt': instance.removedAt?.toIso8601String(),
  'deleted': instance.deleted,
  'isPresent': instance.isPresent,
};
