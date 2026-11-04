import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/services/chat_topic_subscription_registry.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// 채팅방 부가 토픽 구독 3개 묶음: 읽음, AI 추천, 메시지 변경 (재연결 재구독·연결 해제 정리 공통)
class ChatRoomTopicRegistries {
  // 읽음 이벤트 (/sub/chat.read.{chatRoomId})
  final ChatTopicSubscriptionRegistry<ChatUserState> readEvents = ChatTopicSubscriptionRegistry(
    destinationOf: (chatRoomId) => '/sub/chat.read.$chatRoomId',
    parseBody: ChatUserState.fromJson,
    topicLabel: 'read event',
  );

  // AI 행동 추천: 사용자 전용 큐 (BE convertAndSendToUser '/queue/chat.recommend.{chatRoomId}', #759)
  final ChatTopicSubscriptionRegistry<ChatActionRecommendation> recommendations = ChatTopicSubscriptionRegistry(
    destinationOf: (chatRoomId) => '/user/queue/chat.recommend.$chatRoomId',
    parseBody: ChatActionRecommendation.fromJson,
    topicLabel: 'recommendation',
  );

  // 이미 있는 메시지의 변경본: 삭제·약속 상태 변경 (/sub/chat.update.{chatRoomId}, 옛 앱은 구독 안 함, #1006)
  final ChatTopicSubscriptionRegistry<ChatMessage> messageUpdates = ChatTopicSubscriptionRegistry(
    destinationOf: (chatRoomId) => '/sub/chat.update.$chatRoomId',
    parseBody: ChatMessage.fromJson,
    topicLabel: 'message update',
  );

  List<ChatTopicSubscriptionRegistry<Object>> get _allRegistries => [readEvents, recommendations, messageUpdates];

  /// 재연결 시 구독 중인 방 전부 재구독
  void resubscribeAll(StompClient stompClient) {
    for (final registry in _allRegistries) {
      for (final chatRoomId in registry.subscribedChatRoomIds) {
        registry.subscribeOnStomp(chatRoomId, stompClient);
      }
    }
  }

  /// 연결 해제 시 전부 정리 (STOMP 구독 해제·스트림 닫기)
  Future<void> closeAll() async {
    for (final registry in _allRegistries) {
      await registry.closeAll();
    }
  }
}
