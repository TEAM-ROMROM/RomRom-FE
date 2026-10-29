import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';

class FakeItemRepository implements ItemRepository {
  List<Item> available = [];
  List<Item> exchanged = [];
  int deleteCount = 0;
  int postCount = 0;
  int statusCount = 0;
  int updateCount = 0;
  int getMyItemsCount = 0;

  @override
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    getMyItemsCount++;
    return status == ItemStatus.available ? available : exchanged;
  }

  @override
  Future<ItemResponse> postItem(ItemRequest request) async {
    postCount++;
    available = [...available, Item(itemId: 'new', itemName: request.itemName)];
    return ItemResponse(
      item: Item(itemId: 'new'),
      isFirstItemPosted: available.length == 1,
    );
  }

  @override
  Future<void> deleteItem(String itemId) async {
    deleteCount++;
    available = available.where((e) => e.itemId != itemId).toList();
  }

  @override
  Future<ItemResponse> updateItemStatus(ItemRequest request) async {
    statusCount++;
    return ItemResponse();
  }

  @override
  Future<void> updateItem(ItemRequest request) async {
    updateCount++;
    // 수정 결과를 서버 데이터에 반영 (재조회로만 화면에 보여야 함)
    available = available
        .map((item) => item.itemId == request.itemId ? Item(itemId: item.itemId, itemName: request.itemName) : item)
        .toList();
  }

  @override
  Future<ItemResponse> postLike(String itemId) async => throw UnimplementedError();
}

void main() {
  group('myItemsProvider', () {
    late FakeItemRepository fake;
    late ProviderContainer container;

    setUp(() {
      fake = FakeItemRepository();
      container = ProviderContainer(overrides: [itemRepositoryProvider.overrideWithValue(fake)]);
    });
    tearDown(() => container.dispose());

    test('build는 available/exchanged를 병렬 로드한다', () async {
      fake.available = [Item(itemId: 'a')];
      fake.exchanged = [Item(itemId: 'x')];
      final state = await container.read(myItemsProvider.future);
      expect(state.available.length, 1);
      expect(state.exchanged.length, 1);
    });

    test('register 후 available가 재조회된다', () async {
      await container.read(myItemsProvider.future);
      final isFirst = await container.read(myItemsProvider.notifier).register(ItemRequest(itemName: 'n'));
      expect(fake.postCount, 1);
      expect(isFirst, isTrue);
      expect(container.read(myItemsProvider).value!.available.length, 1);
    });

    test('delete 후 목록에서 빠진다', () async {
      fake.available = [Item(itemId: 'a'), Item(itemId: 'b')];
      await container.read(myItemsProvider.future);
      await container.read(myItemsProvider.notifier).delete('a');
      expect(fake.deleteCount, 1);
      expect(container.read(myItemsProvider).value!.available.any((e) => e.itemId == 'a'), isFalse);
    });

    test('changeStatus 후 statusCount가 증가한다', () async {
      await container.read(myItemsProvider.future);
      await container.read(myItemsProvider.notifier).changeStatus(ItemRequest(itemId: 'a'));
      expect(fake.statusCount, 1);
    });

    test('edit 후 updateItem 1회 호출 + 서버 재조회로 수정 내용이 반영된다', () async {
      fake.available = [Item(itemId: 'a', itemName: 'before')];
      await container.read(myItemsProvider.future);
      final fetchCountBeforeUpdate = fake.getMyItemsCount;

      await container.read(myItemsProvider.notifier).edit(ItemRequest(itemId: 'a', itemName: 'after'));

      expect(fake.updateCount, 1);
      // 재조회 1회 = available + exchanged 2건
      expect(fake.getMyItemsCount, fetchCountBeforeUpdate + 2);
      expect(container.read(myItemsProvider).value!.available.single.itemName, 'after');
    });
  });
}
