// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomRequest _$ChatRoomRequestFromJson(Map<String, dynamic> json) => ChatRoomRequest(
  opponentMemberId: json['opponentMemberId'] as String?,
  chatRoomId: json['chatRoomId'] as String?,
  tradeRequestHistoryId: json['tradeRequestHistoryId'] as String?,
  pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 20,
);

Map<String, dynamic> _$ChatRoomRequestToJson(ChatRoomRequest instance) => <String, dynamic>{
  'opponentMemberId': instance.opponentMemberId,
  'chatRoomId': instance.chatRoomId,
  'tradeRequestHistoryId': instance.tradeRequestHistoryId,
  'pageNumber': instance.pageNumber,
  'pageSize': instance.pageSize,
};
