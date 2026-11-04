import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/home_feed_refresh_result.dart';
import 'package:romrom_fe/enums/item_sort_field.dart';
import 'package:romrom_fe/enums/refresh_trigger.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/providers/home_feed_provider.dart';
import 'package:romrom_fe/providers/home_feed_repository_provider.dart';
import 'package:romrom_fe/providers/member_block_provider.dart';
import 'package:romrom_fe/repositories/home_feed_repository.dart';

/// 최근 본 물품 저장소 fake (기기 저장 대신 메모리, 저장 호출 기록)
mixin _InMemoryRecentlySeenStorage {
  List<String> persistedRecentlySeenItemIds = const [];
  int saveCallCount = 0;
  // 현재 로그인 회원 (null = 세션 종료로 비워짐), 마지막 저장 회원
  String? currentMemberId = 'member-1';
  String? lastSavedMemberId;

  Future<String?> readCurrentMemberId() async => currentMemberId;

  Future<List<String>> loadRecentlySeenItemIds() async => persistedRecentlySeenItemIds;

  Future<void> saveRecentlySeenItemIds(List<String> recentlySeenItemIds, {required String memberId}) async {
    saveCallCount++;
    lastSavedMemberId = memberId;
    persistedRecentlySeenItemIds = List.of(recentlySeenItemIds);
  }
}

/// fetchPage 요청값 기록 (페이지·시드·최근 본 물품 스냅샷)
class _FetchPageCall {
  final int pageNumber;
  final List<String> recentlySeenItemIds;
  final int? feedSeed;

  _FetchPageCall(this.pageNumber, this.recentlySeenItemIds, this.feedSeed);
}

/// 요청값을 기록하는 fake — page 키로 응답 매핑 (정렬 무관)
class _RecordingRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  final Map<int, List<Item>> pages;
  final List<_FetchPageCall> calls = [];

  _RecordingRepository(this.pages);

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    calls.add(_FetchPageCall(pageNumber, List.of(recentlySeenItemIds), feedSeed));
    return pages[pageNumber] ?? const <Item>[];
  }
}

/// 테스트용 fake — sortField.serverName + page 키로 응답 매핑.
class _FakeRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  final Map<String, Map<int, List<Item>>> pages;
  int callCount = 0;
  // 설정되면 조회 시 던짐 (새로고침 실패 재현)
  Object? errorToThrow;

  _FakeRepository(this.pages);

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    callCount++;
    final error = errorToThrow;
    if (error != null) throw error;
    return pages[sortField.serverName]?[pageNumber] ?? const <Item>[];
  }
}

class _ThrowingRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  int callCount = 0;

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    callCount++;
    throw Exception('boom');
  }
}

/// 처음 [failCount]회는 실패, 이후 [items] 반환 (첫 로드 실패 > 재시도 성공 재현)
class _FailThenSucceedRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  final int failCount;
  final List<Item> items;
  int callCount = 0;

  _FailThenSucceedRepository({required this.failCount, required this.items});

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    callCount++;
    if (callCount <= failCount) throw Exception('boom');
    return items;
  }
}

/// fetchPage를 completer로 붙잡아 두는 fake (동시 호출 재현)
class _GatedRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  final Completer<void> gate = Completer<void>();
  int callCount = 0;

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    callCount++;
    // 첫 페이지(0)는 즉시, 이후 페이지는 gate가 열릴 때까지 대기
    if (pageNumber > 0) await gate.future;
    return [_item('p$pageNumber')];
  }
}

/// 첫 페이지(0)는 성공, 이후 페이지는 [shouldFailLoadMore]가 true인 동안 실패
class _LoadMoreFailRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  bool shouldFailLoadMore = true;
  int loadMoreCallCount = 0;

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    if (pageNumber == 0) return [_item('p0')];
    loadMoreCallCount++;
    if (shouldFailLoadMore) throw Exception('boom');
    return [_item('p$pageNumber')];
  }
}

/// lat/lng 없는 Item — fromItems에서 LocationService 호출 안 함 ('미지정').
Item _item(String id) => Item(itemId: id, itemName: 'name-$id', price: 0);

/// 작성자 지정 Item (차단 회원 물품 제외 검증)
Item _itemBy(String id, String authorMemberId) => Item(
  itemId: id,
  itemName: 'name-$id',
  price: 0,
  member: Member(memberId: authorMemberId),
);

