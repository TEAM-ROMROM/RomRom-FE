import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/pending_deep_link.dart';
import 'package:romrom_fe/screens/item_deleted_screen.dart';
import 'package:romrom_fe/services/deep_link_gate.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/deep_link_router.dart';

import '../helpers/pump_design_screen.dart';

/// 라우터 게이트 경로: 메인 진입 전 receive > 화면 이동 없음, onMainScreenEntered > 보관 링크 1회 이동
void main() {
  final itemDeletedLink = PendingDeepLink(
    uri: Uri.parse('romrom://item/deleted'),
    extraData: const {'itemName': '테스트물품', 'deleteReason': '가이드라인 위반'},
  );

  setUp(DeepLinkGate.instance.resetForTest);

  Future<void> pumpRootApp(WidgetTester tester) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: designScreenSize,
        builder: (context, child) => MaterialApp(navigatorKey: navigatorKey, home: const Scaffold()),
      ),
    );
  }

  testWidgets('메인 진입 전 수신 > 이동 없음, 메인 진입 > 보관 링크 화면 이동', (tester) async {
    await pumpRootApp(tester);

    RomRomDeepLinkRouter.receive(itemDeletedLink);
    await tester.pumpAndSettle();
    expect(find.byType(ItemDeletedScreen), findsNothing);

    RomRomDeepLinkRouter.onMainScreenEntered();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDeletedScreen), findsOneWidget);
    expect(tester.widget<ItemDeletedScreen>(find.byType(ItemDeletedScreen)).itemTitle, '테스트물품'); // extraData 전달
  });

  testWidgets('메인 진입 후 수신 > 바로 화면 이동', (tester) async {
    await pumpRootApp(tester);
    RomRomDeepLinkRouter.onMainScreenEntered();

    RomRomDeepLinkRouter.receive(itemDeletedLink);
    await tester.pumpAndSettle();
    expect(find.byType(ItemDeletedScreen), findsOneWidget);
  });

  testWidgets('메인 진입 후 다음 프레임 전 세션 종료 > 보관 링크 열지 않음', (tester) async {
    await pumpRootApp(tester);
    RomRomDeepLinkRouter.receive(itemDeletedLink);

    RomRomDeepLinkRouter.onMainScreenEntered();
    DeepLinkGate.instance.leaveMainScreen();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDeletedScreen), findsNothing);
  });
}
