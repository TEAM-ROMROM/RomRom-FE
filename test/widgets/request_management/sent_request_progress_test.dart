import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/request_management/request_sent_list.dart';
import '../../helpers/pump_design_screen.dart';

/// 보낸 요청 1건 (상태·확인·추가금·메시지 지정)
TradeRequestHistory buildSentRequest({
  required String tradeStatus,
  bool? isNew,
  int? extraChargeAmount,
  String? message,
}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'history-$tradeStatus-$isNew',
    takeItem: Item(itemId: 'take-1', itemName: '상대 물품'),
    giveItem: Item(itemId: 'give-1', itemName: '내 물품'),
    itemTradeOptions: const ['EXTRA_CHARGE'],
    tradeStatus: tradeStatus,
    isNew: isNew,
    extraChargeAmount: extraChargeAmount,
    requestMessage: message,
  );
}

Future<void> pumpSentList(WidgetTester tester, List<TradeRequestHistory> sentRequests) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            RequestSentList(
              sentRequests: sentRequests,
              isLoading: false,
              hasLoadFailed: false,
              onRetry: () {},
              currentSort: RequestSortType.latest,
              onSortChanged: (_) {},
              onCardTap: (_) {},
              onEditTap: (_) {},
              onCancelTap: (_) {},
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('보낸 요청: 대기·확인함·거절됨 태그 + 추가금·메시지 표시', (tester) async {
    useDesignScreenView(tester, screenSize: const Size(393, 2000));
    await pumpSentList(tester, [
      buildSentRequest(tradeStatus: 'PENDING', isNew: true, extraChargeAmount: 5000, message: '주말 가능해요'),
      buildSentRequest(tradeStatus: 'PENDING', isNew: false),
      buildSentRequest(tradeStatus: 'REJECTED'),
    ]);

    expect(tester.takeException(), isNull);
    expect(find.text('대기'), findsOneWidget);
    expect(find.text('확인함'), findsOneWidget);
    expect(find.text('거절됨'), findsOneWidget);
    expect(find.text('추가금 5,000원'), findsOneWidget);
    expect(find.text('"주말 가능해요"'), findsOneWidget);
    // 거절 건은 수정·취소 메뉴 없음 (대기 2건만)
    expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
  });
}
