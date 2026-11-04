import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/sent_request_progress.dart';
import 'package:romrom_fe/enums/trade_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';

/// 상태·확인 여부·추가금 지정 가능한 거래 요청 이력
TradeRequestHistory buildHistory({
  required String tradeStatus,
  bool? isNew,
  DateTime? checkedAt,
  List<String> itemTradeOptions = const [],
  int? extraChargeAmount,
}) {
  return TradeRequestHistory(
    tradeRequestHistoryId: 'history-1',
    takeItem: Item(itemId: 'take-1'),
    giveItem: Item(itemId: 'give-1'),
    itemTradeOptions: itemTradeOptions,
    tradeStatus: tradeStatus,
    isNew: isNew,
    checkedAt: checkedAt,
    extraChargeAmount: extraChargeAmount,
  );
}

void main() {
  group('TradeStatus.fromServerName', () {
    test('REJECTED > rejected, 모르는 값 > null', () {
      expect(TradeStatus.fromServerName('REJECTED'), TradeStatus.rejected);
      expect(TradeStatus.fromServerName('SOMETHING_NEW'), isNull);
    });
  });

  group('sentRequestProgress', () {
    test('거절 > 거절됨', () {
      expect(buildHistory(tradeStatus: 'REJECTED').sentRequestProgress, SentRequestProgress.rejected);
    });

    test('대기 + 확인 시각 또는 isNew false > 확인함', () {
      expect(
        buildHistory(tradeStatus: 'PENDING', checkedAt: DateTime(2026, 11, 5)).sentRequestProgress,
        SentRequestProgress.checked,
      );
      expect(buildHistory(tradeStatus: 'PENDING', isNew: false).sentRequestProgress, SentRequestProgress.checked);
    });

    test('대기 + 미확인 > 대기, 채팅 중·모르는 값 > null', () {
      expect(buildHistory(tradeStatus: 'PENDING', isNew: true).sentRequestProgress, SentRequestProgress.waiting);
      expect(buildHistory(tradeStatus: 'CHATTING').sentRequestProgress, isNull);
      expect(buildHistory(tradeStatus: 'UNKNOWN').sentRequestProgress, isNull);
    });
  });

  group('requestedExtraChargeAmount', () {
    test('추가금 방식 선택 시만 금액 노출', () {
      expect(
        buildHistory(
          tradeStatus: 'PENDING',
          itemTradeOptions: const ['EXTRA_CHARGE'],
          extraChargeAmount: 5000,
        ).requestedExtraChargeAmount,
        5000,
      );
      expect(
        buildHistory(
          tradeStatus: 'PENDING',
          itemTradeOptions: const ['DIRECT_ONLY'],
          extraChargeAmount: 5000,
        ).requestedExtraChargeAmount,
        isNull,
      );
    });
  });

  group('JSON 파싱 (#1005 신규 필드)', () {
    test('추가금·메시지·확인·거절 시각, 물품 isReserved 파싱 / 구버전 응답은 null', () {
      final history = TradeRequestHistory.fromJson({
        'tradeRequestHistoryId': 'history-1',
        'takeItem': {'itemId': 'take-1', 'isReserved': true},
        'giveItem': {'itemId': 'give-1'},
        'itemTradeOptions': ['EXTRA_CHARGE'],
        'tradeStatus': 'REJECTED',
        'extraChargeAmount': 3000,
        'requestMessage': '주말 가능해요',
        'checkedAt': '2026-11-05T10:20:00',
        'rejectedAt': '2026-11-05T11:00:00',
      });
      expect(history.extraChargeAmount, 3000);
      expect(history.requestMessage, '주말 가능해요');
      expect(history.checkedAt, DateTime(2026, 11, 5, 10, 20));
      expect(history.rejectedAt, DateTime(2026, 11, 5, 11));
      expect(history.takeItem.isReserved, isTrue);

      final legacyHistory = TradeRequestHistory.fromJson({
        'tradeRequestHistoryId': 'history-2',
        'takeItem': {'itemId': 'take-2'},
        'giveItem': {'itemId': 'give-2'},
        'itemTradeOptions': ['EXTRA_CHARGE'],
        'tradeStatus': 'PENDING',
      });
      expect(legacyHistory.extraChargeAmount, isNull);
      expect(legacyHistory.requestMessage, isNull);
      expect(legacyHistory.giveItem.isReserved, isNull);
    });

    test('읽음 변경 복사 시 신규 필드 유지', () {
      final copiedHistory = buildHistory(
        tradeStatus: 'PENDING',
        itemTradeOptions: const ['EXTRA_CHARGE'],
        extraChargeAmount: 5000,
      ).copyWithIsNew(false);
      expect(copiedHistory.extraChargeAmount, 5000);
      expect(copiedHistory.isNew, isFalse);
    });
  });
}
