import 'dart:async';

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
  int callCount = 0;

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    callCount++;
    throw Exception('boom');
  }
}

/// 처음 [failCount]회는 실패, 이후 [items] 반환 (첫 로드 실패 > 재시도 성공 재현)
class _FailThenSucceedRepo implements HomeFeedRepository {
  final int failCount;
  final List<Item> items;
  int callCount = 0;

  _FailThenSucceedRepo({required this.failCount, required this.items});

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    callCount++;
    if (callCount <= failCount) throw Exception('boom');
    return items;
  }
}

/// fetchPage를 completer로 붙잡아 두는 fake (동시 호출 재현)
class _GatedRepo implements HomeFeedRepository {
  final Completer<void> gate = Completer<void>();
  int callCount = 0;

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    callCount++;
    // 첫 페이지(0)는 즉시, 이후 페이지는 gate가 열릴 때까지 대기
    if (pageNumber > 0) await gate.future;
    return [_item('p$pageNumber')];
  }
}

/// 첫 페이지(0)는 성공, 이후 페이지는 [shouldFailLoadMore]가 true인 동안 실패
class _LoadMoreFailRepo implements HomeFeedRepository {
  bool shouldFailLoadMore = true;
  int loadMoreCallCount = 0;

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
  }) async {
    if (pageNumber == 0) return [_item('p0')];
    loadMoreCallCount++;
    if (shouldFailLoadMore) throw Exception('boom');
    return [_item('p$pageNumber')];
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

      final beforeRev = c.read(homeFeedProvider).value!.feedRevision;

      // refresh → 같은 데이터지만 'a'가 끝으로 가야 함
      await c.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);
      final after = c.read(homeFeedProvider).value!;
      expect(after.items.map((e) => e.itemUuid).toList(), ['b', 'c', 'a']);
      // refresh는 replace 신호로 feedRevision을 증가시켜야 함 (#904)
      expect(after.feedRevision, beforeRev + 1, reason: 'refresh는 replace이므로 revision 증가');
    });

    // #904 회귀 방지: 초기 페이지가 적게 와도 refresh를 append로 오분류하지 않도록
    // provider가 명시 신호(feedRevision)를 정확히 갱신하는지 검증
    test('feedRevision: refresh는 증가, loadMore는 불변', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('a'), _item('b')], // 초기 페이지 2개 (10개 미만 — 버그 트리거 조건)
          1: [_item('c'), _item('d')],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final initialRev = c.read(homeFeedProvider).value!.feedRevision;

      // loadMore: revision 불변 (append)
      await c.read(homeFeedProvider.notifier).loadMore();
      expect(c.read(homeFeedProvider).value!.feedRevision, initialRev, reason: 'loadMore는 append이므로 revision 불변');

      // refresh: revision 증가 (replace) — 초기보다 많은 아이템이어도 append로 오분류되지 않음
      await c.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);
      expect(c.read(homeFeedProvider).value!.feedRevision, initialRev + 1, reason: 'refresh는 replace이므로 revision 증가');
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

    test('retryInitialLoad: 첫 로드 실패 후 재시도 성공 시 데이터 표시', () async {
      final repo = _FailThenSucceedRepo(failCount: 1, items: [_item('a')]);
      final c = _makeContainer(repo);
      await expectLater(c.read(homeFeedProvider.future), throwsException);

      await c.read(homeFeedProvider.notifier).retryInitialLoad();

      final state = c.read(homeFeedProvider);
      expect(state.hasError, false);
      expect(state.value!.items.length, 1);
    });

    test('retryInitialLoad: 재시도 진행 중 중복 호출은 무시', () async {
      final repo = _ThrowingRepo();
      final c = _makeContainer(repo);
      await expectLater(c.read(homeFeedProvider.future), throwsException);
      final callsAfterInitial = repo.callCount;
      final notifier = c.read(homeFeedProvider.notifier);

      await Future.wait([notifier.retryInitialLoad(), notifier.retryInitialLoad()]);

      // 실패 시 정렬 폴백 없이 1회 호출 > 재시도 1회분만 증가
      expect(repo.callCount - callsAfterInitial, 1);
      expect(c.read(homeFeedProvider).hasError, true);
    });

    test('retryInitialLoad: 데이터가 이미 있으면 무시', () async {
      final repo = _FakeRepo({
        ItemSortField.recommended.serverName: {
          0: [_item('a')],
        },
      });
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final callsAfterInitial = repo.callCount;

      await c.read(homeFeedProvider.notifier).retryInitialLoad();

      expect(repo.callCount, callsAfterInitial);
    });

    test('refresh: 첫 로드 실패(데이터 없음) 상태에서 호출해도 예외 없이 무시', () async {
      final repo = _ThrowingRepo();
      final c = _makeContainer(repo);
      await expectLater(c.read(homeFeedProvider.future), throwsException);
      final callsAfterInitial = repo.callCount;

      await c.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.tabReentry);

      expect(repo.callCount, callsAfterInitial);
      expect(c.read(homeFeedProvider).hasError, true);
    });

    test('loadMore: 진행 중 동시 호출은 repository를 1번만 호출', () async {
      final repo = _GatedRepo();
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final callsAfterInitial = repo.callCount;
      final notifier = c.read(homeFeedProvider.notifier);

      final firstLoad = notifier.loadMore();
      final secondLoad = notifier.loadMore();
      repo.gate.complete();
      await Future.wait([firstLoad, secondLoad]);

      expect(repo.callCount - callsAfterInitial, 1, reason: '동시 loadMore는 같은 페이지를 중복 조회하지 않음');
      expect(c.read(homeFeedProvider).value!.currentPage, 1);
    });

    test('loadMore: 완료 후에는 다시 호출 가능', () async {
      final repo = _GatedRepo()..gate.complete();
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final notifier = c.read(homeFeedProvider.notifier);

      await notifier.loadMore();
      await notifier.loadMore();

      expect(c.read(homeFeedProvider).value!.currentPage, 2);
    });

    test('loadMore 실패: 대기 시간 안의 재호출은 repository를 부르지 않고, 지나면 다시 호출', () async {
      final repo = _LoadMoreFailRepo();
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final notifier = c.read(homeFeedProvider.notifier);
      var fakeNow = DateTime(2026, 10, 29, 12);
      notifier.now = () => fakeNow;

      await notifier.loadMore();
      expect(repo.loadMoreCallCount, 1);
      expect(c.read(homeFeedProvider).hasError, true);

      // 실패 직후 재호출 — 대기 시간 안이라 차단
      await notifier.loadMore();
      expect(repo.loadMoreCallCount, 1, reason: '대기 시간 안에는 재시도하지 않음');

      // 대기 시간 직전 — 여전히 차단
      fakeNow = fakeNow.add(loadMoreRetryCooldown - const Duration(milliseconds: 1));
      await notifier.loadMore();
      expect(repo.loadMoreCallCount, 1);

      // 대기 시간 경과 — 재시도 허용, 성공 시 에러 해소
      fakeNow = fakeNow.add(const Duration(milliseconds: 1));
      repo.shouldFailLoadMore = false;
      await notifier.loadMore();
      expect(repo.loadMoreCallCount, 2);
      expect(c.read(homeFeedProvider).hasError, false);
      expect(c.read(homeFeedProvider).value!.currentPage, 1);
    });

    test('세션 초기화(invalidate) 후 > 이전 loadMore 실패 대기 시간 무시하고 바로 loadMore', () async {
      final repo = _LoadMoreFailRepo();
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final notifier = c.read(homeFeedProvider.notifier);
      notifier.now = () => DateTime(2026, 10, 29, 12);
      await notifier.loadMore();
      expect(repo.loadMoreCallCount, 1);

      c.invalidate(homeFeedProvider);
      await c.read(homeFeedProvider.future);
      await c.read(homeFeedProvider.notifier).loadMore();

      expect(repo.loadMoreCallCount, 2);
    });

    test('세션 초기화(invalidate) 후 > 이전 세션 진행 중 loadMore가 새 loadMore를 막지 않고, 늦은 결과는 버림', () async {
      final repo = _GatedRepo();
      final c = _makeContainer(repo);
      await c.read(homeFeedProvider.future);
      final previousSessionLoad = c.read(homeFeedProvider.notifier).loadMore();

      c.invalidate(homeFeedProvider);
      await c.read(homeFeedProvider.future);
      final callsBeforeNextLoad = repo.callCount;
      final nextSessionLoad = c.read(homeFeedProvider.notifier).loadMore();
      expect(repo.callCount - callsBeforeNextLoad, 1, reason: '이전 세션 진행 중 표시에 묶이지 않음');

      repo.gate.complete();
      await Future.wait([previousSessionLoad, nextSessionLoad]);

      final itemIds = c.read(homeFeedProvider).value!.items.map((item) => item.itemUuid);
      expect(itemIds, ['p0', 'p1'], reason: '이전 세션 loadMore 결과는 새 피드에 붙지 않음');
    });
  });
}
