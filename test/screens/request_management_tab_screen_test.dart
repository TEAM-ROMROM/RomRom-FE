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
import 'package:romrom_fe/providers/sent_requests_focus_trigger_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/screens/request_management_tab_screen.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';
import '../helpers/pump_design_screen.dart';

/// 내 물품 조회 대역: 판매중 카드 기본 2개 (a, b), 테스트에서 교체 가능
class FakeAvailableItemRepository implements ItemRepository {
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

/// 거래 요청 조회 대역: 호출 기록만 (응답 빈 목록, 받은 요청 실패 지정 가능)
class CountingTradeRepository implements TradeRepository {
  final List<String> receivedRequestedTakeItemIds = [];
  final List<String> sentRequestedGiveItemIds = [];
  bool shouldFailReceived = false;

  @override
  Future<List<TradeRequestHistory>> getReceived({
    required String takeItemId,
    RequestSortType sortType = RequestSortType.latest,
  }) async {
    receivedRequestedTakeItemIds.add(takeItemId);
    if (shouldFailReceived) throw Exception('received failed');
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

/// 요청관리 탭 렌더 (저장소 대역 주입)
Future<void> pumpRequestManagementTab(
  WidgetTester tester, {
  required FakeAvailableItemRepository itemRepository,
  required CountingTradeRepository tradeRepository,
}) async {
  useDesignScreenView(tester);
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
}

void main() {
  testWidgets('요청관리 탭 첫 진입 > 받은 요청 1회(첫 카드)·보낸 요청 카드별 1회 조회', (tester) async {
    useDesignScreenView(tester);
    final tradeRepository = CountingTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(FakeAvailableItemRepository()),
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
    final itemRepository = FakeAvailableItemRepository();
    final tradeRepository = CountingTradeRepository();

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

  testWidgets('판매중 물품 12개 > 10개 제한 없이 모든 카드 보낸 요청 조회, 인디케이터는 숫자 표시', (tester) async {
    final itemRepository = FakeAvailableItemRepository()
      ..availableItems = [
        for (var index = 0; index < 12; index++)
          Item(itemId: 'item-$index', itemName: '물품 $index', itemCategory: 'SHOES'),
      ];
    final tradeRepository = CountingTradeRepository();

    await pumpRequestManagementTab(tester, itemRepository: itemRepository, tradeRepository: tradeRepository);

    expect(tradeRepository.sentRequestedGiveItemIds, [for (var index = 0; index < 12; index++) 'item-$index']);
    expect(find.text('1 / 12'), findsOneWidget);
  });

  testWidgets('받은 요청 조회 실패 > 다시 시도 표시, 탭 > 현재 카드 재조회', (tester) async {
    final tradeRepository = CountingTradeRepository()..shouldFailReceived = true;
    await pumpRequestManagementTab(
      tester,
      itemRepository: FakeAvailableItemRepository(),
      tradeRepository: tradeRepository,
    );

    expect(find.text('진행 중인 요청이 없습니다'), findsNothing);
    await tester.ensureVisible(find.text('다시 시도'));
    await tester.pump();
    tradeRepository.shouldFailReceived = false;
    await tester.tap(find.text('다시 시도'));
    await pumpFixedFrames(tester);

    expect(tradeRepository.receivedRequestedTakeItemIds, ['a', 'a']);
    expect(find.text('진행 중인 요청이 없습니다'), findsOneWidget);
  });

  testWidgets('보낸 요청 보기 신호 > 보낸 요청 토글 전환 후 신호 소비', (tester) async {
    await pumpRequestManagementTab(
      tester,
      itemRepository: FakeAvailableItemRepository(),
      tradeRepository: CountingTradeRepository(),
    );
    expect(find.text('보낸 요청이 없습니다'), findsNothing);

    final container = ProviderScope.containerOf(tester.element(find.byType(RequestManagementTabScreen)));
    container.read(sentRequestsFocusTriggerProvider.notifier).trigger();
    await pumpFixedFrames(tester);

    expect(find.text('보낸 요청이 없습니다'), findsOneWidget);
    expect(container.read(sentRequestsFocusTriggerProvider), isFalse);
  });
}
