import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/widgets/common/empty_state_view.dart';
import 'package:romrom_fe/widgets/request_list_item_card_widget.dart';
import 'package:romrom_fe/widgets/request_management/request_received_list.dart';
import 'package:romrom_fe/widgets/request_management/request_sent_list.dart';
import 'package:romrom_fe/widgets/sent_request_item_card.dart';
import '../../helpers/pump_design_screen.dart';

/// 서버 거래 방식 값 3개: 알려진 값 2개 + 모르는 값 1개
const List<String> tradeOptionServerNamesWithUnknown = ['DIRECT_ONLY', 'UNKNOWN_OPTION', 'DELIVERY_ONLY'];

/// 요청 거래 방식에 모르는 값이 섞인 거래 요청 이력 (물품 기본 방식은 요청과 다름)
TradeRequestHistory buildRequestWithUnknownTradeOption() {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'history-1',
    takeItem: Item(itemId: 'take-1', itemName: '상대 물품', itemTradeOptions: const ['EXTRA_CHARGE']),
    giveItem: Item(itemId: 'give-1', itemName: '내 물품', itemTradeOptions: const ['EXTRA_CHARGE']),
    itemTradeOptions: tradeOptionServerNamesWithUnknown,
    tradeStatus: 'UNKNOWN_STATUS',
  );
}

/// 요청 시각·요청자·상태 지정 가능한 거래 요청 이력 (물품 등록일은 요청 시각과 다름)
TradeRequestHistory buildRequest({DateTime? requestedDate, Member? requester, String tradeStatus = 'PENDING'}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'history-2',
    takeItem: Item(itemId: 'take-2', itemName: '상대 물품', createdDate: DateTime(2020)),
    giveItem: Item(itemId: 'give-2', itemName: '내 물품', createdDate: DateTime(2020), member: requester),
    itemTradeOptions: const ['DELIVERY_ONLY'],
    tradeStatus: tradeStatus,
    createdDate: requestedDate,
  );
}

/// 받은 요청 목록 위젯 (실패 여부 지정)
RequestReceivedList buildReceivedList(List<TradeRequestHistory> requests, {bool hasLoadFailed = false}) {
  return RequestReceivedList(
    filteredRequests: requests,
    isLoading: false,
    hasLoadFailed: hasLoadFailed,
    onRetry: () {},
    onCardTap: (_) {},
    onMenuTap: (_) {},
  );
}

/// 보낸 요청 목록 위젯 (실패 여부 지정)
RequestSentList buildSentList(List<TradeRequestHistory> requests, {bool hasLoadFailed = false}) {
  return RequestSentList(
    sentRequests: requests,
    isLoading: false,
    hasLoadFailed: hasLoadFailed,
    onRetry: () {},
    currentSort: RequestSortType.latest,
    onSortChanged: (_) {},
    onCardTap: (_) {},
    onEditTap: (_) {},
    onCancelTap: (_) {},
  );
}

/// 테스트 앱 렌더 (ScreenUtil 초기화 포함, 목록 sliver를 스크롤 뷰에 배치)
Future<void> pumpRequestListWidget(WidgetTester tester, Widget requestListSliver) async {
  await tester.pumpWidget(
    buildDesignScreenApp(
      home: Scaffold(body: CustomScrollView(slivers: [requestListSliver])),
    ),
  );
  await tester.pump(const Duration(seconds: 1));
}

