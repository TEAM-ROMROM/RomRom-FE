import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

/// 내 물품 조회 API 대역: 마지막 요청 기록, 응답 지정
class FakeMyItemsApi implements ItemApi {
  ItemRequest? lastRequest;
  ItemResponse myItemsResponse = ItemResponse();

  @override
  Future<ItemResponse> getMyItems(ItemRequest request) async {
    lastRequest = request;
    return myItemsResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Item> buildItems(int count) => [for (var index = 0; index < count; index++) Item(itemId: 'item-$index')];

void main() {
  late FakeMyItemsApi fakeApi;
  late ItemRepository repository;

  setUp(() {
    fakeApi = FakeMyItemsApi();
    repository = ItemRepository(fakeApi);
  });

  group('ItemRepository.getMyItemsPage', () {
    test('페이지 번호·크기·상태 전달, 목록 반환', () async {
      fakeApi.myItemsResponse = ItemResponse(itemPage: ItemPage(content: buildItems(2)));

      final myItemsPage = await repository.getMyItemsPage(ItemStatus.available, pageNumber: 2, pageSize: 20);

      expect(fakeApi.lastRequest?.pageNumber, 2);
      expect(fakeApi.lastRequest?.pageSize, 20);
      expect(fakeApi.lastRequest?.itemStatus, ItemStatus.available.serverName);
      expect(myItemsPage.items.map((item) => item.itemId), ['item-0', 'item-1']);
    });

    test('서버 전체 페이지 수 기준 다음 페이지 여부 (page 객체 우선)', () async {
      fakeApi.myItemsResponse = ItemResponse(
        itemPage: ItemPage(
          content: buildItems(20),
          page: const ApiPage(size: 20, number: 0, totalElements: 40, totalPages: 2),
        ),
      );
      expect((await repository.getMyItemsPage(ItemStatus.available, pageNumber: 0, pageSize: 20)).hasMore, isTrue);
      expect((await repository.getMyItemsPage(ItemStatus.available, pageNumber: 1, pageSize: 20)).hasMore, isFalse);
    });

    test('최상위 전체 페이지 수만 있음 > 그 값 기준', () async {
      fakeApi.myItemsResponse = ItemResponse(itemPage: ItemPage(content: buildItems(20), totalPages: 3));

      expect((await repository.getMyItemsPage(ItemStatus.available, pageNumber: 1, pageSize: 20)).hasMore, isTrue);
    });

    test('페이지 정보 없음 > 받은 개수가 페이지 크기만큼이면 다음 페이지 있음', () async {
      fakeApi.myItemsResponse = ItemResponse(itemPage: ItemPage(content: buildItems(20)));
      expect((await repository.getMyItemsPage(ItemStatus.available, pageNumber: 0, pageSize: 20)).hasMore, isTrue);

      fakeApi.myItemsResponse = ItemResponse(itemPage: ItemPage(content: buildItems(5)));
      expect((await repository.getMyItemsPage(ItemStatus.available, pageNumber: 0, pageSize: 20)).hasMore, isFalse);
    });

    test('목록 없음 > 빈 목록, 다음 페이지 없음', () async {
      final myItemsPage = await repository.getMyItemsPage(ItemStatus.available, pageNumber: 0, pageSize: 20);

      expect(myItemsPage.items, isEmpty);
      expect(myItemsPage.hasMore, isFalse);
    });
  });
}
