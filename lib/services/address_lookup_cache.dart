import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/address_lookup_persistent_store.dart';
import 'package:romrom_fe/utils/concurrency_limiter.dart';

/// 좌표 > 주소 조회 캐시: 성공 결과 메모리·디스크 캐시, 진행 중 같은 좌표 요청 합치기, 네트워크 동시 조회 제한, 예외 흡수
/// 키: 위도·경도 소수 4자리 반올림 (약 11m 이내 같은 주소 취급), 실패(null·예외)는 캐시하지 않음, 최대 개수 초과 시 오래된 순 제거
/// 디스크: 첫 조회 때 1회 로드, 새 주소 저장 후 [persistDelay] 동안 모아 1회 저장
class AddressLookupCache {
  AddressLookupCache({
    required Future<LocationAddress?> Function(double latitude, double longitude) fetchAddress,
    AddressLookupPersistentStore persistentStore = const SharedPreferencesAddressLookupPersistentStore(),
    this.persistDelay = defaultPersistDelay,
    this.fetchTimeout = defaultFetchTimeout,
  }) : _fetchAddress = fetchAddress,
       _persistentStore = persistentStore;

  // 캐시 키 좌표 반올림 자릿수 (소수 4자리)
  static const int _cacheKeyFractionDigits = 4;
  // 캐시 최대 주소 개수 (메모리·디스크 공통, 초과 시 가장 먼저 저장된 주소부터 제거)
  static const int maximumCachedAddressCount = 500;
  // 네트워크 주소 조회 동시 최대 수 (목록 수백 건 동시 요청 방지, 캐시 적중은 대기 없음)
  static const int maximumConcurrentFetchCount = 4;
  // 디스크 묶음 저장 대기 시간 (연속 저장을 1회로)
  static const Duration defaultPersistDelay = Duration(seconds: 2);
  // 조회 1건 전체 제한 시간 (슬롯 대기 포함, 초과 시 null > 다음 조회에서 재시도)
  static const Duration defaultFetchTimeout = Duration(seconds: 10);

  final Future<LocationAddress?> Function(double latitude, double longitude) _fetchAddress;
  final AddressLookupPersistentStore _persistentStore;
  final Duration persistDelay;
  final Duration fetchTimeout;
  final ConcurrencyLimiter _fetchLimiter = ConcurrencyLimiter(maximumConcurrentCount: maximumConcurrentFetchCount);
  // LinkedHashMap: 저장 순서 유지 > 첫 키가 가장 오래된 주소
  final LinkedHashMap<String, LocationAddress> _addressByCacheKey = LinkedHashMap<String, LocationAddress>();
  final Map<String, Future<LocationAddress?>> _pendingFetchByCacheKey = {};

  bool _hasLoadedPersistedAddresses = false;
  Future<void>? _loadingPersistedAddresses;
  Timer? _persistTimer;

  /// 좌표 > 주소 (디스크 로드 1회 > 캐시 > 진행 중 요청 공유 > 새 조회), 반환 좌표는 요청 값, 실패 시 null
  Future<LocationAddress?> lookup(double latitude, double longitude) async {
    final cacheKey = toCacheKey(latitude, longitude);
    if (!_hasLoadedPersistedAddresses) await (_loadingPersistedAddresses ??= _loadPersistedAddresses());

    final cachedAddress = _addressByCacheKey[cacheKey];
    if (cachedAddress != null) return _withRequestedCoordinates(cachedAddress, latitude, longitude);

    final fetchedAddress = await (_pendingFetchByCacheKey[cacheKey] ??= _fetchAndStore(cacheKey, latitude, longitude));
    if (fetchedAddress == null) return null;
    return _withRequestedCoordinates(fetchedAddress, latitude, longitude);
  }

  /// 좌표 > 캐시 키 '{위도},{경도}' (소수 4자리 반올림)
  static String toCacheKey(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(_cacheKeyFractionDigits)},${longitude.toStringAsFixed(_cacheKeyFractionDigits)}';

