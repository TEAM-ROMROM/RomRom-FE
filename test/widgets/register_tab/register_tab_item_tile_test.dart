import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/register_tab/register_tab_item_tile.dart';
import '../../helpers/pump_design_screen.dart';

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함)
Future<void> pumpRegisterTabWidget(WidgetTester tester, Widget registerTabWidget) async {
  await tester.pumpWidget(buildDesignScreenApp(home: Scaffold(body: registerTabWidget)));
}

void main() {
  group('RegisterTabItemTile', () {
    testWidgets('물품 요약 표시: 이름·가격·좋아요 수, 사진 없으면 플레이스홀더, Hero 태그 유지', (tester) async {
      int tapCount = 0;
      await pumpRegisterTabWidget(
        tester,
        RegisterTabItemTile(
          item: Item(itemId: 'item-1', itemName: '캠핑 의자', price: 15000, likeCount: 3),
          isSellingTab: true,
          onTap: () => tapCount++,
          onChangeStatusTap: () {},
          onEditTap: () {},
          onDeleteTap: () {},
        ),
      );

      expect(find.text('캠핑 의자'), findsOneWidget);
      expect(find.text('15,000원'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(ErrorImagePlaceholder), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is Hero && widget.tag == 'itemImage_item-1_0'), findsOneWidget);

      await tester.tap(find.text('캠핑 의자'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
    });

    testWidgets('물품 id 없으면 Hero 없음, 이름 없으면 기본 문구', (tester) async {
      await pumpRegisterTabWidget(
        tester,
        RegisterTabItemTile(
          item: Item(),
          isSellingTab: false,
          onTap: () {},
          onChangeStatusTap: () {},
          onEditTap: () {},
          onDeleteTap: () {},
        ),
      );

      expect(find.text('물품명 없음'), findsOneWidget);
      expect(find.byType(Hero), findsNothing);
    });
  });
}
