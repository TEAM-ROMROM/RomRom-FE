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
}