/// 페이지별 응답 + 페이지별 대기 (진행 중 refresh·loadMore 경쟁 재현, gate 없으면 즉시 응답)
class _GateablePagesRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  final Map<int, List<Item>> pages;
  final Map<int, Completer<void>> gateByPageNumber = {};
  int callCount = 0;

  _GateablePagesRepository(this.pages);

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    callCount++;
    final gate = gateByPageNumber[pageNumber];
    if (gate != null) await gate.future;
    return pages[pageNumber] ?? const <Item>[];
  }
}

/// 페이지별 응답 + 실패 전환 (첫 로드 성공 > 새로고침 실패 재현)
class _SwitchableRepository with _InMemoryRecentlySeenStorage implements HomeFeedRepository {
  final Map<int, List<Item>> pages;
  bool shouldFail = false;
  int callCount = 0;

  _SwitchableRepository(this.pages);

  @override
  Future<List<Item>> fetchPage({
    required int pageNumber,
    required int pageSize,
    required ItemSortField sortField,
    List<String> recentlySeenItemIds = const [],
    int? feedSeed,
  }) async {
    callCount++;
    if (shouldFail) throw Exception('boom');
    return pages[pageNumber] ?? const <Item>[];
  }
}

ProviderContainer _makeContainer(HomeFeedRepository repository) {
  final container = ProviderContainer(overrides: [homeFeedRepositoryProvider.overrideWithValue(repository)]);
  addTearDown(container.dispose);
  return container;
}

