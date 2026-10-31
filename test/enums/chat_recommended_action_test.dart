import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';

/// 서버 추천 행동 이름(BE ChatRecommendedAction) > enum, 모르는 값·null > none
void main() {
  group('ChatRecommendedAction.fromServerName', () {
    const expectedActionByServerName = <String, ChatRecommendedAction>{
      'NONE': ChatRecommendedAction.none,
      'SEND_LOCATION': ChatRecommendedAction.sendLocation,
      'REQUEST_TRADE_COMPLETION': ChatRecommendedAction.requestTradeCompletion,
      'CANCEL_TRADE_COMPLETION_REQUEST': ChatRecommendedAction.cancelTradeCompletionRequest,
      'REJECT_TRADE_COMPLETION_REQUEST': ChatRecommendedAction.rejectTradeCompletionRequest,
      'CONFIRM_TRADE_COMPLETION': ChatRecommendedAction.confirmTradeCompletion,
    };

    for (final entry in expectedActionByServerName.entries) {
      test('${entry.key} > ${entry.value.name}', () {
        expect(ChatRecommendedAction.fromServerName(entry.key), entry.value);
      });
    }

    test('BE enum 6개 전부 대응', () {
      expect(ChatRecommendedAction.values.map((action) => action.serverName).toSet(), expectedActionByServerName.keys);
    });

    test('모르는 값·소문자·null > none', () {
      expect(ChatRecommendedAction.fromServerName('BRAND_NEW_ACTION'), ChatRecommendedAction.none);
      expect(ChatRecommendedAction.fromServerName('send_location'), ChatRecommendedAction.none);
      expect(ChatRecommendedAction.fromServerName(null), ChatRecommendedAction.none);
    });
  });

  test('none만 노출 대상 아님, 나머지는 추천 문구·버튼 문구 보유', () {
    expect(ChatRecommendedAction.none.isRecommendation, isFalse);
    for (final action in ChatRecommendedAction.values.where((action) => action != ChatRecommendedAction.none)) {
      expect(action.isRecommendation, isTrue, reason: action.name);
      expect(action.recommendationMessage, isNotEmpty, reason: action.name);
      expect(action.actionLabel, isNotEmpty, reason: action.name);
    }
  });
}
