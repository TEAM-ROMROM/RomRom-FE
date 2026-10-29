import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_empty_feed_view.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_top_actions.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함)
Future<void> pumpHomeTabWidget(WidgetTester tester, Widget homeTabWidget) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(body: Center(child: homeTabWidget)),
    ),
  );
}

void main() {
  group('HomeTabTopActions', () {
    testWidgets('미확인 알림 없음: 알림 아이콘 라벨 > 탭 시 알림 콜백', (tester) async {
      int notificationTapCount = 0;
      await pumpHomeTabWidget(
        tester,
        HomeTabTopActions(
          hasUnreadNotification: false,
          onNotificationTap: () => notificationTapCount++,
          onReportPressed: () {},
        ),
      );

      expect(find.bySemanticsLabel('알림'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('알림'));
      await tester.pump();
      expect(notificationTapCount, 1);
    });

    testWidgets('미확인 알림 있음: 배지 아이콘 라벨', (tester) async {
      await pumpHomeTabWidget(
        tester,
        HomeTabTopActions(hasUnreadNotification: true, onNotificationTap: () {}, onReportPressed: () {}),
      );

      expect(find.bySemanticsLabel('읽지 않은 알림 있음, 알림 목록'), findsOneWidget);
      expect(find.bySemanticsLabel('알림'), findsNothing);
    });
  });

  group('HomeTabEmptyFeedView', () {
    testWidgets('빈 피드 문구 > 새로고침 탭 시 콜백', (tester) async {
      int refreshTapCount = 0;
      await pumpHomeTabWidget(tester, HomeTabEmptyFeedView(onRefreshTap: () => refreshTapCount++));

      expect(find.text('물품이 없습니다.'), findsOneWidget);
      await tester.tap(find.text('새로고침'));
      await tester.pumpAndSettle();
      expect(refreshTapCount, 1);
    });
  });
}
