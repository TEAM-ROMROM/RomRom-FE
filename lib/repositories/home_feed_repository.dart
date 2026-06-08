import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/services/apis/item_api.dart';

/// 홈 피드 조회 전용 repository.
/// 정렬 폴백·페이지네이션·seen 재정렬 같은 도메인 로직은 notifier가 담당한다.
class HomeFeedRepository {
  final ItemApi _api;

  HomeFeedRepository(this._api);

  /// 단일 페이지를 단일 정렬 필드로 조회한다.
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    final res = await _api.getItems(
      ItemRequest(pageNumber: pageNumber, pageSize: pageSize, sortField: sortField.serverName),
    );
    return res.itemPage?.content ?? const <Item>[];
  }
}
