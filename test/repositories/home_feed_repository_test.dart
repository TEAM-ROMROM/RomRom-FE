import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/apis/requests/item_request.dart';
import 'package:romrom_fe/models/apis/responses/item_response.dart';
import 'package:romrom_fe/repositories/home_feed_repository.dart';
import 'package:romrom_fe/services/apis/item_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 물품 목록 API fake (요청값 기록, 빈 응답)
class _RecordingItemApi implements ItemApi {
  ItemRequest? lastRequest;

  @override
  Future<ItemResponse> getItems(ItemRequest request) async {
    lastRequest = request;
    return ItemResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 홈 피드 저장소 테스트 (#966): 요청값 전달, 최근 본 물품 회원별 저장
void main() {
  late _RecordingItemApi recordingItemApi;
  String? currentMemberId;

  HomeFeedRepository buildRepository() =>
      HomeFeedRepository(recordingItemApi, readCurrentMemberId: () async => currentMemberId);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    recordingItemApi = _RecordingItemApi();
    currentMemberId = 'member-1';
  });

  test('fetchPage: 최근 본 물품·시드를 요청에 그대로 전달', () async {
    await buildRepository().fetchPage(
      pageNumber: 2,
      pageSize: 10,
      sortField: ItemSortField.recommended,
      recentlySeenItemIds: const ['b', 'a'],
      feedSeed: 99,
    );

    final request = recordingItemApi.lastRequest!;
    expect(request.pageNumber, 2);
    expect(request.sortField, ItemSortField.recommended.serverName);
    expect(request.recentlySeenItemIds, ['b', 'a']);
    expect(request.feedSeed, 99);
  });

  test('최근 본 물품: 저장 후 같은 회원은 그대로 복원, 다른 회원은 빈 목록', () async {
    await buildRepository().saveRecentlySeenItemIds(['a', 'b'], memberId: 'member-1');

    expect(await buildRepository().loadRecentlySeenItemIds(), ['a', 'b']);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('${StorageKeys.homeFeedRecentlySeenItemIds.key}_member-1'), ['a', 'b']);

    currentMemberId = 'member-2';
    expect(await buildRepository().loadRecentlySeenItemIds(), isEmpty);
  });

  test('최근 본 물품: 회원 정보 없으면 복원 안 함', () async {
    await buildRepository().saveRecentlySeenItemIds(['a'], memberId: 'member-1');
    currentMemberId = null;

    expect(await buildRepository().loadRecentlySeenItemIds(), isEmpty);
    expect(await buildRepository().readCurrentMemberId(), isNull);
  });

  test('최근 본 물품 저장: 지정 회원 키에 저장 (저장 시점 현재 회원과 무관)', () async {
    currentMemberId = 'member-2';

    await buildRepository().saveRecentlySeenItemIds(['a'], memberId: 'member-1');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getStringList('${StorageKeys.homeFeedRecentlySeenItemIds.key}_member-1'), ['a']);
    expect(preferences.getStringList('${StorageKeys.homeFeedRecentlySeenItemIds.key}_member-2'), isNull);
  });
}
