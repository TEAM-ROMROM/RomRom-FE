import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/screens/my_page/member_withdrawal_screen.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

import '../helpers/pump_design_screen.dart';

/// 탈퇴 화면: 사라지는 정보 안내 > 동의 전 버튼 비활성 > 동의 후 탈퇴 1회 (진행 중 중복 차단)
void main() {
  tearDown(SessionNavigationHandler.unregister);

  Future<void> pumpWithdrawalScreen(WidgetTester tester, Future<bool> Function() deleteAccount) async {
    useDesignScreenView(tester);
    await tester.pumpWidget(buildDesignScreenApp(home: MemberWithdrawalScreen(deleteAccount: deleteAccount)));
    await tester.pumpAndSettle();
  }

  testWidgets('사라지는 정보 안내 표시', (tester) async {
    await pumpWithdrawalScreen(tester, () async => true);

    for (final deletedInformation in MemberWithdrawalScreen.deletedInformationLabels) {
      expect(find.text(deletedInformation), findsOneWidget);
    }
  });

  testWidgets('동의 전 탈퇴 버튼 탭 > 탈퇴 요청 없음', (tester) async {
    var deleteCallCount = 0;
    await pumpWithdrawalScreen(tester, () async {
      deleteCallCount++;
      return true;
    });

    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(deleteCallCount, 0);
  });

  testWidgets('동의 후 탈퇴 버튼 연속 탭 > 탈퇴 요청 1회, 성공 시 로그아웃 전환 알림', (tester) async {
    var deleteCallCount = 0;
    var loggedOutCount = 0;
    SessionNavigationHandler.register(
      onAccountSuspended: (_, _) {},
      onSessionExpired: () {},
      onLoggedOut: () => loggedOutCount++,
    );
    final deleteCompleter = Completer<bool>();
    await pumpWithdrawalScreen(tester, () {
      deleteCallCount++;
      return deleteCompleter.future;
    });

    await tester.tap(find.text(MemberWithdrawalScreen.agreementLabel));
    await tester.pump();
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();
    await tester.tap(find.byType(CompletionButton), warnIfMissed: false); // 진행 중 재탭
    expect(deleteCallCount, 1);

    deleteCompleter.complete(true);
    await tester.pump();
    expect(loggedOutCount, 1);
  });

  testWidgets('탈퇴 요청 중 화면이 사라져도 성공하면 로그아웃 전환 알림', (tester) async {
    var loggedOutCount = 0;
    SessionNavigationHandler.register(
      onAccountSuspended: (_, _) {},
      onSessionExpired: () {},
      onLoggedOut: () => loggedOutCount++,
    );
    final deleteCompleter = Completer<bool>();
    await pumpWithdrawalScreen(tester, () => deleteCompleter.future);

    await tester.tap(find.text(MemberWithdrawalScreen.agreementLabel));
    await tester.pump();
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();
    await tester.pumpWidget(buildDesignScreenApp(home: const SizedBox.shrink())); // 화면 해제

    deleteCompleter.complete(true);
    await tester.pump();
    expect(loggedOutCount, 1);
  });

  testWidgets('탈퇴 요청 중 뒤로 가기 차단', (tester) async {
    final deleteCompleter = Completer<bool>();
    await pumpWithdrawalScreen(tester, () => deleteCompleter.future);

    await tester.tap(find.text(MemberWithdrawalScreen.agreementLabel));
    await tester.pump();
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
    expect(popScope.canPop, isFalse);
    deleteCompleter.complete(true);
    await tester.pump();
  });
}
