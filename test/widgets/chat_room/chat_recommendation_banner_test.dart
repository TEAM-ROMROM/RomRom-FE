import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_recommended_action.dart';
import 'package:romrom_fe/widgets/chat_room/chat_recommendation_banner.dart';
import '../../helpers/pump_design_screen.dart';

/// 배너 콜백 기록
class RecommendationBannerCallbackLog {
  final List<ChatRecommendedAction> pressedActions = [];
  int dismissCount = 0;
}

/// 추천 배너 렌더 (ScreenUtil 초기화 포함)
Future<RecommendationBannerCallbackLog> pumpRecommendationBanner(
  WidgetTester tester, {
  required ChatRecommendedAction? action,
}) async {
  useDesignScreenView(tester);
  final callbackLog = RecommendationBannerCallbackLog();
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: ChatRecommendationBanner(
            action: action,
            onActionPressed: callbackLog.pressedActions.add,
            onDismissed: () => callbackLog.dismissCount++,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return callbackLog;
}

void main() {
  group('ChatRecommendationBanner', () {
    for (final action in ChatRecommendedAction.values.where((action) => action.isRecommendation)) {
      testWidgets('${action.name} > 추천 문구·버튼 문구 표시, 버튼 탭 시 같은 행동 전달', (tester) async {
        final callbackLog = await pumpRecommendationBanner(tester, action: action);

        expect(find.text(action.recommendationMessage), findsOneWidget);
        expect(find.text(action.actionLabel), findsOneWidget);

        await tester.tap(find.text(action.actionLabel));
        await tester.pump();
        expect(callbackLog.pressedActions, [action]);
        expect(callbackLog.dismissCount, 0);
      });
    }

    testWidgets('닫기 탭 > 닫기 콜백만 호출', (tester) async {
      final callbackLog = await pumpRecommendationBanner(tester, action: ChatRecommendedAction.sendLocation);

      await tester.tap(find.bySemanticsLabel('추천 닫기'));
      await tester.pump();
      expect(callbackLog.dismissCount, 1);
      expect(callbackLog.pressedActions, isEmpty);
    });

    testWidgets('NONE > 미노출', (tester) async {
      await pumpRecommendationBanner(tester, action: ChatRecommendedAction.none);

      for (final action in ChatRecommendedAction.values.where((action) => action.isRecommendation)) {
        expect(find.text(action.actionLabel), findsNothing);
      }
      expect(find.bySemanticsLabel('추천 닫기'), findsNothing);
    });

    testWidgets('null > 미노출, 추천 수신 시 등장, NONE 수신 시 퇴장', (tester) async {
      await pumpRecommendationBanner(tester, action: null);
      expect(find.text(ChatRecommendedAction.sendLocation.actionLabel), findsNothing);

      await pumpRecommendationBanner(tester, action: ChatRecommendedAction.sendLocation);
      expect(find.text(ChatRecommendedAction.sendLocation.actionLabel), findsOneWidget);

      await pumpRecommendationBanner(tester, action: ChatRecommendedAction.none);
      expect(find.text(ChatRecommendedAction.sendLocation.actionLabel), findsNothing);
    });
  });
}