/// 첫 로드 직후의 30초 제한 해제 (테스트 시계를 1분 뒤로)
void _expireFirstLoadThrottle(HomeFeedNotifier notifier) {
  notifier.now = () => DateTime.now().add(const Duration(minutes: 1));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeFeedNotifier', () {
    test('loadInitial: 첫 정렬 빈 결과면 다음 정렬로 폴백', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {0: const []},
        ItemSortField.distance.serverName: {
          0: [_item('a'), _item('b')],
        },
      });
      final container = _makeContainer(repository);

      final state = await container.read(homeFeedProvider.future);
      expect(state.currentSortField, ItemSortField.distance);
      expect(state.items.length, 2);
      expect(state.hasMoreItems, true);
    });

    test('refresh throttle: 30초 이내면 API 호출 안 함', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {
          0: [_item('a')],
        },
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      _expireFirstLoadThrottle(container.read(homeFeedProvider.notifier));
      final callsAfterInitial = repository.callCount;

      // 최초 refresh — lastRefreshAt 세팅
      await container.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);
      final callsAfterFirstRefresh = repository.callCount;
      expect(callsAfterFirstRefresh, greaterThan(callsAfterInitial));

      // 즉시 두 번째 refresh — throttle로 차단
      await container.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);
      expect(repository.callCount, callsAfterFirstRefresh, reason: 'throttle 차단되어 API 호출 없음');
    });

    test('markSeen → refresh: seen 아이템이 응답 뒤로 재정렬', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {
          0: [_item('a'), _item('b'), _item('c')],
        },
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      _expireFirstLoadThrottle(container.read(homeFeedProvider.notifier));

      // 'a'를 봤다고 마킹
      container.read(homeFeedProvider.notifier).markSeen('a');

      final beforeRev = container.read(homeFeedProvider).value!.feedRevision;

      // refresh → 같은 데이터지만 'a'가 끝으로 가야 함
      await container.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);
      final after = container.read(homeFeedProvider).value!;
      expect(after.items.map((e) => e.itemUuid).toList(), ['b', 'c', 'a']);
      // refresh는 replace 신호로 feedRevision을 증가시켜야 함 (#904)
      expect(after.feedRevision, beforeRev + 1, reason: 'refresh는 replace이므로 revision 증가');
    });

    // #904 회귀 방지: 초기 페이지가 적게 와도 refresh를 append로 오분류하지 않도록
    // provider가 명시 신호(feedRevision)를 정확히 갱신하는지 검증
    test('feedRevision: refresh는 증가, loadMore는 불변', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {
          0: [_item('a'), _item('b')], // 초기 페이지 2개 (10개 미만 — 버그 트리거 조건)
          1: [_item('c'), _item('d')],
        },
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      _expireFirstLoadThrottle(container.read(homeFeedProvider.notifier));
      final initialRev = container.read(homeFeedProvider).value!.feedRevision;

      // loadMore: revision 불변 (append)
      await container.read(homeFeedProvider.notifier).loadMore();
      expect(
        container.read(homeFeedProvider).value!.feedRevision,
        initialRev,
        reason: 'loadMore는 append이므로 revision 불변',
      );

      // refresh: revision 증가 (replace) — 초기보다 많은 아이템이어도 append로 오분류되지 않음
      await container.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);
      expect(
        container.read(homeFeedProvider).value!.feedRevision,
        initialRev + 1,
        reason: 'refresh는 replace이므로 revision 증가',
      );
    });

    test('seen-set LRU: 100개 초과 시 가장 오래된 것 제거', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {
          0: [_item('seed')],
        },
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);

      final notifier = container.read(homeFeedProvider.notifier);
      for (int i = 0; i < 105; i++) {
        notifier.markSeen('id-$i');
      }
      expect(notifier.seenItemIds.length, kHomeFeedSeenSetMaxSize);
      expect(notifier.seenItemIds.contains('id-0'), false, reason: '가장 오래된 것 제거');
      expect(notifier.seenItemIds.contains('id-104'), true);
    });

    test('loadMore 빈 페이지: page=0 되감기 + seen 기록 유지 + 새 시드·스냅샷으로 새 세션 (#966)', () async {
      final repository = _RecordingRepository({
        0: [_item('a'), _item('b')],
        1: const [],
      });
      final container = _makeContainer(repository);
      final notifier = container.read(homeFeedProvider.notifier);
      var nextSeed = 100;
      notifier.generateFeedSeed = () => nextSeed++;
      await container.read(homeFeedProvider.future);

      notifier.markSeen('a');
      notifier.markSeen('b');
      await notifier.loadMore();

      final after = container.read(homeFeedProvider).value!;
      expect(after.currentPage, 0, reason: '되감기');
      expect(notifier.seenItemIds.toList(), ['a', 'b'], reason: 'seen 기록은 지우지 않음 (서버가 본 물품 뒤로)');
      final rewindCall = repository.calls.last;
      expect(rewindCall.pageNumber, 0);
      expect(rewindCall.feedSeed, 101, reason: '되감기는 새 세션 > 새 시드');
      expect(rewindCall.recentlySeenItemIds, ['b', 'a'], reason: '지금까지 본 물품 스냅샷 (최근 본 순)');
      expect(after.feedSeed, 101);
    });

    test('build: 저장된 최근 본 물품 복원 > 첫 요청에 스냅샷(최근 본 순) + 시드 전송 (#966)', () async {
      final repository = _RecordingRepository({
        0: [_item('a'), _item('b'), _item('c')],
      })..persistedRecentlySeenItemIds = ['old', 'a'];
      final container = _makeContainer(repository);
      container.read(homeFeedProvider.notifier).generateFeedSeed = () => 7;

      final state = await container.read(homeFeedProvider.future);

      expect(repository.calls.single.recentlySeenItemIds, ['a', 'old']);
      expect(repository.calls.single.feedSeed, 7);
      expect(container.read(homeFeedProvider.notifier).seenItemIds.toList(), ['old', 'a']);
      expect(state.items.map((item) => item.itemUuid).toList(), ['b', 'c', 'a'], reason: '받은 페이지 안에서도 본 물품 뒤로');
    });

    test('build: 저장된 기록이 최대치 초과면 최근 것만 복원', () async {
      final repository = _RecordingRepository({
        0: [_item('a')],
      })..persistedRecentlySeenItemIds = List.generate(kHomeFeedSeenSetMaxSize + 5, (index) => 'id-$index');
      final container = _makeContainer(repository);

      await container.read(homeFeedProvider.future);
      final seenItemIds = container.read(homeFeedProvider.notifier).seenItemIds;

      expect(seenItemIds.length, kHomeFeedSeenSetMaxSize);
      expect(seenItemIds.first, 'id-5', reason: '오래된 5건 제외');
      expect(seenItemIds.last, 'id-${kHomeFeedSeenSetMaxSize + 4}');
    });

    test('loadMore: 중간에 본 물품이 늘어도 같은 세션은 같은 시드·스냅샷 유지 (#966)', () async {
      final repository = _RecordingRepository({
        0: [_item('a'), _item('b')],
        1: [_item('c'), _item('d')],
      })..persistedRecentlySeenItemIds = ['x'];
      final container = _makeContainer(repository);
      final notifier = container.read(homeFeedProvider.notifier);
      notifier.generateFeedSeed = () => 42;
      await container.read(homeFeedProvider.future);

      notifier.markSeen('a');
      await notifier.loadMore();

      expect(repository.calls.map((call) => call.pageNumber).toList(), [0, 1]);
      expect(repository.calls[1].feedSeed, repository.calls[0].feedSeed);
      expect(repository.calls[1].recentlySeenItemIds, ['x'], reason: '세션 중 본 물품은 다음 세션부터 반영 (페이지 경계 중복·누락 방지)');
    });

    test('refresh: 새 시드 + 그동안 본 물품 포함한 새 스냅샷 (#966)', () async {
      final repository = _RecordingRepository({
        0: [_item('a'), _item('b')],
      });
      final container = _makeContainer(repository);
      final notifier = container.read(homeFeedProvider.notifier);
      var nextSeed = 1;
      notifier.generateFeedSeed = () => nextSeed++;
      await container.read(homeFeedProvider.future);
      _expireFirstLoadThrottle(notifier);

      notifier.markSeen('a');
      await notifier.refresh(trigger: RefreshTrigger.foregroundResume);

      final refreshCall = repository.calls.last;
      expect(refreshCall.feedSeed, 2);
      expect(refreshCall.recentlySeenItemIds, ['a']);
      expect(container.read(homeFeedProvider).value!.feedSeed, 2);
    });

    test('refresh 실패: 기존 세션 시드 유지 (이어지는 loadMore가 같은 순서로 이어짐)', () async {
      final repository = _LoadMoreFailRepository()..shouldFailLoadMore = false;
      final container = _makeContainer(repository);
      final notifier = container.read(homeFeedProvider.notifier);
      notifier.generateFeedSeed = () => 5;
      await container.read(homeFeedProvider.future);
      _expireFirstLoadThrottle(notifier);

      final failingRefreshRepository = _ThrowingRepository();
      container.updateOverrides([homeFeedRepositoryProvider.overrideWithValue(failingRefreshRepository)]);
      notifier.generateFeedSeed = () => 6;
      await notifier.refresh(trigger: RefreshTrigger.foregroundResume);

      expect(failingRefreshRepository.callCount, greaterThan(0));
      expect(container.read(homeFeedProvider).value!.feedSeed, 5, reason: '실패한 새로고침의 시드로 바뀌지 않음');
    });

    test('markSeen: 넘길 때마다 저장하지 않고 묶어서 1회 저장 (오래된 순)', () async {
      final repository = _RecordingRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);

      notifier.markSeen('a');
      notifier.markSeen('b');
      notifier.markSeen('a');
      await Future<void>.delayed(Duration.zero);
      expect(repository.saveCallCount, 0, reason: '묶음 저장 대기');

      await notifier.flushSeenItemIds();

      expect(repository.saveCallCount, 1);
      expect(repository.persistedRecentlySeenItemIds, ['b', 'a'], reason: '다시 본 물품은 최근으로 이동');
    });

    test('markSeen: 피드 상태를 새로 내보내지 않음 (넘길 때 홈 화면 재빌드 방지)', () async {
      final repository = _RecordingRepository({
        0: [_item('a'), _item('b')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final before = container.read(homeFeedProvider);
      var emitCount = 0;
      container.listen(homeFeedProvider, (_, _) => emitCount++);

      container.read(homeFeedProvider.notifier).markSeen('a');

      expect(emitCount, 0);
      expect(identical(container.read(homeFeedProvider), before), true);
    });

    test('세션 만료: 회원 정보가 비워진 뒤 세션 초기화돼도 기록 시점 회원 키로 저장', () async {
      final repository = _RecordingRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      container.read(homeFeedProvider.notifier).markSeen('a');
      await Future<void>.delayed(Duration.zero);

      repository.currentMemberId = null;
      container.invalidate(homeFeedProvider);
      await Future<void>.delayed(Duration.zero);

      expect(repository.saveCallCount, 1);
      expect(repository.lastSavedMemberId, 'member-1');
      expect(repository.persistedRecentlySeenItemIds, ['a']);
    });

    test('세션 초기화(invalidate): 대기 중 본 물품 기록 즉시 저장', () async {
      final repository = _RecordingRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      container.read(homeFeedProvider.notifier).markSeen('a');

      container.invalidate(homeFeedProvider);
      await Future<void>.delayed(Duration.zero);

      expect(repository.saveCallCount, 1);
      expect(repository.persistedRecentlySeenItemIds, ['a']);
    });

    test('build 실패 시 AsyncError surface', () async {
      final container = _makeContainer(_ThrowingRepository());
      await expectLater(container.read(homeFeedProvider.future), throwsException);
      expect(container.read(homeFeedProvider).hasError, true);
    });

    test('중복 refresh 가드: 정상 build 후 연속 refresh는 한 번만 진행', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {
          0: [_item('a')],
        },
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);

      // 두 번 연속 호출 — 두 번째는 진행 중 refresh 가드로 차단
      final f1 = notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final f2 = notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      await Future.wait([f1, f2]);
      // 예외 없이 완료, 데이터 유지
      expect(container.read(homeFeedProvider).hasValue, true);
      expect(container.read(homeFeedProvider).value!.items.length, 1);
    });

    test('retryInitialLoad: 첫 로드 실패 후 재시도 성공 시 데이터 표시', () async {
      final repository = _FailThenSucceedRepository(failCount: 1, items: [_item('a')]);
      final container = _makeContainer(repository);
      await expectLater(container.read(homeFeedProvider.future), throwsException);

      await container.read(homeFeedProvider.notifier).retryInitialLoad();

      final state = container.read(homeFeedProvider);
      expect(state.hasError, false);
      expect(state.value!.items.length, 1);
    });

    test('retryInitialLoad: 재시도 진행 중 중복 호출은 무시', () async {
      final repository = _ThrowingRepository();
      final container = _makeContainer(repository);
      await expectLater(container.read(homeFeedProvider.future), throwsException);
      final callsAfterInitial = repository.callCount;
      final notifier = container.read(homeFeedProvider.notifier);

      await Future.wait([notifier.retryInitialLoad(), notifier.retryInitialLoad()]);

      // 실패 시 정렬 폴백 없이 1회 호출 > 재시도 1회분만 증가
      expect(repository.callCount - callsAfterInitial, 1);
      expect(container.read(homeFeedProvider).hasError, true);
    });

    test('retryInitialLoad: 데이터가 이미 있으면 무시', () async {
      final repository = _FakeRepository({
        ItemSortField.recommended.serverName: {
          0: [_item('a')],
        },
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final callsAfterInitial = repository.callCount;

      await container.read(homeFeedProvider.notifier).retryInitialLoad();

      expect(repository.callCount, callsAfterInitial);
    });

    test('refresh: 첫 로드 실패(데이터 없음) 상태에서 호출해도 예외 없이 무시', () async {
      final repository = _ThrowingRepository();
      final container = _makeContainer(repository);
      await expectLater(container.read(homeFeedProvider.future), throwsException);
      final callsAfterInitial = repository.callCount;

      await container.read(homeFeedProvider.notifier).refresh(trigger: RefreshTrigger.foregroundResume);

      expect(repository.callCount, callsAfterInitial);
      expect(container.read(homeFeedProvider).hasError, true);
    });

    test('loadMore: 진행 중 동시 호출은 repository를 1번만 호출', () async {
      final repository = _GatedRepository();
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final callsAfterInitial = repository.callCount;
      final notifier = container.read(homeFeedProvider.notifier);

      final firstLoad = notifier.loadMore();
      final secondLoad = notifier.loadMore();
      repository.gate.complete();
      await Future.wait([firstLoad, secondLoad]);

      expect(repository.callCount - callsAfterInitial, 1, reason: '동시 loadMore는 같은 페이지를 중복 조회하지 않음');
      expect(container.read(homeFeedProvider).value!.currentPage, 1);
    });

    test('loadMore: 완료 후에는 다시 호출 가능', () async {
      final repository = _GatedRepository()..gate.complete();
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);

      await notifier.loadMore();
      await notifier.loadMore();

      expect(container.read(homeFeedProvider).value!.currentPage, 2);
    });

    test('loadMore 실패: 대기 시간 안의 재호출은 repository를 부르지 않고, 지나면 다시 호출', () async {
      final repository = _LoadMoreFailRepository();
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      var fakeNow = DateTime(2026, 10, 29, 12);
      notifier.now = () => fakeNow;

      await notifier.loadMore();
      expect(repository.loadMoreCallCount, 1);
      expect(container.read(homeFeedProvider).hasError, true);

      // 실패 직후 재호출 — 대기 시간 안이라 차단
      await notifier.loadMore();
      expect(repository.loadMoreCallCount, 1, reason: '대기 시간 안에는 재시도하지 않음');

      // 대기 시간 직전 — 여전히 차단
      fakeNow = fakeNow.add(loadMoreRetryCooldown - const Duration(milliseconds: 1));
      await notifier.loadMore();
      expect(repository.loadMoreCallCount, 1);

      // 대기 시간 경과 — 재시도 허용, 성공 시 에러 해소
      fakeNow = fakeNow.add(const Duration(milliseconds: 1));
      repository.shouldFailLoadMore = false;
      await notifier.loadMore();
      expect(repository.loadMoreCallCount, 2);
      expect(container.read(homeFeedProvider).hasError, false);
      expect(container.read(homeFeedProvider).value!.currentPage, 1);
    });

    test('세션 초기화(invalidate) 후 > 이전 loadMore 실패 대기 시간 무시하고 바로 loadMore', () async {
      final repository = _LoadMoreFailRepository();
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      notifier.now = () => DateTime(2026, 10, 29, 12);
      await notifier.loadMore();
      expect(repository.loadMoreCallCount, 1);

      container.invalidate(homeFeedProvider);
      await container.read(homeFeedProvider.future);
      await container.read(homeFeedProvider.notifier).loadMore();

      expect(repository.loadMoreCallCount, 2);
    });

    test('세션 초기화(invalidate) 후 > 이전 세션 진행 중 loadMore가 새 loadMore를 막지 않고, 늦은 결과는 버림', () async {
      final repository = _GatedRepository();
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final previousSessionLoad = container.read(homeFeedProvider.notifier).loadMore();

      container.invalidate(homeFeedProvider);
      await container.read(homeFeedProvider.future);
      final callsBeforeNextLoad = repository.callCount;
      final nextSessionLoad = container.read(homeFeedProvider.notifier).loadMore();
      expect(repository.callCount - callsBeforeNextLoad, 1, reason: '이전 세션 진행 중 표시에 묶이지 않음');

      repository.gate.complete();
      await Future.wait([previousSessionLoad, nextSessionLoad]);

      final itemIds = container.read(homeFeedProvider).value!.items.map((item) => item.itemUuid);
      expect(itemIds, ['p0', 'p1'], reason: '이전 세션 loadMore 결과는 새 피드에 붙지 않음');
    });
  });

  group('HomeFeedNotifier 수동 새로고침·신고 제외 (#969)', () {
    test('수동 새로고침: 30초 제한 안이어도 조회 > refreshed', () async {
      final repository = _SwitchableRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      await notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final callsAfterAutoRefresh = repository.callCount;

      final refreshResult = await notifier.refresh(trigger: RefreshTrigger.manualRefresh);

      expect(refreshResult, HomeFeedRefreshResult.refreshed);
      expect(repository.callCount, greaterThan(callsAfterAutoRefresh), reason: '수동 새로고침은 제한 우회');
    });

    test('탐색 범위 변경 새로고침: 30초 제한 우회', () async {
      final repository = _SwitchableRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      await notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final callsAfterAutoRefresh = repository.callCount;

      final refreshResult = await notifier.refresh(trigger: RefreshTrigger.searchRangeChanged);

      expect(refreshResult, HomeFeedRefreshResult.refreshed);
      expect(repository.callCount, greaterThan(callsAfterAutoRefresh));
    });

    test('자동 새로고침: 제한에 걸리면 skipped', () async {
      final repository = _SwitchableRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      await notifier.refresh(trigger: RefreshTrigger.foregroundResume);

      final refreshResult = await notifier.refresh(trigger: RefreshTrigger.foregroundResume);

      expect(refreshResult, HomeFeedRefreshResult.skipped);
    });

    test('새로고침 실패: failed 반환 + 기존 목록 유지', () async {
      final repository = _SwitchableRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      repository.shouldFail = true;

      final refreshResult = await container
          .read(homeFeedProvider.notifier)
          .refresh(trigger: RefreshTrigger.manualRefresh);

      expect(refreshResult, HomeFeedRefreshResult.failed);
      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a']);
    });

    test('신고 물품 제외: 현재 목록에서 빠짐', () async {
      final repository = _SwitchableRepository({
        0: [_item('a'), _item('b'), _item('c')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);

      container.read(homeFeedProvider.notifier).excludeReportedItem('b');

      final itemIds = container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid);
      expect(itemIds, ['a', 'c']);
    });

    test('신고 물품 제외: 이후 새로고침·다음 페이지 응답에서도 빠짐', () async {
      final repository = _SwitchableRepository({
        0: [_item('a'), _item('b')],
        1: [_item('b'), _item('d')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      notifier.excludeReportedItem('b');

      await notifier.refresh(trigger: RefreshTrigger.manualRefresh);
      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a']);

      await notifier.loadMore();
      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a', 'd']);
    });
  });

  group('HomeFeedNotifier 진행 중 경쟁 (#969 리뷰)', () {
    test('우회 트리거: 진행 중 refresh가 있으면 끝난 뒤 1회 더 조회 > refreshed', () async {
      final repository = _GateablePagesRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      _expireFirstLoadThrottle(notifier);
      repository.gateByPageNumber[0] = Completer<void>();

      final autoRefresh = notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final manualRefresh = notifier.refresh(trigger: RefreshTrigger.manualRefresh);
      final callsWhileGated = repository.callCount;
      repository.gateByPageNumber.remove(0)!.complete();

      expect(await autoRefresh, HomeFeedRefreshResult.refreshed);
      expect(await manualRefresh, HomeFeedRefreshResult.refreshed);
      expect(repository.callCount, callsWhileGated + 1, reason: '진행 중 조회 뒤 수동 새로고침 1회 추가 조회');
    });

    test('우회 트리거 여러 번 대기: 추가 조회는 1회로 합침', () async {
      final repository = _GateablePagesRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      repository.gateByPageNumber[0] = Completer<void>();

      final autoRefresh = notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final firstManualRefresh = notifier.refresh(trigger: RefreshTrigger.manualRefresh);
      final secondManualRefresh = notifier.refresh(trigger: RefreshTrigger.searchRangeChanged);
      final callsWhileGated = repository.callCount;
      repository.gateByPageNumber.remove(0)!.complete();
      await Future.wait([autoRefresh, firstManualRefresh, secondManualRefresh]);

      expect(repository.callCount, callsWhileGated + 1);
    });

    test('자동 트리거: 진행 중이면 skipped (추가 조회 없음)', () async {
      final repository = _GateablePagesRepository({
        0: [_item('a')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      repository.gateByPageNumber[0] = Completer<void>();

      final firstRefresh = notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final secondRefresh = notifier.refresh(trigger: RefreshTrigger.foregroundResume);
      final callsWhileGated = repository.callCount;
      repository.gateByPageNumber.remove(0)!.complete();

      expect(await secondRefresh, HomeFeedRefreshResult.skipped);
      await firstRefresh;
      expect(repository.callCount, callsWhileGated);
    });

    test('refresh 진행 중 신고 제외: 로딩 상태 유지 + 새 결과에서도 제외', () async {
      final repository = _GateablePagesRepository({
        0: [_item('a'), _item('b')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      repository.gateByPageNumber[0] = Completer<void>();

      final refresh = notifier.refresh(trigger: RefreshTrigger.manualRefresh);
      notifier.excludeReportedItem('b');

      expect(container.read(homeFeedProvider).isLoading, true, reason: '진행 중 로딩 상태를 덮지 않음');
      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a']);
      repository.gateByPageNumber.remove(0)!.complete();
      await refresh;

      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a']);
    });

    test('loadMore 진행 중 신고 제외: 제외한 물품이 다시 붙지 않고 새 페이지에서도 제외', () async {
      final repository = _GateablePagesRepository({
        0: [_item('a'), _item('b')],
        1: [_item('b'), _item('c')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      final notifier = container.read(homeFeedProvider.notifier);
      repository.gateByPageNumber[1] = Completer<void>();

      final loadMore = notifier.loadMore();
      await Future<void>.delayed(Duration.zero);
      notifier.excludeReportedItem('b');
      repository.gateByPageNumber.remove(1)!.complete();
      await loadMore;

      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a', 'c']);
    });
  });

  group('HomeFeedNotifier 차단 회원 물품 제외', () {
    test('차단 즉시 현재 피드에서 그 회원 물품 제외 (다른 회원 물품 유지)', () async {
      final repository = _RecordingRepository({
        0: [_itemBy('a', 'blocked'), _itemBy('b', 'other'), _itemBy('c', 'blocked')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);

      container.read(memberBlockProvider.notifier).seed({'blocked'}, force: true);

      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['b']);
    });

    test('차단한 회원 물품은 이후 loadMore 결과에서도 제외', () async {
      final repository = _RecordingRepository({
        0: [_itemBy('a', 'other')],
        1: [_itemBy('b', 'blocked'), _itemBy('c', 'other')],
      });
      final container = _makeContainer(repository);
      await container.read(homeFeedProvider.future);
      container.read(memberBlockProvider.notifier).seed({'blocked'}, force: true);

      await container.read(homeFeedProvider.notifier).loadMore();

      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['a', 'c']);
    });
  });

  group('HomeFeedNotifier #995 오래된 피드', () {
    final firstLoadAt = DateTime(2026, 11, 4, 12);

    _FakeRepository makeRepository() => _FakeRepository({
      ItemSortField.recommended.serverName: {
        0: [_item('a'), _item('b')],
      },
    });

    // now를 첫 로드 전에 고정한 컨테이너
    Future<HomeFeedNotifier> loadAt(ProviderContainer container, DateTime Function() clock) async {
      final notifier = container.read(homeFeedProvider.notifier);
      notifier.now = clock;
      await container.read(homeFeedProvider.future);
      return notifier;
    }

    test('첫 로드 상태에 lastRefreshAt 기록', () async {
      final container = _makeContainer(makeRepository());
      await loadAt(container, () => firstLoadAt);

      expect(container.read(homeFeedProvider).valueOrNull?.lastRefreshAt, firstLoadAt);
    });

    test('10분 이내 refreshIfStale은 조회 안 함', () async {
      final repository = makeRepository();
      final container = _makeContainer(repository);
      var currentTime = firstLoadAt;
      final notifier = await loadAt(container, () => currentTime);
      final callsAfterLoad = repository.callCount;

      currentTime = firstLoadAt.add(const Duration(minutes: 9));

      expect(await notifier.refreshIfStale(), HomeFeedRefreshResult.skipped);
      expect(repository.callCount, callsAfterLoad);
    });

    test('10분 초과 refreshIfStale은 새로 조회', () async {
      final repository = makeRepository();
      final container = _makeContainer(repository);
      var currentTime = firstLoadAt;
      final notifier = await loadAt(container, () => currentTime);
      final callsAfterLoad = repository.callCount;

      currentTime = firstLoadAt.add(const Duration(minutes: 11));

      expect(await notifier.refreshIfStale(), HomeFeedRefreshResult.refreshed);
      expect(repository.callCount, greaterThan(callsAfterLoad));
      expect(container.read(homeFeedProvider).valueOrNull?.lastRefreshAt, currentTime);
    });

    test('새로고침 실패 시 lastRefreshAt 유지 > 다음 refreshIfStale 재시도', () async {
      final repository = makeRepository();
      final container = _makeContainer(repository);
      var currentTime = firstLoadAt;
      final notifier = await loadAt(container, () => currentTime);
      currentTime = firstLoadAt.add(const Duration(minutes: 11));

      repository.errorToThrow = Exception('boom');
      expect(await notifier.refreshIfStale(), HomeFeedRefreshResult.failed);
      expect(container.read(homeFeedProvider).valueOrNull?.lastRefreshAt, firstLoadAt);

      repository.errorToThrow = null;
      expect(await notifier.refreshIfStale(), HomeFeedRefreshResult.refreshed);
    });

    test('excludeUnavailableItem은 카드 제거 + 이후 조회에서도 제외', () async {
      final repository = makeRepository();
      final container = _makeContainer(repository);
      var currentTime = firstLoadAt;
      final notifier = await loadAt(container, () => currentTime);

      notifier.excludeUnavailableItem('a');
      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['b']);

      currentTime = firstLoadAt.add(const Duration(minutes: 11));
      await notifier.refreshIfStale();
      expect(container.read(homeFeedProvider).valueOrNull?.items.map((item) => item.itemUuid), ['b']);
    });

    test('첫 로드 실패 > retryInitialLoad 성공 시 lastRefreshAt 기록 > 10분 초과 refreshIfStale 조회', () async {
      final repository = _FailThenSucceedRepository(failCount: 1, items: [_item('a')]);
      final container = _makeContainer(repository);
      var currentTime = firstLoadAt;
      final notifier = container.read(homeFeedProvider.notifier);
      notifier.now = () => currentTime;
      await expectLater(container.read(homeFeedProvider.future), throwsException);

      await notifier.retryInitialLoad();
      expect(container.read(homeFeedProvider).valueOrNull?.lastRefreshAt, firstLoadAt);

      currentTime = firstLoadAt.add(const Duration(minutes: 11));
      expect(await notifier.refreshIfStale(), HomeFeedRefreshResult.refreshed);
    });

    test('피드 로드 전 호출은 무시', () async {
      final container = _makeContainer(makeRepository());
      final notifier = container.read(homeFeedProvider.notifier);

      expect(await notifier.refreshIfStale(), HomeFeedRefreshResult.skipped);
      expect(() => notifier.excludeUnavailableItem('x'), returnsNormally);
    });
  });
}
