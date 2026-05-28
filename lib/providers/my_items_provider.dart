import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/item_status.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/providers/item_repository_provider.dart';
import 'package:romrom_fe/repositories/item_repository.dart';
import 'package:romrom_fe/states/my_items_state.dart';

final myItemsProvider = AsyncNotifierProvider<MyItemsNotifier, MyItemsState>(MyItemsNotifier.new);

class MyItemsNotifier extends AsyncNotifier<MyItemsState> {
  ItemRepository get _repo => ref.read(itemRepositoryProvider);

  @override
  Future<MyItemsState> build() => _fetch();

  Future<MyItemsState> _fetch() async {
    final results = await Future.wait([_repo.getMyItems(ItemStatus.available), _repo.getMyItems(ItemStatus.exchanged)]);
    return MyItemsState(available: results[0], exchanged: results[1]);
  }

  /// mutation 후 서버 재조회 (CLAUDE.md: 수동 제거 금지, 재조회만).
  Future<void> reload() async {
    final next = await AsyncValue.guard(_fetch);
    // 재조회 실패 시 이전 목록을 유지한 채 에러만 덧씌운다 (화면 blank 방지)
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  /// 등록. 반환값으로 isFirstItemPosted를 전달(코치마크 게이트용).
  Future<bool> register(ItemRequest request) async {
    final res = await _repo.postItem(request);
    await reload();
    return res.isFirstItemPosted ?? false;
  }

  Future<void> delete(String itemId) async {
    await _repo.deleteItem(itemId);
    await reload();
  }

  Future<void> changeStatus(ItemRequest request) async {
    await _repo.updateItemStatus(request);
    await reload();
  }
}
