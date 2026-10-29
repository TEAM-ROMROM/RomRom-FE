import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

/// 물품 API 대역: 마지막 요청 기록, 응답 조절
class FakeItemApi implements ItemApi {
  ItemRequest? lastRequest;
  int predictedPrice = 0;
  ItemResponse listResponse = ItemResponse();

  @override
  Future<int> pricePredict(ItemRequest request) async {
    lastRequest = request;
    return predictedPrice;
  }

  @override
  Future<ItemResponse> getLikeList(ItemRequest request) async {
    lastRequest = request;
    return listResponse;
  }

  @override
  Future<ItemResponse> getMemberItems(ItemRequest request) async {
    lastRequest = request;
    return listResponse;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ItemRepository 단건 호출', () {
    late FakeItemApi fakeApi;
    late ItemRepository repository;

    setUp(() {
      fakeApi = FakeItemApi();
      repository = ItemRepository(fakeApi);
    });

    test('predictPrice는 이름·설명·상태를 전달하고 예측 가격 반환', () async {
      fakeApi.predictedPrice = 15000;

      final predictedPrice = await repository.predictPrice(
        itemName: '의자',
        itemDescription: '튼튼함',
        itemCondition: 'SEALED',
      );

      expect(predictedPrice, 15000);
      expect(fakeApi.lastRequest?.itemName, '의자');
      expect(fakeApi.lastRequest?.itemDescription, '튼튼함');
      expect(fakeApi.lastRequest?.itemCondition, 'SEALED');
    });

    test('getLikedItems는 페이지 번호·크기 전달, 목록 반환 (페이지 없으면 빈 목록)', () async {
      expect(await repository.getLikedItems(pageNumber: 2, pageSize: 10), isEmpty);
      expect(fakeApi.lastRequest?.pageNumber, 2);
      expect(fakeApi.lastRequest?.pageSize, 10);

      fakeApi.listResponse = ItemResponse(
        itemPage: ItemPage(content: [Item(itemId: 'A')]),
      );
      final likedItems = await repository.getLikedItems(pageNumber: 0, pageSize: 10);
      expect(likedItems.map((item) => item.itemId), ['A']);
    });

    test('getMemberItems는 회원 id 전달', () async {
      await repository.getMemberItems('member-1');
      expect(fakeApi.lastRequest?.memberId, 'member-1');
    });
  });
}
