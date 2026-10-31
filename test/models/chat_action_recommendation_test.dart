import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/models/apis/objects/chat_action_recommendation.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';

// BE ChatWebSocketControllerDocs 추천 이벤트 예시 (#635)
const Map<String, dynamic> serverRecommendationJson = {
  'chatRoomId': '7d52df85-e88f-4344-bb68-a6f0dc1e03fb',
  'targetMemberId': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'action': 'REQUEST_TRADE_COMPLETION',
  'reason': '최근 대화 흐름상 거래가 마무리된 것으로 보여 교환 완료 요청이 자연스럽습니다.',
  'basedOnMessageId': '67f5c9b93a7b5a2a4b9ef001',
  'createdDate': '2026-04-09T18:12:00',
};

void main() {
  group('ChatActionRecommendation.fromJson', () {
    test('서버 예시 payload > 전 필드 파싱', () {
      final recommendation = ChatActionRecommendation.fromJson(serverRecommendationJson);

      expect(recommendation.chatRoomId, '7d52df85-e88f-4344-bb68-a6f0dc1e03fb');
      expect(recommendation.targetMemberId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
      expect(recommendation.action, ChatRecommendedAction.requestTradeCompletion);
      expect(recommendation.reason, startsWith('최근 대화 흐름상'));
      expect(recommendation.basedOnMessageId, '67f5c9b93a7b5a2a4b9ef001');
      expect(recommendation.createdDate, DateTime(2026, 4, 9, 18, 12));
      expect(recommendation.identityKey, '67f5c9b93a7b5a2a4b9ef001:REQUEST_TRADE_COMPLETION');
    });

    test('모르는 action·action 누락 > none', () {
      expect(
        ChatActionRecommendation.fromJson({...serverRecommendationJson, 'action': 'BRAND_NEW_ACTION'}).action,
        ChatRecommendedAction.none,
      );
      expect(ChatActionRecommendation.fromJson(const {'chatRoomId': 'room-1'}).action, ChatRecommendedAction.none);
    });

    test('createdDate: Jackson 배열·epoch ms 허용, 그 외 null', () {
      expect(parseRecommendationCreatedDate([2026, 4, 9, 18, 12, 30]), DateTime(2026, 4, 9, 18, 12, 30));
      expect(parseRecommendationCreatedDate([2026, 4, 9]), DateTime(2026, 4, 9));
      expect(parseRecommendationCreatedDate(0), DateTime.fromMillisecondsSinceEpoch(0));
      expect(parseRecommendationCreatedDate('not-a-date'), isNull);
      expect(parseRecommendationCreatedDate(null), isNull);
    });

    test('toJson > fromJson 왕복 동일', () {
      final recommendation = ChatActionRecommendation.fromJson(serverRecommendationJson);
      expect(ChatActionRecommendation.fromJson(recommendation.toJson()), recommendation);
    });
  });

  group('ChatRoomResponse.latestRecommendation (messages/get)', () {
    test('latestRecommendation 있음 > 추천 파싱', () {
      final response = ChatRoomResponse.fromJson({'latestRecommendation': serverRecommendationJson});
      expect(response.latestRecommendation?.action, ChatRecommendedAction.requestTradeCompletion);
    });

    test('NONE 추천 > action none으로 보존', () {
      final response = ChatRoomResponse.fromJson({
        'latestRecommendation': {...serverRecommendationJson, 'action': 'NONE', 'reason': null},
      });
      expect(response.latestRecommendation?.action, ChatRecommendedAction.none);
    });

    test('필드 누락·null (상대 탈퇴 응답) > null', () {
      expect(ChatRoomResponse.fromJson(const {}).latestRecommendation, isNull);
      expect(ChatRoomResponse.fromJson(const {'latestRecommendation': null}).latestRecommendation, isNull);
    });
  });
}
