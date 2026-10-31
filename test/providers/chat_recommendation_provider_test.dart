import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/providers/chat_recommendation_provider.dart';
import 'package:romrom_fe/services/chat_topic_subscription_registry.dart';

const String roomId = 'room-1';

/// 테스트용 추천 (기준 메시지 ID로 같은 추천 구분)
ChatActionRecommendation buildRecommendation(
  ChatRecommendedAction action, {
  String basedOnMessageId = 'message-1',
  String? chatRoomId = roomId,
}) {
  return ChatActionRecommendation(chatRoomId: chatRoomId, action: action, basedOnMessageId: basedOnMessageId);
}

void main() {
  late ProviderContainer container;
  ChatRecommendationNotifier notifier() => container.read(chatRecommendationProvider.notifier);
  ChatActionRecommendation? currentRecommendation() =>
      container.read(chatRecommendationProvider).recommendationOf(roomId);

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('초기 상태 > 추천 없음', () {
    expect(currentRecommendation(), isNull);
  });

  test('서버 추천 반영 > 방 추천 노출, 새 추천으로 교체', () {
    notifier().applyServerRecommendation(roomId, buildRecommendation(ChatRecommendedAction.sendLocation));
    expect(currentRecommendation()?.action, ChatRecommendedAction.sendLocation);

    notifier().applyServerRecommendation(
      roomId,
      buildRecommendation(ChatRecommendedAction.requestTradeCompletion, basedOnMessageId: 'message-2'),
    );
    expect(currentRecommendation()?.action, ChatRecommendedAction.requestTradeCompletion);
  });

  test('NONE·null 추천 > 기존 추천 숨김', () {
    notifier().applyServerRecommendation(roomId, buildRecommendation(ChatRecommendedAction.sendLocation));
    notifier().applyServerRecommendation(
      roomId,
      buildRecommendation(ChatRecommendedAction.none, basedOnMessageId: 'message-2'),
    );
    expect(currentRecommendation(), isNull);

    notifier().applyServerRecommendation(roomId, buildRecommendation(ChatRecommendedAction.sendLocation));
    notifier().applyServerRecommendation(roomId, null);
    expect(currentRecommendation(), isNull);
  });

  test('다른 방 추천 > 무시', () {
    notifier().applyServerRecommendation(
      roomId,
      buildRecommendation(ChatRecommendedAction.sendLocation, chatRoomId: 'room-other'),
    );
    expect(currentRecommendation(), isNull);
  });

  test('닫기 > 숨김, 같은 추천 재수신(재조회·재연결) 시에도 숨김 유지, 새 추천은 노출', () {
    final recommendation = buildRecommendation(ChatRecommendedAction.requestTradeCompletion);
    notifier().applyServerRecommendation(roomId, recommendation);
    notifier().dismiss(roomId);
    expect(currentRecommendation(), isNull);

    notifier().applyServerRecommendation(roomId, recommendation);
    expect(currentRecommendation(), isNull);

    notifier().applyServerRecommendation(
      roomId,
      buildRecommendation(ChatRecommendedAction.requestTradeCompletion, basedOnMessageId: 'message-2'),
    );
    expect(currentRecommendation()?.basedOnMessageId, 'message-2');
  });

  test('방별 독립 보관', () {
    notifier().applyServerRecommendation(roomId, buildRecommendation(ChatRecommendedAction.sendLocation));
    notifier().applyServerRecommendation(
      'room-2',
      buildRecommendation(ChatRecommendedAction.confirmTradeCompletion, chatRoomId: 'room-2'),
    );
    notifier().dismiss('room-2');

    expect(currentRecommendation()?.action, ChatRecommendedAction.sendLocation);
    expect(container.read(chatRecommendationProvider).recommendationOf('room-2'), isNull);
  });

  test('웹소켓 추천 이벤트 > 레지스트리 스트림 > provider 상태 갱신', () async {
    // 채팅방 화면 구독과 같은 연결: 추천 스트림 수신 > applyServerRecommendation
    final registry = ChatTopicSubscriptionRegistry<ChatActionRecommendation>(
      destinationOf: (chatRoomId) => '/user/queue/chat.recommend.$chatRoomId',
      parseBody: ChatActionRecommendation.fromJson,
      topicLabel: 'recommendation',
    );
    final subscription = registry
        .subscribe(roomId, stompClient: null, isConnected: false)
        .listen((recommendation) => notifier().applyServerRecommendation(roomId, recommendation));
    addTearDown(subscription.cancel);

    registry.handleFrameBody(
      roomId,
      jsonEncode({'chatRoomId': roomId, 'action': 'CONFIRM_TRADE_COMPLETION', 'basedOnMessageId': 'message-9'}),
    );
    await Future<void>.delayed(Duration.zero);
    expect(currentRecommendation()?.action, ChatRecommendedAction.confirmTradeCompletion);

    registry.handleFrameBody(roomId, jsonEncode({'chatRoomId': roomId, 'action': 'NONE'}));
    await Future<void>.delayed(Duration.zero);
    expect(currentRecommendation(), isNull);
  });
}
