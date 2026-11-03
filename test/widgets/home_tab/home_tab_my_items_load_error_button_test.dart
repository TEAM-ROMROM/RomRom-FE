import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';
import 'package:romrom_fe/widgets/home_tab/home_tab_my_items_load_error_button.dart';

import '../../helpers/pump_design_screen.dart';

Future<void> pumpLoadErrorButton(
  WidgetTester tester, {
  required VoidCallback onRetryTap,
  bool isRetrying = false,
}) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: HomeTabMyItemsLoadErrorButton(onRetryTap: onRetryTap, isRetrying: isRetrying),
      ),
    ),
  );
}

void main() {
  group('HomeTabMyItemsLoadErrorButton', () {
    testWidgets('실패 안내 + 다시 시도 탭 시 콜백 1회', (tester) async {
      var retryTapCount = 0;
      await pumpLoadErrorButton(tester, onRetryTap: () => retryTapCount++);

      expect(find.text('내 물품을 불러오지 못했어요'), findsOneWidget);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      expect(retryTapCount, 1);
    });

    testWidgets('재시도 중 > 스피너 표시, 탭 무시', (tester) async {
      var retryTapCount = 0;
      await pumpLoadErrorButton(tester, onRetryTap: () => retryTapCount++, isRetrying: true);

      expect(find.byType(CommonLoadingIndicator), findsOneWidget);
      await tester.tap(find.text('내 물품을 불러오지 못했어요'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(retryTapCount, 0);
    });
  });
}
