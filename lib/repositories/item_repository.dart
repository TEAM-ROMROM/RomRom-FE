import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

class ItemRepository {
  final ItemApi _api;

  ItemRepository(this._api);

  Future<ItemResponse> postLike(String itemId) => _api.postLike(ItemRequest(itemId: itemId));

  /// 내 물건 목록 (status별). 1페이지(기본 100개)만 단일 소스로 관리.
  Future<List<Item>> getMyItems(ItemStatus status, {int pageSize = 100}) async {
    final res = await _api.getMyItems(ItemRequest(pageNumber: 0, pageSize: pageSize, itemStatus: status.serverName));
    return res.itemPage?.content ?? const <Item>[];
  }

  Future<ItemResponse> postItem(ItemRequest request) => _api.postItem(request);

  Future<void> deleteItem(String itemId) => _api.deleteItem(itemId);

  Future<ItemResponse> updateItemStatus(ItemRequest request) => _api.updateItemStatus(request);

  /// 물품 수정 (이미지 URL·위치 포함 전체 필드)
  Future<void> updateItem(ItemRequest request) => _api.updateItem(request);

  /// 물품 상세 조회 (물품 + 내 좋아요 여부)
  Future<ItemResponse> getItemDetail(String? itemId) => _api.getItemDetail(ItemRequest(itemId: itemId));

  /// AI 적정 가격 예측 (예측 실패 시 0 이하)
  Future<int> predictPrice({required String itemName, required String itemDescription, String? itemCondition}) {
    return _api.pricePredict(
      ItemRequest(itemName: itemName, itemDescription: itemDescription, itemCondition: itemCondition),
    );
  }

  /// 내가 좋아요한 물품 한 페이지 조회
  Future<List<Item>> getLikedItems({required int pageNumber, required int pageSize}) async {
    final res = await _api.getLikeList(ItemRequest(pageNumber: pageNumber, pageSize: pageSize));
    return res.itemPage?.content ?? <Item>[];
  }

  /// 타인 회원의 등록 물품 목록 조회 (프로필 교환 물건)
  Future<List<Item>> getMemberItems(String? memberId) async {
    final res = await _api.getMemberItems(ItemRequest(memberId: memberId));
    return res.itemPage?.content ?? <Item>[];
  }
}
