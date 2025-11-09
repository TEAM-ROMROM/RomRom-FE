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
      chatRooms: json['chatRooms'] == null
          ? null
          : PagedChatRoom.fromJson(json['chatRooms'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChatRoomResponseToJson(ChatRoomResponse instance) =>
    <String, dynamic>{
      'chatRoom': instance.chatRoom?.toJson(),
      'messages': instance.messages?.toJson(),
      'chatRooms': instance.chatRooms?.toJson(),
    };

PagedChatMessage _$PagedChatMessageFromJson(Map<String, dynamic> json) =>
    PagedChatMessage(
      content: _chatMessageListFromJson(json['content']),
      page: json['page'] == null
          ? null
          : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PagedChatMessageToJson(PagedChatMessage instance) =>
    <String, dynamic>{
      'content': _chatMessageListToJson(instance.content),
      'page': instance.page?.toJson(),
    };

PagedChatRoom _$PagedChatRoomFromJson(Map<String, dynamic> json) =>
    PagedChatRoom(
      content: _chatRoomListFromJson(json['content']),
      page: json['page'] == null
          ? null
          : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PagedChatRoomToJson(PagedChatRoom instance) =>
    <String, dynamic>{
      'content': _chatRoomListToJson(instance.content),
      'page': instance.page?.toJson(),
    };
