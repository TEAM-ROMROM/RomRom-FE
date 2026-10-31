import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/services/chat_topic_subscription_registry.dart';

/// 추천 토픽 레지스트리 (ChatWebSocketService 추천 구독과 같은 설정)
ChatTopicSubscriptionRegistry<ChatActionRecommendation> buildRecommendationRegistry() {
  return ChatTopicSubscriptionRegistry(
    destinationOf: (chatRoomId) => '/user/queue/chat.recommend.$chatRoomId',
    parseBody: ChatActionRecommendation.fromJson,
    topicLabel: 'recommendation',
  );
}

void main() {
  test('destination: 사용자 전용 추천 큐', () {
    expect(buildRecommendationRegistry().destinationOf('room-1'), '/user/queue/chat.recommend.room-1');
  });

  test('프레임 본문 > 추천 모델로 해당 방 스트림 전달', () async {
    final registry = buildRecommendationRegistry();
    final stream = registry.subscribe('room-1', stompClient: null, isConnected: false);
    final firstRecommendation = stream.first;

    registry.handleFrameBody(
      'room-1',
      jsonEncode({'chatRoomId': 'room-1', 'action': 'SEND_LOCATION', 'basedOnMessageId': 'message-1'}),
    );

    final recommendation = await firstRecommendation;
    expect(recommendation.action, ChatRecommendedAction.sendLocation);
    expect(recommendation.basedOnMessageId, 'message-1');
  });

  test('본문 없음·깨진 JSON > 무시 (스트림 오류 없음)', () async {
    final registry = buildRecommendationRegistry();
    final receivedRecommendations = <ChatActionRecommendation>[];
    final subscription = registry
        .subscribe('room-1', stompClient: null, isConnected: false)
        .listen(receivedRecommendations.add, onError: (Object error) => fail('stream error: $error'));
    addTearDown(subscription.cancel);

    registry.handleFrameBody('room-1', null);
    registry.handleFrameBody('room-1', '{broken');
    registry.handleFrameBody('room-1', jsonEncode({'chatRoomId': 'room-1', 'action': 'NONE'}));
    await Future<void>.delayed(Duration.zero);

    expect(receivedRecommendations.single.action, ChatRecommendedAction.none);
  });

  test('참조 카운트: 마지막 구독 해제 때만 스트림 닫힘', () async {
    final registry = buildRecommendationRegistry();
    final firstStream = registry.subscribe('room-1', stompClient: null, isConnected: false);
    registry.subscribe('room-1', stompClient: null, isConnected: false);
    var isStreamClosed = false;
    firstStream.listen((_) {}, onDone: () => isStreamClosed = true);

    registry.unsubscribe('room-1');
    await Future<void>.delayed(Duration.zero);
    expect(isStreamClosed, isFalse);
    expect(registry.subscribedChatRoomIds, contains('room-1'));

    registry.unsubscribe('room-1');
    await Future<void>.delayed(Duration.zero);
    expect(isStreamClosed, isTrue);
    expect(registry.subscribedChatRoomIds, isEmpty);

    // 이미 해제된 방 > 무시
    registry.unsubscribe('room-1');
  });

  test('closeAll > 모든 방 정리, 재구독 시 새 스트림', () async {
    final registry = buildRecommendationRegistry();
    registry.subscribe('room-1', stompClient: null, isConnected: false);
    registry.subscribe('room-2', stompClient: null, isConnected: false);

    await registry.closeAll();
    expect(registry.subscribedChatRoomIds, isEmpty);

    final renewedStream = registry.subscribe('room-1', stompClient: null, isConnected: false);
    final firstRecommendation = renewedStream.first;
    registry.handleFrameBody('room-1', jsonEncode({'action': 'CONFIRM_TRADE_COMPLETION'}));
    expect((await firstRecommendation).action, ChatRecommendedAction.confirmTradeCompletion);
  });
}
