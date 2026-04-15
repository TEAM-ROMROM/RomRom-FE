// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_action_recommendation_payload.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatActionRecommendationPayload _$ChatActionRecommendationPayloadFromJson(Map<String, dynamic> json) =>
    ChatActionRecommendationPayload(
      chatRoomId: json['chatRoomId'] as String?,
      targetMemberId: json['targetMemberId'] as String?,
      action: const _ActionConverter().fromJson(json['action'] as String?),
      reason: json['reason'] as String?,
      basedOnMessageId: json['basedOnMessageId'] as String?,
      createdDate: const _FlexDateTimeConverter().fromJson(json['createdDate']),
    );

Map<String, dynamic> _$ChatActionRecommendationPayloadToJson(ChatActionRecommendationPayload instance) =>
    <String, dynamic>{
      'chatRoomId': instance.chatRoomId,
      'targetMemberId': instance.targetMemberId,
      'action': const _ActionConverter().toJson(instance.action),
      'reason': instance.reason,
      'basedOnMessageId': instance.basedOnMessageId,
      'createdDate': const _FlexDateTimeConverter().toJson(instance.createdDate),
    };
