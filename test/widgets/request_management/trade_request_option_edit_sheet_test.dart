import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';
import 'package:romrom_fe/utils/error_utils.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';
import 'package:romrom_fe/widgets/request_management/trade_request_option_edit_sheet.dart';
import '../../helpers/pump_design_screen.dart';

const String sheetTitle = '거래 방식 수정';

/// 거래 방식 수정 대역: 호출 기록, 응답 시점을 테스트가 결정
class ControlledUpdateTradeRepository implements TradeRepository {
  final List<List<String>> updatedTradeOptionsHistory = [];
  Completer<void> pendingUpdate = Completer<void>();

  @override
  Future<void> updateTradeOptions({required String tradeRequestHistoryId, required List<String> itemTradeOptions}) {
    updatedTradeOptionsHistory.add(itemTradeOptions);
    return pendingUpdate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 대기 상태 보낸 요청 (요청 거래 방식 지정)
TradeRequestHistory buildPendingSentRequest(List<String> itemTradeOptions) {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'sent-1',
    takeItem: Item(itemId: 'take-1'),
    giveItem: Item(itemId: 'give-1'),
    itemTradeOptions: itemTradeOptions,
    tradeStatus: 'PENDING',
  );
}

/// 시트 열기 버튼이 있는 테스트 앱 렌더 > 시트 열기
Future<void> pumpAndOpenSheet(
  WidgetTester tester,
  ControlledUpdateTradeRepository tradeRepository, {
  List<String> itemTradeOptions = const ['DIRECT_ONLY'],
}) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tradeRepositoryProvider.overrideWithValue(tradeRepository),
        itemAddressResolverProvider.overrideWithValue(ItemAddressResolver(lookupAddress: (_) async => null)),
      ],
      child: buildDesignScreenApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => TradeRequestOptionEditSheet.show(
                  context: context,
                  request: buildPendingSentRequest(itemTradeOptions),
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

/// 안내 스낵바 자동 닫힘 + 닫힘 애니메이션 대기
Future<void> waitForSnackBarDismissed(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('저장 연타 > 수정 1회만 호출, 성공 > 시트 닫힘', (tester) async {
    final tradeRepository = ControlledUpdateTradeRepository();
    await pumpAndOpenSheet(tester, tradeRepository);

    await tester.tap(find.text('택배'));
    await tester.pump();
    await tester.tap(find.byType(CompletionButton));
    await tester.pump();
    await tester.tap(find.byType(CompletionButton), warnIfMissed: false);
    await tester.pump();
    expect(tradeRepository.updatedTradeOptionsHistory.length, 1);

    tradeRepository.pendingUpdate.complete();
    await tester.pumpAndSettle();
    expect(find.text(sheetTitle), findsNothing);
    await waitForSnackBarDismissed(tester);
  });

  testWidgets('저장 실패 > 시트 유지 + 오류 안내', (tester) async {
    final tradeRepository = ControlledUpdateTradeRepository();
    await pumpAndOpenSheet(tester, tradeRepository);
    final updateError = Exception('update failed');

    await tester.tap(find.text('택배'));
    await tester.pump();
    await tester.tap(find.text('수정하기'));
    tradeRepository.pendingUpdate.completeError(updateError);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(sheetTitle), findsOneWidget);
    expect(find.text(ErrorUtils.getErrorMessage(updateError)), findsOneWidget);
    await waitForSnackBarDismissed(tester);
  });

  testWidgets('저장 중 뒤로가기(바깥 탭과 같은 maybePop 경로) > 시트 닫히지 않음', (tester) async {
    final tradeRepository = ControlledUpdateTradeRepository();
    await pumpAndOpenSheet(tester, tradeRepository);

    await tester.tap(find.text('택배'));
    await tester.pump();
    await tester.tap(find.text('수정하기'));
    await tester.pump();
    await tester.binding.handlePopRoute();
    // 닫힘 애니메이션 + 라우트 제거까지 여러 프레임 진행 (로딩 스피너 때문에 pumpAndSettle 불가)
    for (var frame = 0; frame < 5; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text(sheetTitle), findsOneWidget);

    tradeRepository.pendingUpdate.complete();
    await tester.pumpAndSettle();
    await waitForSnackBarDismissed(tester);
  });

  testWidgets('앱이 모르는 기존 거래 방식 > 선택값과 함께 그대로 전송', (tester) async {
    final tradeRepository = ControlledUpdateTradeRepository();
    await pumpAndOpenSheet(tester, tradeRepository, itemTradeOptions: const ['DIRECT_ONLY', 'FUTURE_OPTION']);

    await tester.tap(find.text('택배'));
    await tester.pump();
    await tester.tap(find.text('수정하기'));
    await tester.pump();

    expect(tradeRepository.updatedTradeOptionsHistory.single, ['DIRECT_ONLY', 'DELIVERY_ONLY', 'FUTURE_OPTION']);
    tradeRepository.pendingUpdate.complete();
    await tester.pumpAndSettle();
    await waitForSnackBarDismissed(tester);
  });
}
