import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/widgets/my_page/my_item_promote_control.dart';

import '../../helpers/pump_design_screen.dart';

// 남은 시간 계산 기준 시각
final referenceTime = DateTime(2026, 10, 31, 12);

Future<void> pumpPromoteControl(WidgetTester tester, Item item) async {
  await tester.pumpWidget(
    ProviderScope(
      child: buildDesignScreenApp(
        home: Scaffold(
          body: MyItemPromoteControl(item: item, referenceTime: referenceTime),
        ),
      ),
    ),
  );
}

void main() {
  group('MyItemPromoteControl 노출 배지', () {
    testWidgets('종료 시각이 미래 > 남은 시간 배지, 우선 노출 버튼 없음', (tester) async {
      await pumpPromoteControl(
        tester,
        Item(
          itemId: 'A',
          isPromoted: true,
          promotionExpiresAt: referenceTime.add(const Duration(hours: 23, minutes: 40)),
        ),
      );

      expect(find.text('⚡ 노출 중 · 23시간 남음'), findsOneWidget);
      expect(find.text('⚡ 우선 노출'), findsNothing);
    });

    testWidgets('종료 시각 지남 > 배지 숨김, 우선 노출 버튼 (isPromoted true여도)', (tester) async {
      await pumpPromoteControl(
        tester,
        Item(itemId: 'A', isPromoted: true, promotionExpiresAt: referenceTime.subtract(const Duration(minutes: 1))),
      );

      expect(find.textContaining('노출 중'), findsNothing);
      expect(find.text('⚡ 우선 노출'), findsOneWidget);
    });

    testWidgets('종료 시각 없음 + isPromoted true > 문구만 배지', (tester) async {
      await pumpPromoteControl(tester, Item(itemId: 'A', isPromoted: true));

      expect(find.text('⚡ 노출 중'), findsOneWidget);
    });

    testWidgets('노출 이력 없음 > 우선 노출 버튼', (tester) async {
      await pumpPromoteControl(tester, Item(itemId: 'A'));

      expect(find.text('⚡ 우선 노출'), findsOneWidget);
    });

    testWidgets('itemId 없음 > 아무것도 표시 안 함', (tester) async {
      await pumpPromoteControl(tester, Item(isPromoted: true));

      expect(find.textContaining('노출'), findsNothing);
    });
  });

  group('toPromotionActiveLabel 남은 시간 문구', () {
    test('1시간 이상 > 시간 (버림), 1시간 미만 > 분 (최소 1분), 없음 > 문구만', () {
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(hours: 24)), '⚡ 노출 중 · 24시간 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(hours: 1, minutes: 59)), '⚡ 노출 중 · 1시간 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(minutes: 59)), '⚡ 노출 중 · 59분 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(const Duration(seconds: 20)), '⚡ 노출 중 · 1분 남음');
      expect(MyItemPromoteControl.toPromotionActiveLabel(null), '⚡ 노출 중');
    });
  });
}
