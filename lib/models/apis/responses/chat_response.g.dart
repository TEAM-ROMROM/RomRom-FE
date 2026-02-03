// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatRoomResponse _$ChatRoomResponseFromJson(Map<String, dynamic> json) =>
    ChatRoomResponse(
      chatRoom: json['chatRoom'] == null
          ? null
          : ChatRoom.fromJson(json['chatRoom'] as Map<String, dynamic>),
      messages: json['messages'] == null
          ? null
          : PagedChatMessage.fromJson(json['messages'] as Map<String, dynamic>),
      chatRoomDetailDtoPage: json['chatRoomDetailDtoPage'] == null
          ? null
          : PagedChatRoomDetail.fromJson(
              json['chatRoomDetailDtoPage'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$ChatRoomResponseToJson(ChatRoomResponse instance) =>
    <String, dynamic>{
      'chatRoom': instance.chatRoom?.toJson(),
      'messages': instance.messages?.toJson(),
      'chatRoomDetailDtoPage': instance.chatRoomDetailDtoPage?.toJson(),
    };

PagedChatMessage _$PagedChatMessageFromJson(Map<String, dynamic> json) =>
    PagedChatMessage(
      content: _chatMessageListFromJson(json['content']),
      page: _pageableFromJson(json['page'] as Map<String, dynamic>?),
      last: json['last'] as bool? ?? true,
    );

Map<String, dynamic> _$PagedChatMessageToJson(PagedChatMessage instance) =>
    <String, dynamic>{
      'content': _chatMessageListToJson(instance.content),
      'page': instance.page?.toJson(),
      'last': instance.last,
    };

PagedChatRoomDetail _$PagedChatRoomDetailFromJson(Map<String, dynamic> json) =>
    PagedChatRoomDetail(
      content: _chatRoomDetailListFromJson(json['content']),
      page: _pageableFromJson(json['page'] as Map<String, dynamic>?),
      last: json['last'] as bool? ?? true,
    );

Map<String, dynamic> _$PagedChatRoomDetailToJson(
  PagedChatRoomDetail instance,
) => <String, dynamic>{
  'content': _chatRoomDetailListToJson(instance.content),
  'page': instance.page?.toJson(),
  'last': instance.last,
};
