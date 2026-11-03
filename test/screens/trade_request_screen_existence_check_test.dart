import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/providers/current_tab_index_provider.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/sent_requests_focus_trigger_provider.dart';
import 'package:romrom_fe/providers/trade_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/repositories/trade_repository.dart';
import 'package:romrom_fe/screens/trade_request_screen.dart';
import 'package:romrom_fe/widgets/trade_request_trade_option_selector.dart';
import '../helpers/pump_design_screen.dart';

const String alreadyRequestedNotice = '이미 교환을 요청한 물품입니다.';
const String existenceCheckFailedNotice = '요청 여부를 확인하지 못했어요.';

/// 판매중 내 물품 1개 (카드 이름 '물품 {id}')
Item buildMyItem(String itemId) => Item(itemId: itemId, itemName: '물품 $itemId', itemCategory: 'SHOES');

/// 내 물품 조회 대역: 페이지 번호별 응답(기본 1페이지 a, b), 요청한 페이지 번호 기록
class FakeMyItemsPageRepository implements ItemRepository {
  Map<int, List<Item>> itemsByPageNumber = {
    0: [buildMyItem('a'), buildMyItem('b')],
  };
  final List<int> requestedPageNumbers = [];

  // 조회 실패시킬 페이지 번호
  Set<int> failingPageNumbers = {};

  // true > 모든 페이지에 새 물품 1개 + 다음 페이지 있음 (끝없는 목록)
  bool isEndless = false;

