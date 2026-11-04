import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/member_withdrawal_reason.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/screens/my_page/member_withdrawal_screen.dart';
import 'package:romrom_fe/services/session_navigation_handler.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

import '../helpers/pump_design_screen.dart';

/// 탈퇴 화면: 사라지는 정보 안내 > 사유·동의 전 버튼 비활성 > 진행 중 거래 안내 > 탈퇴 1회 (진행 중 중복 차단)
void main() {
  tearDown(SessionNavigationHandler.unregister);

  Future<void> pumpWithdrawalScreen(
    WidgetTester tester,
    MemberWithdrawalRequest deleteAccount, {
    List<TradeRequestHistory> ongoingTrades = const [],
  }) async {
    useDesignScreenView(tester, screenSize: const Size(393, 1400));
    await tester.pumpWidget(
      ProviderScope(
        child: buildDesignScreenApp(
          home: MemberWithdrawalScreen(deleteAccount: deleteAccount, loadOngoingTrades: () async => ongoingTrades),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> selectReasonAndAgree(WidgetTester tester) async {
    await tester.tap(find.text(MemberWithdrawalReason.noWantedItems.label));
    await tester.pump();
    await tester.tap(find.text(MemberWithdrawalScreen.agreementLabel));
    await tester.pump();
  }

  TradeRequestHistory buildOngoingTrade(String takeItemName, String giveItemName) {
    return TradeRequestHistory(
      tradeRequestHistoryId: '$takeItemName-$giveItemName',
      takeItem: Item(itemName: takeItemName),
      giveItem: Item(itemName: giveItemName),
      itemTradeOptions: const [],
      tradeStatus: 'PENDING',
    );
  }

  testWidgets('사라지는 정보·탈퇴 사유 표시', (tester) async {
    await pumpWithdrawalScreen(tester, ({withdrawalReason, withdrawalReasonDetail}) async => true);

    for (final deletedInformation in MemberWithdrawalScreen.deletedInformationLabels) {
      expect(find.text(deletedInformation), findsOneWidget);
    }
    for (final reason in MemberWithdrawalReason.values) {
      expect(find.text(reason.label), findsOneWidget);
    }
  });

  testWidgets('동의만 하고 사유 미선택 > 탈퇴 요청 없음', (tester) async {
    var deleteCallCount = 0;
    await pumpWithdrawalScreen(tester, ({withdrawalReason, withdrawalReasonDetail}) async {
      deleteCallCount++;
      return true;
    });

    await tester.tap(find.text(MemberWithdrawalScreen.agreementLabel));
    await tester.pump();
    await tester.tap(find.text('탈퇴하기'));
    await tester.pumpAndSettle();

    expect(deleteCallCount, 0);
  });

  testWidgets('사유·동의 후 탈퇴 버튼 연속 탭 > 사유 포함 탈퇴 요청 1회, 성공 시 로그아웃 전환 알림', (tester) async {
    var deleteCallCount = 0;
    var loggedOutCount = 0;
    MemberWithdrawalReason? sentReason;
    String? sentReasonDetail;
    SessionNavigationHandler.register(
      onAccountSuspended: (_, _) {},
      onSessionExpired: () {},
      onLoggedOut: () => loggedOutCount++,
    );
    final deleteCompleter = Completer<bool>();
    await pumpWithdrawalScreen(tester, ({withdrawalReason, withdrawalReasonDetail}) {
      deleteCallCount++;
      sentReason = withdrawalReason;
      sentReasonDetail = withdrawalReasonDetail;
      return deleteCompleter.future;
    });

    await selectReasonAndAgree(tester);
    await tester.enterText(find.byType(TextField), '찾는 물건이 없어요');
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();
    await tester.tap(find.byType(CompletionButton), warnIfMissed: false); // 진행 중 재탭
    await tester.pump();
    expect(deleteCallCount, 1);
    expect(sentReason, MemberWithdrawalReason.noWantedItems);
    expect(sentReasonDetail, '찾는 물건이 없어요');

    deleteCompleter.complete(true);
    await tester.pump();
    expect(loggedOutCount, 1);
  });

  testWidgets('진행 중 거래 있음 > 안내 모달, 취소 시 탈퇴 안 함, 확인 시 탈퇴', (tester) async {
    var deleteCallCount = 0;
    await pumpWithdrawalScreen(tester, ({withdrawalReason, withdrawalReasonDetail}) async {
      deleteCallCount++;
      return true;
    }, ongoingTrades: [buildOngoingTrade('내 운동화', '상대 가방')]);

    await selectReasonAndAgree(tester);
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump(const Duration(seconds: 1)); // 모달 표시 중 버튼 로딩 애니메이션 > 고정 시간
    expect(find.textContaining('내 운동화 ↔ 상대 가방'), findsOneWidget);

    await tester.tap(find.text('취소'));
    await tester.pump(const Duration(seconds: 1)); // 모달 표시 중 버튼 로딩 애니메이션 > 고정 시간
    expect(deleteCallCount, 0);

    await tester.tap(find.text('탈퇴하기'));
    await tester.pump(const Duration(seconds: 1)); // 모달 표시 중 버튼 로딩 애니메이션 > 고정 시간
    await tester.tap(find.text(MemberWithdrawalScreen.ongoingTradeConfirmText));
    // 성공 후 세션 종료 대기 중 버튼 로딩 표시 유지 > pumpAndSettle 대신 고정 시간
    await tester.pump(const Duration(seconds: 1));
    expect(deleteCallCount, 1);
  });

  testWidgets('탈퇴 요청 중 화면이 사라져도 성공하면 로그아웃 전환 알림', (tester) async {
    var loggedOutCount = 0;
    SessionNavigationHandler.register(
      onAccountSuspended: (_, _) {},
      onSessionExpired: () {},
      onLoggedOut: () => loggedOutCount++,
    );
    final deleteCompleter = Completer<bool>();
    await pumpWithdrawalScreen(tester, ({withdrawalReason, withdrawalReasonDetail}) => deleteCompleter.future);

    await selectReasonAndAgree(tester);
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();
    await tester.pumpWidget(buildDesignScreenApp(home: const SizedBox.shrink())); // 화면 해제

    deleteCompleter.complete(true);
    await tester.pump();
    expect(loggedOutCount, 1);
  });

  testWidgets('탈퇴 요청 중 뒤로 가기 차단', (tester) async {
    final deleteCompleter = Completer<bool>();
    await pumpWithdrawalScreen(tester, ({withdrawalReason, withdrawalReasonDetail}) => deleteCompleter.future);

    await selectReasonAndAgree(tester);
    await tester.tap(find.text('탈퇴하기'));
    await tester.pump();
    await tester.pump();

    final popScope = tester.widget<PopScope>(find.byType(PopScope).first);
    expect(popScope.canPop, isFalse);
    deleteCompleter.complete(true);
    await tester.pump();
  });
}
