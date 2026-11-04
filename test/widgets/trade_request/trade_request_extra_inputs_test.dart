import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/trade_request/trade_request_extra_inputs.dart';
import '../../helpers/pump_design_screen.dart';

/// 부가 입력 위젯 렌더 (추가금 선택 여부 지정)
Future<void> pumpExtraInputs(
  WidgetTester tester, {
  required bool isExtraChargeSelected,
  required TextEditingController requestMessageController,
}) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: TradeRequestExtraInputs(
          isExtraChargeSelected: isExtraChargeSelected,
          extraChargeAmountController: TextEditingController(),
          requestMessageController: requestMessageController,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('추가금 미선택 > 메시지 칸만, 선택 > 금액 칸 추가', (tester) async {
    final requestMessageController = TextEditingController();
    addTearDown(requestMessageController.dispose);

    await pumpExtraInputs(tester, isExtraChargeSelected: false, requestMessageController: requestMessageController);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('추가금 (선택)'), findsNothing);

    await pumpExtraInputs(tester, isExtraChargeSelected: true, requestMessageController: requestMessageController);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('추가금 (선택)'), findsOneWidget);
  });

  testWidgets('메시지 100자 제한 + 줄바꿈 차단 + 글자 수 표시', (tester) async {
    final requestMessageController = TextEditingController();
    addTearDown(requestMessageController.dispose);
    await pumpExtraInputs(tester, isExtraChargeSelected: false, requestMessageController: requestMessageController);

    await tester.enterText(find.byType(TextField), '가' * 120);
    await tester.pump();
    expect(requestMessageController.text.length, 100);
    expect(find.text('100/100'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '첫 줄\n둘째 줄');
    await tester.pump();
    expect(requestMessageController.text.contains('\n'), isFalse);
  });
}
