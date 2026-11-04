import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/providers/open_chat_room_registry_provider.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';
import 'package:romrom_fe/screens/item_deleted_screen.dart';
import 'package:romrom_fe/services/deep_link_gate.dart';
import 'package:romrom_fe/services/local_notification_service.dart';
import 'package:romrom_fe/services/open_chat_room_registry.dart';
import 'package:romrom_fe/services/push_notification_routing.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';

import '../helpers/pump_design_screen.dart';

/// 푸시 탭 이동 (#984): 같은 방이 맨 위면 새로 쌓지 않음, Android 포그라운드 로컬 알림 탭 > payload 딥링크 이동
void main() {
  late OpenChatRoomRegistry openChatRoomRegistry;

  setUp(() {
    DeepLinkGate.instance.resetForTest();
    openChatRoomRegistry = OpenChatRoomRegistry();
  });

  Future<void> pumpRootApp(WidgetTester tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [openChatRoomRegistryProvider.overrideWithValue(openChatRoomRegistry)],
        child: ScreenUtilInit(
          designSize: designScreenSize,
          builder: (context, child) => MaterialApp(navigatorKey: navigatorKey, home: const Scaffold()),
        ),
      ),
    );
    RomRomDeepLinkRouter.onMainScreenEntered();
  }

  testWidgets('같은 채팅방이 맨 위에 열려 있음 > 채팅방 화면 새로 쌓지 않음', (tester) async {
    await pumpRootApp(tester);
    final Object openRoomScreen = Object();
    openChatRoomRegistry.register(owner: openRoomScreen, chatRoomId: 'room-1', isRouteCurrent: () => true);

    await RomRomDeepLinkRouter.openFromUri(
      navigatorKey.currentContext!,
      Uri.parse('romrom://chat/room?chatRoomId=room-1'),
    );
    await tester.pump();

    expect(find.byType(ChatRoomScreen), findsNothing);
  });

  testWidgets('로컬 알림 탭 > payload의 딥링크 화면으로 이동', (tester) async {
    await pumpRootApp(tester);
    final payload = encodePushNotificationPayload(const {
      'deepLink': 'romrom://item/deleted',
      'itemName': '테스트물품',
      'deleteReason': '가이드라인 위반',
    });

    onLocalNotificationTapped(
      NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification, payload: payload),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItemDeletedScreen), findsOneWidget);
  });

  testWidgets('payload 없는 로컬 알림 탭 > 이동 없음', (tester) async {
    await pumpRootApp(tester);

    onLocalNotificationTapped(
      const NotificationResponse(notificationResponseType: NotificationResponseType.selectedNotification),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ItemDeletedScreen), findsNothing);
  });
}
