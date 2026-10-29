import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/screens/item_register_screen.dart';
import 'package:romrom_fe/widgets/common/unsaved_changes_guard.dart';
import '../helpers/pump_design_screen.dart';

/// 런처 > 'open' 탭 시 물품 등록 화면 push
Future<void> pumpItemRegisterScreen(WidgetTester tester) async {
  useDesignScreenView(tester);

  await tester.pumpWidget(
    ProviderScope(
      child: buildDesignScreenApp(
        home: Builder(
          builder: (launcherContext) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(
                  launcherContext,
                ).push(MaterialPageRoute<void>(builder: (_) => const ItemRegisterScreen())),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

/// 시스템 뒤로가기 (Android back 경로)
Future<void> simulateSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  group('ItemRegisterScreen 이탈 경고', () {
    testWidgets('빈 폼 > 뒤로가기 바로 닫힘', (tester) async {
      await pumpItemRegisterScreen(tester);
      expect(find.byType(ItemRegisterScreen), findsOneWidget);

      await simulateSystemBack(tester);

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
      expect(find.byType(ItemRegisterScreen), findsNothing);
    });

    testWidgets('이름 입력 후 뒤로가기 > 확인 모달, 나가기 시 닫힘', (tester) async {
      await pumpItemRegisterScreen(tester);

      await tester.enterText(find.byType(TextField).first, '자전거');
      await tester.pumpAndSettle();
      await simulateSystemBack(tester);

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsOneWidget);
      expect(find.byType(ItemRegisterScreen), findsOneWidget);

      await tester.tap(find.text(UnsavedChangesGuard.leaveConfirmText));
      await tester.pumpAndSettle();

      expect(find.byType(ItemRegisterScreen), findsNothing);
    });

    testWidgets('입력 후 지우면 > 변경 없음으로 바로 닫힘', (tester) async {
      await pumpItemRegisterScreen(tester);

      await tester.enterText(find.byType(TextField).first, '자전거');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await simulateSystemBack(tester);

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
      expect(find.byType(ItemRegisterScreen), findsNothing);
    });
  });
}
