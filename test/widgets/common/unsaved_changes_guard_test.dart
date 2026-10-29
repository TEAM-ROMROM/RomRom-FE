import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/widgets/common/unsaved_changes_guard.dart';

// 디자인 기준 화면 (iPhone 393x852)
const Size designScreenSize = Size(393, 852);

/// 런처 화면 > 'open' 탭 시 가드 화면 push (가드 화면 닫힘 횟수는 [onLeaveCalled]로 통지)
Future<void> pumpGuardedScreen(
  WidgetTester tester, {
  required ValueNotifier<bool> hasUnsavedChangesNotifier,
  ValueNotifier<bool>? isLeaveBlockedNotifier,
  required VoidCallback onLeaveCalled,
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = designScreenSize;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: designScreenSize,
      builder: (context, child) => MaterialApp(
        home: Builder(
          builder: (launcherContext) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(launcherContext).push(
                  MaterialPageRoute<void>(
                    builder: (guardedContext) => UnsavedChangesGuard(
                      hasUnsavedChangesListenable: hasUnsavedChangesNotifier,
                      isLeaveBlockedListenable: isLeaveBlockedNotifier,
                      onLeave: () {
                        onLeaveCalled();
                        Navigator.of(guardedContext).pop();
                      },
                      child: const Scaffold(body: Text('guarded')),
                    ),
                  ),
                ),
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

/// 시스템 뒤로가기 (Android back·iOS 스와이프와 같은 maybePop 경로)
Future<void> simulateSystemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

void main() {
  group('UnsavedChangesGuard 이탈 경고', () {
    testWidgets('변경 없음 > 뒤로가기 바로 닫힘, 모달 없음', (tester) async {
      final hasUnsavedChangesNotifier = ValueNotifier<bool>(false);
      addTearDown(hasUnsavedChangesNotifier.dispose);
      var leaveCallCount = 0;
      await pumpGuardedScreen(
        tester,
        hasUnsavedChangesNotifier: hasUnsavedChangesNotifier,
        onLeaveCalled: () => leaveCallCount++,
      );

      await simulateSystemBack(tester);

      expect(find.text('guarded'), findsNothing);
      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
      expect(leaveCallCount, 0); // 가드 개입 없이 일반 pop
    });

    testWidgets('변경 있음 > 뒤로가기 차단 + 확인 모달, 취소 시 화면 유지', (tester) async {
      final hasUnsavedChangesNotifier = ValueNotifier<bool>(true);
      addTearDown(hasUnsavedChangesNotifier.dispose);
      var leaveCallCount = 0;
      await pumpGuardedScreen(
        tester,
        hasUnsavedChangesNotifier: hasUnsavedChangesNotifier,
        onLeaveCalled: () => leaveCallCount++,
      );

      await simulateSystemBack(tester);

      expect(find.text('guarded'), findsOneWidget);
      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsOneWidget);

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
      expect(find.text('guarded'), findsOneWidget);
      expect(leaveCallCount, 0);
    });

    testWidgets('변경 있음 > 확인 모달에서 나가기 > 화면 닫힘', (tester) async {
      final hasUnsavedChangesNotifier = ValueNotifier<bool>(true);
      addTearDown(hasUnsavedChangesNotifier.dispose);
      var leaveCallCount = 0;
      await pumpGuardedScreen(
        tester,
        hasUnsavedChangesNotifier: hasUnsavedChangesNotifier,
        onLeaveCalled: () => leaveCallCount++,
      );

      await simulateSystemBack(tester);
      await tester.tap(find.text(UnsavedChangesGuard.leaveConfirmText));
      await tester.pumpAndSettle();

      expect(leaveCallCount, 1);
      expect(find.text('guarded'), findsNothing);
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('변경 해제(저장 성공 등) 후 뒤로가기 > 모달 없이 닫힘', (tester) async {
      final hasUnsavedChangesNotifier = ValueNotifier<bool>(true);
      addTearDown(hasUnsavedChangesNotifier.dispose);
      await pumpGuardedScreen(tester, hasUnsavedChangesNotifier: hasUnsavedChangesNotifier, onLeaveCalled: () {});

      hasUnsavedChangesNotifier.value = false;
      await tester.pump();
      await simulateSystemBack(tester);

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
      expect(find.text('guarded'), findsNothing);
    });
  });

  group('UnsavedChangesGuard 저장 중 이탈 차단', () {
    for (final hasUnsavedChanges in const [true, false]) {
      testWidgets('저장 중(변경 $hasUnsavedChanges) 뒤로가기 > 모달 없이 화면 유지', (tester) async {
        final hasUnsavedChangesNotifier = ValueNotifier<bool>(hasUnsavedChanges);
        final isLeaveBlockedNotifier = ValueNotifier<bool>(true);
        addTearDown(hasUnsavedChangesNotifier.dispose);
        addTearDown(isLeaveBlockedNotifier.dispose);
        var leaveCallCount = 0;
        await pumpGuardedScreen(
          tester,
          hasUnsavedChangesNotifier: hasUnsavedChangesNotifier,
          isLeaveBlockedNotifier: isLeaveBlockedNotifier,
          onLeaveCalled: () => leaveCallCount++,
        );

        await simulateSystemBack(tester);

        expect(find.text('guarded'), findsOneWidget);
        expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
        expect(leaveCallCount, 0);
      });
    }

    testWidgets('저장 종료(차단 해제) 후 뒤로가기 > 확인 모달 다시 표시', (tester) async {
      final hasUnsavedChangesNotifier = ValueNotifier<bool>(true);
      final isLeaveBlockedNotifier = ValueNotifier<bool>(true);
      addTearDown(hasUnsavedChangesNotifier.dispose);
      addTearDown(isLeaveBlockedNotifier.dispose);
      await pumpGuardedScreen(
        tester,
        hasUnsavedChangesNotifier: hasUnsavedChangesNotifier,
        isLeaveBlockedNotifier: isLeaveBlockedNotifier,
        onLeaveCalled: () {},
      );

      isLeaveBlockedNotifier.value = false;
      await tester.pump();
      await simulateSystemBack(tester);

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsOneWidget);
    });

    testWidgets('requestLeave 차단 중 > 모달·onLeave 없음 (앱바 뒤로가기 경로)', (tester) async {
      var leaveCallCount = 0;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: designScreenSize,
          builder: (context, child) => MaterialApp(
            home: Builder(
              builder: (screenContext) => Scaffold(
                body: ElevatedButton(
                  onPressed: () => UnsavedChangesGuard.requestLeave(
                    context: screenContext,
                    hasUnsavedChanges: true,
                    isLeaveBlocked: true,
                    onLeave: () => leaveCallCount++,
                  ),
                  child: const Text('back'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('back'));
      await tester.pumpAndSettle();

      expect(find.text(UnsavedChangesGuard.leaveConfirmMessage), findsNothing);
      expect(leaveCallCount, 0);
    });
  });
}