/// 거래 요청 N건 (ID만 다름)
List<TradeRequestHistory> buildRequests(int count) => [
  for (var index = 0; index < count; index++)
    TradeRequestHistory(
      tradeRequestHistoryId: 'history-$index',
      takeItem: Item(itemId: 'take-$index', itemName: '상대 물품 $index'),
      giveItem: Item(itemId: 'give-$index', itemName: '내 물품 $index'),
      itemTradeOptions: const [],
      tradeStatus: 'PENDING',
    ),
];

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
    testWidgets('보낸 요청 > 물품 기본 방식이 아니라 요청 거래 방식, 모르는 값 제외 (예외 없음)', (tester) async {
      await pumpRequestListWidget(tester, buildSentList([buildRequestWithUnknownTradeOption()]));

      expect(tester.takeException(), isNull);
      final sentCard = tester.widget<SentRequestItemCard>(find.byType(SentRequestItemCard));
      expect(sentCard.tradeOptions, [ItemTradeOption.directTradeOnly, ItemTradeOption.deliveryOnly]);
    });

    testWidgets('받은 요청 > 물품 기본 방식이 아니라 요청 거래 방식, 모르는 값 제외 (예외 없음)', (tester) async {
      await pumpRequestListWidget(tester, buildReceivedList([buildRequestWithUnknownTradeOption()]));

      expect(tester.takeException(), isNull);
      final receivedCard = tester.widget<RequestListItemCardWidget>(find.byType(RequestListItemCardWidget));
      expect(receivedCard.tradeOptions, [ItemTradeOption.directTradeOnly, ItemTradeOption.deliveryOnly]);
    });
  });

  group('요청 목록: 요청 자체 정보', () {
    testWidgets('받은 요청 > 요청 시각·요청자 닉네임·프로필 전달 (물품 등록일 아님)', (tester) async {
      final requestedDate = DateTime.now().subtract(const Duration(minutes: 5));
      await pumpRequestListWidget(
        tester,
        buildReceivedList([
          buildRequest(
            requestedDate: requestedDate,
            requester: Member(nickname: '요청자', profileUrl: 'https://example.com/profile.png'),
          ),
        ]),
      );

      final receivedCard = tester.widget<RequestListItemCardWidget>(find.byType(RequestListItemCardWidget));
      expect(receivedCard.requestedDate, requestedDate);
      expect(receivedCard.requesterNickname, '요청자');
      expect(receivedCard.requesterProfileUrl, 'https://example.com/profile.png');
      expect(find.text('요청자'), findsOneWidget);
      expect(find.text('5분 전'), findsOneWidget);
    });

    testWidgets('받은 요청 > 요청 시각·요청자 없음 > 시간·요청자 행 생략 (예외 없음)', (tester) async {
      await pumpRequestListWidget(tester, buildReceivedList([buildRequest()]));

      expect(tester.takeException(), isNull);
      final receivedCard = tester.widget<RequestListItemCardWidget>(find.byType(RequestListItemCardWidget));
      expect(receivedCard.requestedDate, isNull);
      expect(receivedCard.requesterNickname, isNull);
    });

    testWidgets('보낸 요청 > 요청 시각 전달, 대기 상태만 수정 가능', (tester) async {
      final requestedDate = DateTime(2026, 11, 3);
      await pumpRequestListWidget(
        tester,
        buildSentList([buildRequest(requestedDate: requestedDate), buildRequest(tradeStatus: 'CHATTING')]),
      );

      final sentCards = tester.widgetList<SentRequestItemCard>(find.byType(SentRequestItemCard)).toList();
      expect(sentCards.first.requestedDate, requestedDate);
      expect(sentCards.map((card) => card.canEdit), [true, false]);
    });
  });

  group('요청 목록: 지연 생성', () {
    // 목록 항목 수 (한 화면을 크게 넘는 수)
    const int longListCount = 30;

    testWidgets('받은 요청 30건 > 화면 근처 항목만 생성, 스크롤하면 마지막 항목 생성', (tester) async {
      useDesignScreenView(tester);
      await pumpRequestListWidget(tester, buildReceivedList(buildRequests(longListCount)));

      final builtCount = find.byType(RequestListItemCardWidget).evaluate().length;
      expect(builtCount, greaterThan(0));
      expect(builtCount, lessThan(longListCount));

      await tester.scrollUntilVisible(
        find.text('내 물품 ${longListCount - 1}'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('내 물품 ${longListCount - 1}'), findsOneWidget);
    });

    testWidgets('보낸 요청 30건 > 화면 근처 항목만 생성', (tester) async {
      useDesignScreenView(tester);
      await pumpRequestListWidget(tester, buildSentList(buildRequests(longListCount)));

      final builtCount = find.byType(SentRequestItemCard).evaluate().length;
      expect(builtCount, greaterThan(0));
      expect(builtCount, lessThan(longListCount));
    });
  });

  group('요청 목록: 조회 실패', () {
    testWidgets('받은 요청 조회 실패 > 없음 문구 대신 다시 시도', (tester) async {
      await pumpRequestListWidget(tester, buildReceivedList(const [], hasLoadFailed: true));

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('진행 중인 요청이 없습니다'), findsNothing);
    });

    testWidgets('보낸 요청 조회 실패 > 없음 문구 대신 다시 시도', (tester) async {
      await pumpRequestListWidget(tester, buildSentList(const [], hasLoadFailed: true));

      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.text('보낸 요청이 없습니다'), findsNothing);
    });

    testWidgets('보낸 요청 일부 카드 실패 > 성공 결과 목록 유지 + 상단 일부 실패 배너', (tester) async {
      await pumpRequestListWidget(tester, buildSentList([buildRequest()], hasLoadFailed: true));

      expect(find.byType(SentRequestItemCard), findsOneWidget);
      expect(find.text('일부를 불러오지 못했어요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
      expect(find.byType(EmptyStateView), findsNothing);
    });

    testWidgets('조회 성공 + 빈 목록 > 없음 문구', (tester) async {
      await pumpRequestListWidget(tester, buildReceivedList(const []));

      expect(find.text('진행 중인 요청이 없습니다'), findsOneWidget);
      expect(find.text('다시 시도'), findsNothing);
    });
  });
}