  @override
  Future<({List<Item> items, bool hasMore})> getMyItemsPage(
    ItemStatus status, {
    required int pageNumber,
    required int pageSize,
  }) async {
    requestedPageNumbers.add(pageNumber);
    if (failingPageNumbers.contains(pageNumber)) throw Exception('page failed');
    if (isEndless) return (items: [buildMyItem('endless-$pageNumber')], hasMore: true);
    return (
      items: itemsByPageNumber[pageNumber] ?? const <Item>[],
      hasMore: itemsByPageNumber.containsKey(pageNumber + 1),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 요청 존재 확인 대역: 카드(giveItemId)별 응답 시점을 테스트가 직접 결정, 호출 기록
class ControlledTradeRepository implements TradeRepository {
  final Map<String, Completer<bool>> pendingExistenceByGiveItemId = {};
  final List<String> checkedGiveItemIds = [];

  @override
  Future<bool> hasTradeRequest({required String? takeItemId, required String? giveItemId}) {
    checkedGiveItemIds.add(giveItemId!);
    return (pendingExistenceByGiveItemId[giveItemId] = Completer<bool>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> pumpFixedFrames(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// 교환 요청 화면 렌더 (저장소 대역 주입, 홈에서 고른 카드 지정 가능)
Future<void> pumpTradeRequestScreen(
  WidgetTester tester, {
  required FakeMyItemsPageRepository itemRepository,
  required ControlledTradeRepository tradeRepository,
  String? preSelectedCardId,
}) async {
  useDesignScreenView(tester);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        itemRepositoryProvider.overrideWithValue(itemRepository),
        tradeRepositoryProvider.overrideWithValue(tradeRepository),
      ],
      child: buildDesignScreenApp(
        home: TradeRequestScreen(
          targetItem: Item(itemId: 'target', itemName: '상대 물품'),
          preSelectedCardId: preSelectedCardId,
        ),
      ),
    ),
  );
  await pumpFixedFrames(tester);
}

void main() {
  testWidgets('빠른 슬라이드: 이전 카드(a) 응답이 늦게 와도 현재 카드(b) 상태 유지 (#855)', (tester) async {
    useDesignScreenView(tester);
    final tradeRepository = ControlledTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(FakeMyItemsPageRepository()),
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
    final tradeRepository = ControlledTradeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          itemRepositoryProvider.overrideWithValue(FakeMyItemsPageRepository()),
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

  testWidgets('요청 확인 실패 > 요청 없음으로 처리하지 않고 실패 안내, 다시 확인 > 재조회', (tester) async {
    final tradeRepository = ControlledTradeRepository();
    await pumpTradeRequestScreen(tester, itemRepository: FakeMyItemsPageRepository(), tradeRepository: tradeRepository);

    tradeRepository.pendingExistenceByGiveItemId['a']!.completeError(Exception('check failed'));
    await pumpFixedFrames(tester);
    expect(find.text(existenceCheckFailedNotice), findsOneWidget);
    expect(find.byType(TradeRequestTradeOptionSelector), findsNothing);

    await tester.tap(find.text('다시 확인'));
    await pumpFixedFrames(tester);
    expect(tradeRepository.checkedGiveItemIds, ['a', 'a']);

    tradeRepository.pendingExistenceByGiveItemId['a']!.complete(false);
    await pumpFixedFrames(tester);
    expect(find.byType(TradeRequestTradeOptionSelector), findsOneWidget);
  });

  testWidgets('이미 요청한 물품 > 보낸 요청 보기 탭 > 요청관리 탭 + 보낸 요청 신호', (tester) async {
    final tradeRepository = ControlledTradeRepository();
    await pumpTradeRequestScreen(tester, itemRepository: FakeMyItemsPageRepository(), tradeRepository: tradeRepository);
    tradeRepository.pendingExistenceByGiveItemId['a']!.complete(true);
    await pumpFixedFrames(tester);

    await tester.tap(find.text('보낸 요청 보기'));
    await pumpFixedFrames(tester);

    final container = ProviderScope.containerOf(tester.element(find.byType(TradeRequestScreen)));
    expect(container.read(currentTabIndexProvider), 1);
    expect(container.read(sentRequestsFocusTriggerProvider), isTrue);
  });

  testWidgets('끝 근처 카드로 슬라이드 > 내 물품 다음 페이지 조회 후 카드 추가', (tester) async {
    final itemRepository = FakeMyItemsPageRepository()
      ..itemsByPageNumber = {
        0: [buildMyItem('a'), buildMyItem('b'), buildMyItem('c')],
        1: [buildMyItem('d')],
      };
    await pumpTradeRequestScreen(tester, itemRepository: itemRepository, tradeRepository: ControlledTradeRepository());
    expect(itemRepository.requestedPageNumbers, [0]);

    await tester.drag(find.byType(PageView), const Offset(-219, 0));
    await pumpFixedFrames(tester);

    expect(itemRepository.requestedPageNumbers, [0, 1]);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 4);
  });

  testWidgets('홈에서 고른 카드가 다음 페이지에 있음 > 찾을 때까지 조회 후 선택, 다른 물품 선택 > 카드 선택 모드', (tester) async {
    final itemRepository = FakeMyItemsPageRepository()
      ..itemsByPageNumber = {
        0: [buildMyItem('a'), buildMyItem('b')],
        1: [buildMyItem('c')],
      };
    final tradeRepository = ControlledTradeRepository();
    await pumpTradeRequestScreen(
      tester,
      itemRepository: itemRepository,
      tradeRepository: tradeRepository,
      preSelectedCardId: 'c',
    );

    expect(itemRepository.requestedPageNumbers, [0, 1]);
    expect(tradeRepository.checkedGiveItemIds, ['c']);
    expect(find.byType(PageView), findsNothing);
    expect(find.text('물품 c'), findsOneWidget);

    await tester.tap(find.text('다른 물품 선택'));
    await pumpFixedFrames(tester);
    expect(find.byType(PageView), findsOneWidget);
  });

  testWidgets('미리 고른 카드 탐색 중 다음 페이지 실패 > 받은 카드로 선택·존재 확인 진행 (확인 중 고착 없음)', (tester) async {
    final itemRepository = FakeMyItemsPageRepository()
      ..itemsByPageNumber = {
        0: [buildMyItem('a'), buildMyItem('b')],
        1: [buildMyItem('c')],
      }
      ..failingPageNumbers = {1};
    final tradeRepository = ControlledTradeRepository();
    await pumpTradeRequestScreen(
      tester,
      itemRepository: itemRepository,
      tradeRepository: tradeRepository,
      preSelectedCardId: 'c',
    );

    // 못 찾음 > 첫 카드(a) 선택, 카드 선택 모드, 존재 확인 실행
    expect(itemRepository.requestedPageNumbers, [0, 1]);
    expect(tradeRepository.checkedGiveItemIds, ['a']);
    expect(find.byType(PageView), findsOneWidget);

    tradeRepository.pendingExistenceByGiveItemId['a']!.complete(false);
    await pumpFixedFrames(tester);
    expect(find.byType(TradeRequestTradeOptionSelector), findsOneWidget);

    // 실패 안내 스낵바 자동 닫힘 + 닫힘 애니메이션 대기
    await tester.pump(const Duration(seconds: 3));
    await pumpFixedFrames(tester);
  });

  testWidgets('미리 고른 카드 탐색 > 최대 10페이지까지만 조회', (tester) async {
    final itemRepository = FakeMyItemsPageRepository()..isEndless = true;
    final tradeRepository = ControlledTradeRepository();
    await pumpTradeRequestScreen(
      tester,
      itemRepository: itemRepository,
      tradeRepository: tradeRepository,
      preSelectedCardId: 'missing',
    );

    expect(itemRepository.requestedPageNumbers, [for (var pageNumber = 0; pageNumber < 10; pageNumber++) pageNumber]);
    expect(tradeRepository.checkedGiveItemIds, ['endless-0']);
  });

  testWidgets('다음 페이지가 이미 받은 물품뿐 > 탐색 중단, 중복 카드 없음', (tester) async {
    final itemRepository = FakeMyItemsPageRepository()
      ..itemsByPageNumber = {
        0: [buildMyItem('a'), buildMyItem('b')],
        1: [buildMyItem('a'), buildMyItem('b')],
        2: [buildMyItem('c')],
      };
    await pumpTradeRequestScreen(
      tester,
      itemRepository: itemRepository,
      tradeRepository: ControlledTradeRepository(),
      preSelectedCardId: 'c',
    );

    expect(itemRepository.requestedPageNumbers, [0, 1]);
    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.childrenDelegate.estimatedChildCount, 2);
  });
}
