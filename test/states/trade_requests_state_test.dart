import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/states/trade_requests_state.dart';

/// 거래 요청 1건: 요청자(내게 보낸 사람) = giveItem 주인, 상대(내가 보낸 대상) = takeItem 주인
TradeRequestHistory buildRequestBetween(String tradeRequestHistoryId, {String? giveOwnerId, String? takeOwnerId}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: tradeRequestHistoryId,
    takeItem: Item(
      itemId: 'take-$tradeRequestHistoryId',
      member: Member(memberId: takeOwnerId),
    ),
    giveItem: Item(
      itemId: 'give-$tradeRequestHistoryId',
      member: Member(memberId: giveOwnerId),
    ),
    itemTradeOptions: const [],
    tradeStatus: 'PENDING',
  );
}

void main() {
  group('TradeRequestsState 차단 회원 제외', () {
    final state = TradeRequestsState(
      received: [
        buildRequestBetween('received-1', giveOwnerId: 'blocked'),
        buildRequestBetween('received-2', giveOwnerId: 'friend'),
        buildRequestBetween('received-3'),
      ],
      sent: [
        buildRequestBetween('sent-1', takeOwnerId: 'friend'),
        buildRequestBetween('sent-2', takeOwnerId: 'blocked'),
      ],
    );

    test('받은 요청 > 요청자가 제외 회원이면 뺌 (요청자 모름은 유지, 순서 유지)', () {
      final visibleIds = state.receivedExcludingRequesters(const {'blocked'}).map((r) => r.tradeRequestHistoryId);

      expect(visibleIds, ['received-2', 'received-3']);
    });

    test('보낸 요청 > 상대 물품 주인이 제외 회원이면 뺌', () {
      final visibleIds = state.sentExcludingOpponents(const {'blocked'}).map((r) => r.tradeRequestHistoryId);

      expect(visibleIds, ['sent-1']);
    });

    test('제외 회원 없음 > 원본 목록 그대로 (새 목록 생성 없음)', () {
      expect(identical(state.receivedExcludingRequesters(const {}), state.received), isTrue);
      expect(identical(state.sentExcludingOpponents(const {}), state.sent), isTrue);
    });
  });

  test('받은 요청 로딩 여부 > copyWith·동등 비교 반영', () {
    const state = TradeRequestsState();
    final loadingState = state.copyWith(isReceivedLoading: true);

    expect(loadingState.isReceivedLoading, isTrue);
    expect(loadingState == state, isFalse);
    expect(loadingState.copyWith().isReceivedLoading, isTrue);
  });
}
