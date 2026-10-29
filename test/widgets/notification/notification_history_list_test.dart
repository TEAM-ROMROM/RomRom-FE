import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/notification/notification_history_list.dart';
import 'package:romrom_fe/widgets/notification_item_widget.dart';
import '../../helpers/pump_design_screen.dart';

/// 목록 렌더 (ScreenUtil 초기화 포함, 세로 넘침 방지 스크롤)
Future<void> pumpNotificationHistoryList(
  WidgetTester tester, {
  required List<NotificationItemData> notifications,
  bool isRomromNewsTab = false,
  bool isLoadingMore = false,
  ValueChanged<NotificationItemData>? onNotificationTap,
}) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: NotificationHistoryList(
            notifications: notifications,
            isRomromNewsTab: isRomromNewsTab,
            isLoadingMore: isLoadingMore,
            pageSize: 20,
            isMutedFor: (type) => false,
            onNotificationTap: onNotificationTap ?? (_) {},
            onMuteTap: (_) {},
            onDeleteTap: (_) {},
          ),
        ),
      ),
    ),
  );
  // 순차 등장 애니메이션 완료
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('NotificationHistoryList', () {
    testWidgets('빈 목록: 탭별 안내 문구', (tester) async {
      await pumpNotificationHistoryList(tester, notifications: const []);
      expect(find.text('알림이 없습니다'), findsOneWidget);

      await pumpNotificationHistoryList(tester, notifications: const [], isRomromNewsTab: true);
      expect(find.text('롬롬 소식이 없습니다'), findsOneWidget);
    });

    testWidgets('알림 행 표시 > 탭 시 해당 알림 전달, 다음 페이지 조회 중 표시', (tester) async {
      NotificationItemData? tappedNotification;
      final notification = NotificationItemData(
        id: 'notification-1',
        type: NotificationType.itemLiked,
        title: '좋아요 알림',
        description: '누군가 내 물품을 좋아해요',
        time: DateTime.now(),
      );
      await pumpNotificationHistoryList(
        tester,
        notifications: [notification],
        isLoadingMore: true,
        onNotificationTap: (tapped) => tappedNotification = tapped,
      );

      expect(find.text('좋아요 알림'), findsOneWidget);
      expect(find.byType(CommonLoadingIndicator), findsOneWidget);

      await tester.tap(find.text('좋아요 알림'));
      await tester.pump(const Duration(seconds: 1));
      expect(tappedNotification?.id, 'notification-1');
    });
  });
}
