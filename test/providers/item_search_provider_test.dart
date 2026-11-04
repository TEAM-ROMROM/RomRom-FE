import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_search_sort_field.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/item_search_query.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/item_search_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';

/// 검색 repository 대역: 요청 기록, 페이지별 응답·실패 지정
class FakeItemSearchRepository implements ItemRepository {
  final List<({ItemSearchQuery searchQuery, int pageNumber})> requests = [];
  final Map<int, List<Item>> itemsByPageNumber = {};
  int totalPageCount = 1;
  Set<int> failingPageNumbers = {};

  @override
  Future<({List<Item> items, bool hasMore})> searchItemsPage(
    ItemSearchQuery searchQuery, {
    required int pageNumber,
    required int pageSize,
  }) async {
    requests.add((searchQuery: searchQuery, pageNumber: pageNumber));
    if (failingPageNumbers.contains(pageNumber)) throw Exception('search failed');
    return (items: itemsByPageNumber[pageNumber] ?? const <Item>[], hasMore: pageNumber + 1 < totalPageCount);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 물품 검색 provider: 검색 전 상태, 첫 페이지, 다음 페이지 추가, 첫 페이지 실패, 다음 페이지 실패 (#1008)
void main() {
  late FakeItemSearchRepository fakeRepository;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<Object?>> keepAliveSubscription;

  const searchQuery = ItemSearchQuery(
    keyword: '신발',
    categories: [ItemCategories.shoes],
    sortField: ItemSearchSortField.priceAscending,
  );

  setUp(() async {
    fakeRepository = FakeItemSearchRepository();
    container = ProviderContainer(overrides: [itemRepositoryProvider.overrideWithValue(fakeRepository)]);
    // autoDispose 유지 (화면 구독 대역)
    keepAliveSubscription = container.listen(itemSearchProvider, (_, _) {});
    await container.read(itemSearchProvider.future);
  });

  tearDown(() {
    keepAliveSubscription.close();
    container.dispose();
  });

  test('검색 전 > 검색 조건 없음', () {
    expect(container.read(itemSearchProvider).valueOrNull?.hasSearched, isFalse);
  });

  test('검색 > 조건 전달, 첫 페이지 결과·다음 페이지 여부', () async {
    fakeRepository.itemsByPageNumber[0] = [Item(itemId: 'a')];
    fakeRepository.totalPageCount = 2;

    await container.read(itemSearchProvider.notifier).search(searchQuery);

    final searchState = container.read(itemSearchProvider).valueOrNull!;
    expect(fakeRepository.requests.single.searchQuery, searchQuery);
    expect(searchState.searchQuery, searchQuery);
    expect(searchState.items.map((item) => item.itemId), ['a']);
    expect(searchState.hasMore, isTrue);
  });

  test('다음 페이지 > 뒤에 추가, 마지막 페이지면 더 없음', () async {
    fakeRepository.itemsByPageNumber[0] = [Item(itemId: 'a')];
    fakeRepository.itemsByPageNumber[1] = [Item(itemId: 'b')];
    fakeRepository.totalPageCount = 2;
    final searchNotifier = container.read(itemSearchProvider.notifier);

    await searchNotifier.search(searchQuery);
    await searchNotifier.loadMore();

    final searchState = container.read(itemSearchProvider).valueOrNull!;
    expect(searchState.items.map((item) => item.itemId), ['a', 'b']);
    expect(searchState.hasMore, isFalse);
    expect(fakeRepository.requests.last.pageNumber, 1);
  });

  test('첫 페이지 실패 > 에러 상태', () async {
    fakeRepository.failingPageNumbers = {0};

    await container.read(itemSearchProvider.notifier).search(searchQuery);

    expect(container.read(itemSearchProvider).hasError, isTrue);
  });

  test('다음 페이지 실패 > 목록 유지 + 실패 표시', () async {
    fakeRepository.itemsByPageNumber[0] = [Item(itemId: 'a')];
    fakeRepository.totalPageCount = 3;
    fakeRepository.failingPageNumbers = {1};
    final searchNotifier = container.read(itemSearchProvider.notifier);

    await searchNotifier.search(searchQuery);
    await searchNotifier.loadMore();

    final searchState = container.read(itemSearchProvider).valueOrNull!;
    expect(searchState.items.map((item) => item.itemId), ['a']);
    expect(searchState.hasNextPageError, isTrue);
    expect(searchState.isLoadingMore, isFalse);
  });
}
