import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/address_lookup_cache.dart';
import 'package:romrom_fe/services/address_lookup_persistent_store.dart';

/// 테스트용 디스크 저장소: 메모리 목록, 저장 횟수 기록
class _InMemoryAddressLookupPersistentStore implements AddressLookupPersistentStore {
  _InMemoryAddressLookupPersistentStore([List<MapEntry<String, LocationAddress>> initialEntries = const []])
    : savedEntries = List.of(initialEntries);

  List<MapEntry<String, LocationAddress>> savedEntries;
  int saveCount = 0;

  @override
  Future<List<MapEntry<String, LocationAddress>>> loadAddresses() async => List.of(savedEntries);

  @override
  Future<void> saveAddresses(List<MapEntry<String, LocationAddress>> addressEntries) async {
    saveCount++;
    savedEntries = List.of(addressEntries);
  }
}

/// 주소 캐시 검증: 순차·동시 중복 합치기, 실패 미캐시, 예외 흡수, 키 반올림, 요청 좌표 반환, 디스크 로드·저장, 동시 조회 제한
void main() {
  LocationAddress buildSeoulAddress(double latitude, double longitude) =>
      LocationAddress(siDo: '서울특별시', siGunGu: '중구', eupMyoenDong: '태평로1가', latitude: latitude, longitude: longitude);

  test('같은 좌표 2회 순차 조회 > fetch 1회', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async {
        fetchCount++;
        return buildSeoulAddress(latitude, longitude);
      },
    );

    await cache.lookup(37.5665, 126.9780);
    await cache.lookup(37.5665, 126.9780);

    expect(fetchCount, 1);
  });

  test('같은 좌표 동시 3회 조회 > fetch 1회, 결과 동일', () async {
    var fetchCount = 0;
    final fetchCompleter = Completer<LocationAddress?>();
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) {
        fetchCount++;
        return fetchCompleter.future;
      },
    );

    final pendingLookups = [
      cache.lookup(37.5665, 126.9780),
      cache.lookup(37.5665, 126.9780),
      cache.lookup(37.5665, 126.9780),
    ];
    fetchCompleter.complete(buildSeoulAddress(37.5665, 126.9780));
    final addresses = await Future.wait(pendingLookups);

    expect(fetchCount, 1);
    expect(addresses.map((address) => address?.eupMyoenDong).toSet(), {'태평로1가'});
  });

  test('fetch가 null 반환 > 캐시 안 함, 다음 조회에서 다시 fetch', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async {
        fetchCount++;
        return null;
      },
    );

    expect(await cache.lookup(37.5665, 126.9780), isNull);
    expect(await cache.lookup(37.5665, 126.9780), isNull);
    expect(fetchCount, 2);
  });

  test('fetch 예외 > lookup은 null 반환, 캐시 안 함', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async {
        fetchCount++;
        throw Exception('network down');
      },
    );

    expect(await cache.lookup(37.5665, 126.9780), isNull);
    expect(await cache.lookup(37.5665, 126.9780), isNull);
    expect(fetchCount, 2);
  });

  test('fetch 동기 예외 > lookup은 null 반환, 다음 조회에서 다시 fetch', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) {
        fetchCount++;
        throw StateError('sync failure');
      },
    );

    expect(await cache.lookup(37.5665, 126.9780), isNull);
    expect(await cache.lookup(37.5665, 126.9780), isNull);
    expect(fetchCount, 2);
  });

  test('소수 5자리 이하만 다른 좌표 > 같은 키', () {
    expect(AddressLookupCache.toCacheKey(37.56651, 126.97802), AddressLookupCache.toCacheKey(37.56654, 126.97804));
    expect(AddressLookupCache.toCacheKey(37.5665, 126.9780), isNot(AddressLookupCache.toCacheKey(37.5666, 126.9780)));
  });

  test('캐시 결과 반환 시 위도·경도는 요청 좌표', () async {
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async => buildSeoulAddress(latitude, longitude),
    );

    await cache.lookup(37.56651, 126.97802);
    final cachedAddress = await cache.lookup(37.56654, 126.97804);

    expect(cachedAddress?.latitude, 37.56654);
    expect(cachedAddress?.longitude, 126.97804);
    expect(cachedAddress?.eupMyoenDong, '태평로1가');
  });

  test('최대 개수 초과 (501개 서로 다른 키) > 가장 오래된 첫 키 다시 fetch', () async {
    final fetchCountByCacheKey = <String, int>{};
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async {
        final cacheKey = AddressLookupCache.toCacheKey(latitude, longitude);
        fetchCountByCacheKey[cacheKey] = (fetchCountByCacheKey[cacheKey] ?? 0) + 1;
        return buildSeoulAddress(latitude, longitude);
      },
    );

    // 위도 0.001 간격 > 501개 서로 다른 키
    for (var index = 0; index <= AddressLookupCache.maximumCachedAddressCount; index++) {
      await cache.lookup(37.0 + index * 0.001, 127.0);
    }
    await cache.lookup(37.0, 127.0);
    await cache.lookup(37.0 + AddressLookupCache.maximumCachedAddressCount * 0.001, 127.0);

    expect(AddressLookupCache.maximumCachedAddressCount, 500);
    expect(fetchCountByCacheKey[AddressLookupCache.toCacheKey(37.0, 127.0)], 2);
    expect(fetchCountByCacheKey[AddressLookupCache.toCacheKey(37.5, 127.0)], 1);
  });

  test('clear 후 > 다시 fetch', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async {
        fetchCount++;
        return buildSeoulAddress(latitude, longitude);
      },
    );

    await cache.lookup(37.5665, 126.9780);
    cache.clear();
    await cache.lookup(37.5665, 126.9780);

    expect(fetchCount, 2);
  });

  // LocationService의 http 클라이언트는 싱글톤 내부 필드라 주입 불가 > 같은 .timeout 동작을 fetchAddress로 재현
  test('fetch가 시간 초과(TimeoutException) > null, 캐시 안 함, 이후 조회에서 다시 fetch', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) {
        fetchCount++;
        if (fetchCount == 1) {
          // 응답이 영원히 오지 않는 요청
          return Completer<LocationAddress?>().future.timeout(const Duration(milliseconds: 50));
        }
        return Future.value(buildSeoulAddress(latitude, longitude));
      },
    );

    final timedOutAddress = await cache.lookup(37.5665, 126.9780);
    final retriedAddress = await cache.lookup(37.5665, 126.9780);

    expect(timedOutAddress, isNull);
    expect(retriedAddress?.eupMyoenDong, '태평로1가');
    expect(fetchCount, 2, reason: '시간 초과 결과는 캐시·진행 중 표시에 남지 않음');
  });

  group('디스크 캐시', () {
    test('디스크에 저장된 좌표 > fetch 없이 반환 (앱 재시작 후 재조회 방지)', () async {
      var fetchCount = 0;
      final cacheKey = AddressLookupCache.toCacheKey(37.5665, 126.9780);
      final cache = AddressLookupCache(
        persistentStore: _InMemoryAddressLookupPersistentStore([MapEntry(cacheKey, buildSeoulAddress(0, 0))]),
        fetchAddress: (latitude, longitude) async {
          fetchCount++;
          return buildSeoulAddress(latitude, longitude);
        },
      );

      final cachedAddress = await cache.lookup(37.5665, 126.9780);

      expect(fetchCount, 0);
      expect(cachedAddress?.eupMyoenDong, '태평로1가');
      expect(cachedAddress?.latitude, 37.5665);
    });

    test('새 주소 여러 건 > 묶음 저장 1회, 저장 순서 = 조회 순서', () async {
      final persistentStore = _InMemoryAddressLookupPersistentStore();
      final cache = AddressLookupCache(
        persistentStore: persistentStore,
        persistDelay: const Duration(milliseconds: 20),
        fetchAddress: (latitude, longitude) async => buildSeoulAddress(latitude, longitude),
      );

      await cache.lookup(37.0, 127.0);
      await cache.lookup(37.1, 127.0);
      await Future<void>.delayed(const Duration(milliseconds: 60));

      expect(persistentStore.saveCount, 1);
      expect(persistentStore.savedEntries.map((entry) => entry.key), [
        AddressLookupCache.toCacheKey(37.0, 127.0),
        AddressLookupCache.toCacheKey(37.1, 127.0),
      ]);
    });

    test('디스크 로드 실패 > 메모리 캐시로 계속 동작', () async {
      var fetchCount = 0;
      final cache = AddressLookupCache(
        persistentStore: _ThrowingAddressLookupPersistentStore(),
        fetchAddress: (latitude, longitude) async {
          fetchCount++;
          return buildSeoulAddress(latitude, longitude);
        },
      );

      expect((await cache.lookup(37.5665, 126.9780))?.eupMyoenDong, '태평로1가');
      expect((await cache.lookup(37.5665, 126.9780))?.eupMyoenDong, '태평로1가');
      expect(fetchCount, 1);
    });

    test('clear > 디스크도 비움', () async {
      final persistentStore = _InMemoryAddressLookupPersistentStore();
      final cache = AddressLookupCache(
        persistentStore: persistentStore,
        fetchAddress: (latitude, longitude) async => buildSeoulAddress(latitude, longitude),
      );

      await cache.lookup(37.5665, 126.9780);
      await cache.flushPersistedAddresses();
      expect(persistentStore.savedEntries, hasLength(1));

      cache.clear();
      await Future<void>.delayed(Duration.zero);

      expect(persistentStore.savedEntries, isEmpty);
    });
  });

  test('서로 다른 좌표 10건 동시 조회 > 네트워크 동시 조회 최대 4건', () async {
    var runningFetchCount = 0;
    var maximumRunningFetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchAddress: (latitude, longitude) async {
        runningFetchCount++;
        if (runningFetchCount > maximumRunningFetchCount) maximumRunningFetchCount = runningFetchCount;
        await Future<void>.delayed(const Duration(milliseconds: 5));
        runningFetchCount--;
        return buildSeoulAddress(latitude, longitude);
      },
    );

    final addresses = await Future.wait([
      for (var index = 0; index < 10; index++) cache.lookup(37.0 + index * 0.001, 127.0),
    ]);

    expect(addresses.every((address) => address?.eupMyoenDong == '태평로1가'), isTrue);
    expect(AddressLookupCache.maximumConcurrentFetchCount, 4);
    expect(maximumRunningFetchCount, AddressLookupCache.maximumConcurrentFetchCount);
  });

  test('대기 포함 전체 제한 시간 초과 > null(미지정), 진행 중 표시 제거 > 다음 조회에서 다시 fetch', () async {
    var fetchCount = 0;
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchTimeout: const Duration(milliseconds: 30),
      fetchAddress: (latitude, longitude) {
        fetchCount++;
        if (fetchCount == 1) return Completer<LocationAddress?>().future;
        return Future.value(buildSeoulAddress(latitude, longitude));
      },
    );

    final timedOutAddress = await cache.lookup(37.5665, 126.9780);
    final retriedAddress = await cache.lookup(37.5665, 126.9780);

    expect(timedOutAddress, isNull);
    expect(retriedAddress?.eupMyoenDong, '태평로1가');
    expect(fetchCount, 2);
    expect(AddressLookupCache.defaultFetchTimeout, const Duration(seconds: 10));
  });

  test('대기열에서 제한 시간 초과한 조회 > 슬롯 차례가 와도 네트워크 조회 안 함', () async {
    final stuckFetchCompleters = <Completer<LocationAddress?>>[];
    final cache = AddressLookupCache(
      persistentStore: const NoOpAddressLookupPersistentStore(),
      fetchTimeout: const Duration(milliseconds: 30),
      fetchAddress: (latitude, longitude) {
        final completer = Completer<LocationAddress?>();
        stuckFetchCompleters.add(completer);
        return completer.future;
      },
    );

    // 슬롯 4개 점유 + 대기 1건 > 모두 제한 시간 초과
    final addresses = await Future.wait([
      for (var index = 0; index < 5; index++) cache.lookup(37.0 + index * 0.001, 127.0),
    ]);
    for (final completer in stuckFetchCompleters.toList()) {
      completer.complete(null);
    }
    await pumpEventQueue();

    expect(addresses, everyElement(isNull));
    expect(stuckFetchCompleters, hasLength(AddressLookupCache.maximumConcurrentFetchCount));
  });
}

/// 테스트용 디스크 저장소: 읽기·쓰기 모두 실패
class _ThrowingAddressLookupPersistentStore implements AddressLookupPersistentStore {
  @override
  Future<List<MapEntry<String, LocationAddress>>> loadAddresses() async => throw Exception('disk read failed');

  @override
  Future<void> saveAddresses(List<MapEntry<String, LocationAddress>> addressEntries) async {}
}
