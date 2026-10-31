// 채팅방 AI 행동 추천 Provider (#759)
//
// 종류: 동기 Notifier — 서버 추천(messages/get latestRecommendation, 웹소켓 추천 이벤트)을 방별로 보관, API 호출 없음.
// 4-레이어: 수신은 chatRepository(getChatMessages)·ChatWebSocketService 경유 > lib/states/chat_recommendation_state.dart + 이 파일.
// 화면이 닫혀도 닫은 추천 기록 유지 (같은 추천 재진입 시 재노출 방지), 로그아웃 시 userScopedProviders로 초기화.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/states/chat_recommendation_state.dart';

final chatRecommendationProvider = NotifierProvider<ChatRecommendationNotifier, ChatRecommendationState>(
  ChatRecommendationNotifier.new,
);

class ChatRecommendationNotifier extends Notifier<ChatRecommendationState> {
  @override
  ChatRecommendationState build() => const ChatRecommendationState();

  /// 서버 추천 반영: 다른 방 추천 무시 > NONE·null·닫은 추천이면 숨김 > 그 외 교체
  void applyServerRecommendation(String chatRoomId, ChatActionRecommendation? recommendation) {
    final recommendedChatRoomId = recommendation?.chatRoomId;
    if (recommendedChatRoomId != null && recommendedChatRoomId != chatRoomId) return;

    final shouldHide =
        recommendation == null ||
        !recommendation.action.isRecommendation ||
        state.isDismissed(chatRoomId, recommendation);
    if (shouldHide) {
      _removeRecommendation(chatRoomId);
      return;
    }
    if (state.recommendationOf(chatRoomId) == recommendation) return;
    state = state.copyWith(
      recommendationByChatRoomId: {...state.recommendationByChatRoomId, chatRoomId: recommendation},
    );
  }

  /// 추천 닫기 (닫기 버튼·추천 행동 실행 공통): 식별 키 기록 > 숨김
  void dismiss(String chatRoomId) {
    final recommendation = state.recommendationOf(chatRoomId);
    if (recommendation == null) return;
    final dismissedKeys = {...?state.dismissedKeysByChatRoomId[chatRoomId], recommendation.identityKey};
    final remainingRecommendations = {...state.recommendationByChatRoomId}..remove(chatRoomId);
    state = state.copyWith(
      recommendationByChatRoomId: remainingRecommendations,
      dismissedKeysByChatRoomId: {...state.dismissedKeysByChatRoomId, chatRoomId: dismissedKeys},
    );
  }

  // 방 추천 숨김 (닫은 기록은 유지)
  void _removeRecommendation(String chatRoomId) {
    if (!state.recommendationByChatRoomId.containsKey(chatRoomId)) return;
    state = state.copyWith(recommendationByChatRoomId: {...state.recommendationByChatRoomId}..remove(chatRoomId));
  }
}
