import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';

part 'chat_action_recommendation_payload.g.dart';

/// ChatRecommendedAction 서버 문자열 ↔ enum 변환
class _ActionConverter implements JsonConverter<ChatRecommendedAction, String?> {
  const _ActionConverter();

  @override
  ChatRecommendedAction fromJson(String? json) => ChatRecommendedAction.fromServerName(json);

  @override
  String? toJson(ChatRecommendedAction object) => object.name;
}

/// createdDate: 서버가 String 또는 int(ms) 두 형태로 내려올 수 있음
class _FlexDateTimeConverter implements JsonConverter<DateTime?, Object?> {
  const _FlexDateTimeConverter();

  @override
  DateTime? fromJson(Object? json) {
    if (json is String) return DateTime.tryParse(json)?.toLocal();
    if (json is int) return DateTime.fromMillisecondsSinceEpoch(json, isUtc: true).toLocal();
    return null;
  }

  @override
  Object? toJson(DateTime? object) => object?.toIso8601String();
}

/// AI 행동 추천 페이로드 (WebSocket /user/queue/chat.recommend.{chatRoomId})
@JsonSerializable()
class ChatActionRecommendationPayload {
  final String? chatRoomId;
  final String? targetMemberId;

  @_ActionConverter()
  final ChatRecommendedAction action;

  final String? reason;
  final String? basedOnMessageId;

  @_FlexDateTimeConverter()
  final DateTime? createdDate;

  const ChatActionRecommendationPayload({
    this.chatRoomId,
    this.targetMemberId,
    required this.action,
    this.reason,
    this.basedOnMessageId,
    this.createdDate,
  });

  factory ChatActionRecommendationPayload.fromJson(Map<String, dynamic> json) =>
      _$ChatActionRecommendationPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$ChatActionRecommendationPayloadToJson(this);
}
