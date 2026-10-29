import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/widgets/trade_request_trade_option_selector.dart';
import '../helpers/pump_design_screen.dart';

const String alreadyRequestedNotice = '이미 교환을 요청한 물품입니다.';

/// 내 물품 조회 대역: 판매중 카드 2개 (a, b)
class _FakeItemRepository implements ItemRepository {
  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async => [
    Item(itemId: 'a', itemName: '물품 A', itemCategory: 'SHOES'),
    Item(itemId: 'b', itemName: '물품 B', itemCategory: 'SHOES'),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 요청 존재 확인 대역: 카드(giveItemId)별 응답 시점을 테스트가 직접 결정
class _ControlledTradeRepository implements TradeRepository {
  final Map<String, Completer<bool>> pendingExistenceByGiveItemId = {};

  @override
  Future<bool> hasTradeRequest({required String? takeItemId, required String? giveItemId}) {
    return (pendingExistenceByGiveItemId[giveItemId!] = Completer<bool>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpFixedFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('빠른 슬라이드: 이전 카드(a) 응답이 늦게 와도 현재 카드(b) 상태 유지 (#855)', (tester) async {
    useDesignScreenView(tester);
    final tradeRepository = _ControlledTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(_FakeItemRepository()),
          tradeRepositoryProvider.overrideWithValue(tradeRepository),
        ],
        child: buildDesignScreenApp(
          home: TradeRequestScreen(
            targetItem: Item(itemId: 'target', itemName: '상대 물품'),
          ),
        ),
      ),
    );
    await pumpFixedFrames(tester);

    // a 확인 중 > b로 슬라이드 (a 응답 아직 없음)
    expect(tradeRepository.pendingExistenceByGiveItemId.keys, ['a']);
    await tester.drag(find.byType(PageView), const Offset(-219, 0));
    await pumpFixedFrames(tester);
    expect(tradeRepository.pendingExistenceByGiveItemId.keys, ['a', 'b']);

    // b 응답(요청 없음) > 선택 탭 표시
    tradeRepository.pendingExistenceByGiveItemId['b']!.complete(false);
    await pumpFixedFrames(tester);
    expect(find.byType(TradeRequestTradeOptionSelector), findsOneWidget);

    // 늦게 온 a 응답(이미 요청함) > 무시
    tradeRepository.pendingExistenceByGiveItemId['a']!.complete(true);
    await pumpFixedFrames(tester);
    expect(find.text(alreadyRequestedNotice), findsNothing);
    expect(find.byType(TradeRequestTradeOptionSelector), findsOneWidget);
  });

  testWidgets('확인 중에는 선택 탭 대신 로딩, 이미 요청한 카드는 안내 문구 (#855)', (tester) async {
    useDesignScreenView(tester);
    final tradeRepository = _ControlledTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(_FakeItemRepository()),
          tradeRepositoryProvider.overrideWithValue(tradeRepository),
        ],
        child: buildDesignScreenApp(
          home: TradeRequestScreen(
            targetItem: Item(itemId: 'target', itemName: '상대 물품'),
          ),
        ),
      ),
    );
    await pumpFixedFrames(tester);
    expect(find.byType(TradeRequestTradeOptionSelector), findsNothing);

    tradeRepository.pendingExistenceByGiveItemId['a']!.complete(true);
    await pumpFixedFrames(tester);
    expect(find.text(alreadyRequestedNotice), findsOneWidget);
    expect(find.byType(TradeRequestTradeOptionSelector), findsNothing);
  });
}
