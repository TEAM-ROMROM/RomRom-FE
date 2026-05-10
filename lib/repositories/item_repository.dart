import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

class ItemRepository {
  final ItemApi _api;

  ItemRepository(this._api);

  Future<ItemResponse> postLike(String itemId) => _api.postLike(ItemRequest(itemId: itemId));
}
