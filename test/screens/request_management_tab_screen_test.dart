import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/enums/request_sort_type.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/providers/item_address_resolver_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/screens/request_management_tab_screen.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';
import '../helpers/pump_design_screen.dart';

/// 내 물품 조회 대역: 판매중 카드 기본 2개 (a, b), 테스트에서 교체 가능
class _FakeItemRepository implements ItemRepository {
  List<Item> availableItems = [
    Item(itemId: 'a', itemName: '물품 A', itemCategory: 'SHOES'),
    Item(itemId: 'b', itemName: '물품 B', itemCategory: 'SHOES'),
  ];

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    if (status != ItemStatus.available) return const [];
    return availableItems;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 거래 요청 조회 대역: 호출 기록만 (응답 빈 목록)
class _CountingTradeRepository implements TradeRepository {
  final List<String> receivedRequestedTakeItemIds = [];
  final List<String> sentRequestedGiveItemIds = [];

  @override
  Future<List<TradeRequestHistory>> getReceived({
    required String takeItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    receivedRequestedTakeItemIds.add(takeItemId);
    return const [];
  }

  @override
  Future<List<TradeRequestHistory>> getSent({
    required String giveItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    sentRequestedGiveItemIds.add(giveItemId);
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 내 물품 로드 > 거래 요청 로드 반영 (무한 애니메이션 위젯 대비 고정 pump)
Future<void> pumpFixedFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('요청관리 탭 첫 진입 > 받은 요청 1회(첫 카드)·보낸 요청 카드별 1회 조회', (tester) async {
    useDesignScreenView(tester);
    final tradeRepository = _CountingTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(_FakeItemRepository()),
          tradeRepositoryProvider.overrideWithValue(tradeRepository),
          itemAddressResolverProvider.overrideWithValue(ItemAddressResolver(lookupAddress: (_) async => null)),
        ],
        child: buildDesignScreenApp(home: const RequestManagementTabScreen()),
      ),
    );
    await pumpFixedFrames(tester);

    expect(tradeRepository.receivedRequestedTakeItemIds, ['a']);
    expect(tradeRepository.sentRequestedGiveItemIds, ['a', 'b']);
    expect(find.text('물품 A'), findsOneWidget);
  });

  testWidgets('카드 목록 감소(마지막 카드 위치에서 다른 곳 거래 완료) > 현재 카드 위치 보정 후 마지막 카드 받은 요청 재조회', (tester) async {
    useDesignScreenView(tester);
    final itemRepository = _FakeItemRepository();
    final tradeRepository = _CountingTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(itemRepository),
          tradeRepositoryProvider.overrideWithValue(tradeRepository),
          itemAddressResolverProvider.overrideWithValue(ItemAddressResolver(lookupAddress: (_) async => null)),
        ],
        child: buildDesignScreenApp(home: const RequestManagementTabScreen()),
      ),
    );
    await pumpFixedFrames(tester);
    // 두 번째 카드(b)로 이동
    await tester.drag(find.byType(PageView), const Offset(-219, 0));
    await pumpFixedFrames(tester);
    expect(tradeRepository.receivedRequestedTakeItemIds.last, 'b');

    // b 거래 완료 > 내 물품 재조회 (a만 남음)
    itemRepository.availableItems = [Item(itemId: 'a', itemName: '물품 A', itemCategory: 'SHOES')];
    final container = ProviderScope.containerOf(tester.element(find.byType(RequestManagementTabScreen)));
    await container.read(myItemsProvider.notifier).reload();
    await pumpFixedFrames(tester);

    expect(tradeRepository.receivedRequestedTakeItemIds.last, 'a');
    expect(find.text('물품 A'), findsOneWidget);
  });
}