  /// 캐시·진행 중 요청·디스크 저장 전체 비우기
  void clear() {
    _addressByCacheKey.clear();
    _pendingFetchByCacheKey.clear();
    _hasLoadedPersistedAddresses = true;
    _persistTimer?.cancel();
    _persistTimer = null;
    unawaited(_persistentStore.saveAddresses(const []));
  }

  /// 대기 중 묶음 저장 즉시 실행 (테스트 검증용)
  @visibleForTesting
  Future<void> flushPersistedAddresses() {
    _persistTimer?.cancel();
    _persistTimer = null;
    return _persistAddresses();
  }

  /// 디스크 주소 로드 (오래된 순) > 로드 중 메모리에 들어온 주소가 더 최신이라 뒤에 둠, 실패 시 메모리만 사용
  Future<void> _loadPersistedAddresses() async {
    try {
      final persistedEntries = await _persistentStore.loadAddresses();
      if (_hasLoadedPersistedAddresses) return;
      final newerEntries = _addressByCacheKey.entries.toList();
      _addressByCacheKey
        ..clear()
        ..addEntries(persistedEntries);
      for (final newerEntry in newerEntries) {
        _addressByCacheKey.remove(newerEntry.key);
        _addressByCacheKey[newerEntry.key] = newerEntry.value;
      }
      _removeOldestOverflow();
    } catch (error) {
      log('[address lookup] persisted load failed : $error');
    } finally {
      _hasLoadedPersistedAddresses = true;
      _loadingPersistedAddresses = null;
    }
  }

  /// 조회 1회: 성공만 캐시, 예외는 null (진행 중 표시는 성공·실패 공통 제거)
  Future<LocationAddress?> _fetchAndStore(String cacheKey, double latitude, double longitude) async {
    try {
      // 동시 조회 제한 + 대기 포함 제한 시간 (작업 동기 throw도 비동기 실패로 전달)
      var isTimedOut = false;
      final fetchedAddress = await _fetchLimiter
          // 대기 중 시간 초과된 조회는 슬롯 차례가 와도 네트워크 호출 안 함
          .run(() => isTimedOut ? null : _fetchAddress(latitude, longitude))
          .timeout(
            fetchTimeout,
            onTimeout: () {
              isTimedOut = true;
              log('[address lookup] timed out : $cacheKey');
              return null;
            },
          );
      // clear() 이후 늦게 도착한 결과는 저장 안 함
      final isStillPending = _pendingFetchByCacheKey.containsKey(cacheKey);
      if (fetchedAddress != null && isStillPending) _storeAddress(cacheKey, fetchedAddress);
      return fetchedAddress;
    } catch (error) {
      log('[address lookup] failed : $error');
      return null;
    } finally {
      _pendingFetchByCacheKey.remove(cacheKey);
    }
  }

  /// 주소 저장 > 최대 개수 초과분 오래된 순 제거 > 디스크 묶음 저장 예약
  void _storeAddress(String cacheKey, LocationAddress address) {
    _addressByCacheKey[cacheKey] = address;
    _removeOldestOverflow();
    _persistTimer ??= Timer(persistDelay, () {
      _persistTimer = null;
      unawaited(_persistAddresses());
    });
  }

  void _removeOldestOverflow() {
    while (_addressByCacheKey.length > maximumCachedAddressCount) {
      _addressByCacheKey.remove(_addressByCacheKey.keys.first);
    }
  }

  /// 메모리 주소 전체 > 디스크 (오래된 순)
  Future<void> _persistAddresses() => _persistentStore.saveAddresses(_addressByCacheKey.entries.toList());

  /// 캐시된 주소 > 요청 좌표로 재구성한 주소
  LocationAddress _withRequestedCoordinates(LocationAddress address, double latitude, double longitude) =>
      LocationAddress(
        siDo: address.siDo,
        siGunGu: address.siGunGu,
        eupMyoenDong: address.eupMyoenDong,
        ri: address.ri,
        currentAddress: address.currentAddress,
        latitude: latitude,
        longitude: longitude,
      );
}
