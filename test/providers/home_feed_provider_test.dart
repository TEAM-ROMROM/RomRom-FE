import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/home_feed_repository_provider.dart';
import 'package:romrom_fe/repositories/home_feed_repository.dart';

/// 테스트용 fake — sortField.serverName + page 키로 응답 매핑.
class _FakeRepo implements HomeFeedRepository {
  final Map<String, Map<int, List<Item>>> pages;
  int callCount = 0;

  _FakeRepo(this.pages);

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    callCount++;
    return pages[sortField.serverName]?[pageNumber] ?? const <Item>[];
  }
}

class _ThrowingRepo implements HomeFeedRepository {
  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    throw Exception('boom');
  }
}

/// lat/lng 없는 Item — fromItems에서 LocationService 호출 안 함 ('미지정').
Item _item(String id) => Item(itemId: id, itemName: 'name-$id', price: 0);

ProviderContainer _makeContainer(HomeFeedRepository repo) {
  final c = ProviderContainer(overrides: [homeFeedRepositoryProvider.overrideWithValue(repo)]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeFeedNotifier', () {
    test('loadInitial: 첫 정렬 빈 결과면 다음 정렬로 폴백', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {0: const []},
        ItemSortField.distance.serverName: {
          0: [_item('a'), _item('b')],
        },
      });
      final c = _makeContainer(repo);

      final state = await c.read(homeFeedProvider.future);
      expect(state.currentSortField, ItemSortField.distance);
      expect(state.items.length, 2);
      expect(state.hasMoreItems, true);
    });

    test('refresh throttle: 30초 이내면 API 호출 안 함', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('a')],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final callsAfterInitial = repo.callCount;

      // 최초 refresh — lastRefreshAt 세팅
      await c.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);
      final callsAfterFirstRefresh = repo.callCount;
      expect(callsAfterFirstRefresh, greaterThan(callsAfterInitial));

      // 즉시 두 번째 refresh — throttle로 차단
      await c.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);
      expect(repo.callCount, callsAfterFirstRefresh, reason: 'throttle 차단되어 API 호출 없음');
    });

    test('markSeen → refresh: seen 아이템이 응답 뒤로 재정렬', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('a'), _item('b'), _item('c')],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);

      // 'a'를 봤다고 마킹
      c.read(homeFeedProvider.notifier).markSeen('a');

      // refresh → 같은 데이터지만 'a'가 끝으로 가야 함
      await c.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);
      final after = c.read(homeFeedProvider).value!;
      expect(after.items.map((e) => e.itemUuid).toList(), ['b', 'c', 'a']);
    });

    test('seen-set LRU: 100개 초과 시 가장 오래된 것 제거', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('seed')],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);

      final notifier = c.read(homeFeedProvider.notifier);
      for (int i = 0; i < 105; i++) {
        notifier.markSeen('id-$i');
      }
      final state = c.read(homeFeedProvider).value!;
      expect(state.seenItemIds.length, kHomeFeedSeenSetMaxSize);
      expect(state.seenItemIds.contains('id-0'), false, reason: '가장 오래된 것 제거');
      expect(state.seenItemIds.contains('id-104'), true);
    });

    test('loadMore 빈 페이지: page=0 되감기 + seen-set 클리어', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('a'), _item('b')],
          1: const [],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);

      final notifier = c.read(homeFeedProvider.notifier);
      notifier.markSeen('a');
      expect(c.read(homeFeedProvider).value!.seenItemIds.contains('a'), true);

      await notifier.loadMore();
      final after = c.read(homeFeedProvider).value!;
      expect(after.currentPage, 0, reason: '되감기');
      expect(after.seenItemIds.isEmpty, true, reason: 'seen-set 클리어');
    });

    test('build 실패 시 AsyncError surface', () async {
      final c = _makeContainer(_ThrowingRepo());
      await expectLater(c.read(homeFeedProvider.future), throwsException);
      expect(c.read(homeFeedProvider).hasError, true);
    });

    test('중복 refresh 가드: 정상 build 후 연속 refresh는 한 번만 진행', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('a')],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final notifier = c.read(homeFeedProvider.notifier);

      // 두 번 연속 호출 — 두 번째는 throttle 또는 isLoading 가드로 차단
      final f1 = notifier.refresh(trigger: RefreshTrigger.tabReentry);
      final f2 = notifier.refresh(trigger: RefreshTrigger.tabReentry);
      await Future.wait([f1, f2]);
      // 예외 없이 완료, 데이터 유지
      expect(c.read(homeFeedProvider).hasValue, true);
      expect(c.read(homeFeedProvider).value!.items.length, 1);
    });
  });
}
