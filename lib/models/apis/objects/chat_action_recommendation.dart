import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';

/// 채팅방 AI 행동 추천 (BE ChatActionRecommendationPayload, #759)
/// 수신 경로 2개: messages/get 응답 latestRecommendation, 웹소켓 /user/queue/chat.recommend.{chatRoomId}
@immutable
class ChatActionRecommendation {
  final String? chatRoomId;
  // 이 추천을 받는 회원 (= 현재 사용자)
  final String? targetMemberId;
  final ChatRecommendedAction action;
  // 추천 이유 (nullable, 화면 미노출)
  final String? reason;
  // 추천 판단 기준 최신 메시지 ID (같은 추천 식별용)
  final String? basedOnMessageId;
  final DateTime? createdDate;

  const ChatActionRecommendation({
    this.chatRoomId,
    this.targetMemberId,
    required this.action,
    this.reason,
    this.basedOnMessageId,
    this.createdDate,
  });

  /// 서버 JSON > 추천 (action 모르는 값 > none)
  factory ChatActionRecommendation.fromJson(Map<String, dynamic> json) => ChatActionRecommendation(
    chatRoomId: json['chatRoomId'] as String?,
    targetMemberId: json['targetMemberId'] as String?,
    action: ChatRecommendedAction.fromServerName(json['action'] as String?),
    reason: json['reason'] as String?,
    basedOnMessageId: json['basedOnMessageId'] as String?,
    createdDate: parseRecommendationCreatedDate(json['createdDate']),
  );

  Map<String, dynamic> toJson() => {
    'chatRoomId': chatRoomId,
    'targetMemberId': targetMemberId,
    'action': action.serverName,
    'reason': reason,
    'basedOnMessageId': basedOnMessageId,
    'createdDate': createdDate?.toIso8601String(),
  };

  /// 같은 추천 식별 키: {basedOnMessageId}:{action} (닫은 추천 재노출 방지용)
  String get identityKey => '$basedOnMessageId:${action.serverName}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatActionRecommendation &&
          chatRoomId == other.chatRoomId &&
          targetMemberId == other.targetMemberId &&
          action == other.action &&
          reason == other.reason &&
          basedOnMessageId == other.basedOnMessageId &&
          createdDate == other.createdDate;

  @override
  int get hashCode => Object.hash(chatRoomId, targetMemberId, action, reason, basedOnMessageId, createdDate);

  @override
  String toString() =>
      'ChatActionRecommendation(chatRoomId: $chatRoomId, action: ${action.serverName}, basedOnMessageId: $basedOnMessageId)';
}

/// 추천 생성 시각 파싱: ISO 문자열 · Jackson 배열 [년,월,일,시,분,초] · epoch ms (그 외 null)
DateTime? parseRecommendationCreatedDate(Object? value) {
  if (value is String) return DateTime.tryParse(value);
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is List && value.length >= 3 && value.every((part) => part is int)) {
    final parts = value.cast<int>();
    int partAt(int index) => index < parts.length ? parts[index] : 0;
    return DateTime(parts[0], parts[1], parts[2], partAt(3), partAt(4), partAt(5));
  }
  return null;
}
