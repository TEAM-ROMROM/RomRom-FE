import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';

/// 채팅방 AI 행동 추천 상태: 방별 노출 추천, 사용자가 닫은 추천 키 (#759)
@immutable
class ChatRecommendationState {
  // 채팅방 ID > 현재 노출할 추천 (NONE·닫은 추천은 들지 않음)
  final Map<String, ChatActionRecommendation> recommendationByChatRoomId;
  // 채팅방 ID > 닫은 추천 식별 키 {basedOnMessageId}:{action} (재조회·재연결 시 재노출 방지)
  final Map<String, Set<String>> dismissedKeysByChatRoomId;

  const ChatRecommendationState({
    this.recommendationByChatRoomId = const {},
    this.dismissedKeysByChatRoomId = const {},
  });

  /// 채팅방 현재 추천 (없으면 null)
  ChatActionRecommendation? recommendationOf(String chatRoomId) => recommendationByChatRoomId[chatRoomId];

  /// 닫은 추천 여부
  bool isDismissed(String chatRoomId, ChatActionRecommendation recommendation) =>
      dismissedKeysByChatRoomId[chatRoomId]?.contains(recommendation.identityKey) ?? false;

  ChatRecommendationState copyWith({
    Map<String, ChatActionRecommendation>? recommendationByChatRoomId,
    Map<String, Set<String>>? dismissedKeysByChatRoomId,
  }) => ChatRecommendationState(
    recommendationByChatRoomId: recommendationByChatRoomId ?? this.recommendationByChatRoomId,
    dismissedKeysByChatRoomId: dismissedKeysByChatRoomId ?? this.dismissedKeysByChatRoomId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRecommendationState &&
          runtimeType == other.runtimeType &&
          mapEquals(recommendationByChatRoomId, other.recommendationByChatRoomId) &&
          _isDismissedKeysEqual(dismissedKeysByChatRoomId, other.dismissedKeysByChatRoomId);

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(recommendationByChatRoomId.entries.map((entry) => Object.hash(entry.key, entry.value))),
    Object.hashAllUnordered(
      dismissedKeysByChatRoomId.entries.map((entry) => Object.hash(entry.key, Object.hashAllUnordered(entry.value))),
    ),
  );

  @override
  String toString() =>
      'ChatRecommendationState(rooms: ${recommendationByChatRoomId.length}, dismissedRooms: ${dismissedKeysByChatRoomId.length})';
}

// 방별 닫은 키 집합 비교 (Map<String, Set> 깊은 비교)
bool _isDismissedKeysEqual(Map<String, Set<String>> left, Map<String, Set<String>> right) {
  if (left.length != right.length) return false;
  return left.entries.every((entry) => setEquals(entry.value, right[entry.key]));
}
