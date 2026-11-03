import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

/// 요청 시각·요청 거래 방식과 물품 등록일·물품 기본 거래 방식이 서로 다른 이력
TradeRequestHistory buildRequestDifferentFromItem({DateTime? requestCreatedDate, Member? requester}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'history-1',
    takeItem: Item(itemId: 'take-1', createdDate: DateTime(2026, 1, 1), itemTradeOptions: const ['DIRECT_ONLY']),
    giveItem: Item(
      itemId: 'give-1',
      createdDate: DateTime(2026, 1, 2),
      itemTradeOptions: const ['DIRECT_ONLY'],
      member: requester,
    ),
    itemTradeOptions: const ['DELIVERY_ONLY', 'UNKNOWN_OPTION'],
    tradeStatus: 'PENDING',
    createdDate: requestCreatedDate,
  );
}

void main() {
  group('TradeRequestHistoryDisplayX', () {
    test('requestedDate: 물품 등록일이 아니라 요청 생성 시각', () {
      final requestCreatedDate = DateTime(2026, 11, 3, 10);
      final request = buildRequestDifferentFromItem(requestCreatedDate: requestCreatedDate);

      expect(request.requestedDate, requestCreatedDate);
    });

    test('requestedDate: 요청 시각 없음 > null (물품 등록일로 대체하지 않음)', () {
      expect(buildRequestDifferentFromItem().requestedDate, isNull);
    });

    test('requestedTradeOptions: 물품 기본 방식이 아니라 요청 시 고른 방식 (모르는 값 제외)', () {
      expect(buildRequestDifferentFromItem().requestedTradeOptions, [ItemTradeOption.deliveryOnly]);
    });

    test('requester: 요청 보낸 물품(giveItem)의 회원', () {
      final requester = Member(memberId: 'requester-1', nickname: '요청자');

      expect(buildRequestDifferentFromItem(requester: requester).requester?.nickname, '요청자');
      expect(buildRequestDifferentFromItem().requester, isNull);
    });
  });
}
