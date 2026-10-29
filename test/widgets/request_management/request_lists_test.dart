import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';
import 'package:romrom_fe/widgets/request_management/request_received_list.dart';
import 'package:romrom_fe/widgets/request_management/request_sent_list.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';
import '../../helpers/pump_design_screen.dart';

/// 서버 거래 방식 값 3개: 알려진 값 2개 + 모르는 값 1개
const List<String> tradeOptionServerNamesWithUnknown = ['DIRECT_ONLY', 'UNKNOWN_OPTION', 'DELIVERY_ONLY'];

/// 모르는 거래 방식이 섞인 거래 요청 이력
TradeRequestHistory buildRequestWithUnknownTradeOption() {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'history-1',
    takeItem: Item(itemId: 'take-1', itemName: '상대 물품', itemTradeOptions: tradeOptionServerNamesWithUnknown),
    giveItem: Item(itemId: 'give-1', itemName: '내 물품', itemTradeOptions: tradeOptionServerNamesWithUnknown),
    itemTradeOptions: const [],
    tradeStatus: 'UNKNOWN_STATUS',
  );
}

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함, 세로 넘침 방지 스크롤)
Future<void> pumpRequestListWidget(WidgetTester tester, Widget requestListWidget) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(body: SingleChildScrollView(child: requestListWidget)),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  group('ItemTradeOption.fromServerNamesSkippingUnknown', () {
    test('모르는 값 제외, 순서 유지, null > 빈 목록', () {
      expect(ItemTradeOption.fromServerNamesSkippingUnknown(tradeOptionServerNamesWithUnknown), [
        ItemTradeOption.directTradeOnly,
        ItemTradeOption.deliveryOnly,
      ]);
      expect(ItemTradeOption.fromServerNamesSkippingUnknown(null), isEmpty);
    });
  });

  group('요청 목록: 모르는 서버 값', () {
    testWidgets('보낸 요청 > 모르는 거래 방식 제외하고 표시 (예외 없음)', (tester) async {
      await pumpRequestListWidget(
        tester,
        RequestSentList(
          sentRequests: [buildRequestWithUnknownTradeOption()],
          isLoading: false,
          currentSort: RequestSortType.latest,
          onSortChanged: (_) {},
          onCardTap: (_) {},
          onEditTap: (_) {},
          onCancelTap: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      final sentCard = tester.widget<SentRequestItemCard>(find.byType(SentRequestItemCard));
      expect(sentCard.tradeOptions, [ItemTradeOption.directTradeOnly, ItemTradeOption.deliveryOnly]);
    });

    testWidgets('받은 요청 > 모르는 거래 방식 제외하고 표시 (예외 없음)', (tester) async {
      await pumpRequestListWidget(
        tester,
        RequestReceivedList(
          filteredRequests: [buildRequestWithUnknownTradeOption()],
          isLoading: false,
          onCardTap: (_) {},
          onMenuTap: (_) {},
        ),
      );

      expect(tester.takeException(), isNull);
      final receivedCard = tester.widget<RequestListItemCardWidget>(find.byType(RequestListItemCardWidget));
      expect(receivedCard.tradeOptions, [ItemTradeOption.directTradeOnly, ItemTradeOption.deliveryOnly]);
    });
  });
}
