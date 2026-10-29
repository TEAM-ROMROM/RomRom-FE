import 'dart:collection';
import 'dart:developer';

import 'package:romrom_fe/models/location_address.dart';

/// 좌표 > 주소 조회 캐시: 성공 결과 메모리 캐시, 진행 중 같은 좌표 요청 합치기, 예외 흡수
/// 키: 위도·경도 소수 4자리 반올림 (약 11m 이내 같은 주소 취급), 실패(null·예외)는 캐시하지 않음, 최대 개수 초과 시 오래된 순 제거
class AddressLookupCache {
  AddressLookupCache({required Future<LocationAddress?> Function(double latitude, double longitude) fetchAddress})
    : _fetchAddress = fetchAddress;

  // 캐시 키 좌표 반올림 자릿수 (소수 4자리)
  static const int _cacheKeyFractionDigits = 4;
  // 캐시 최대 주소 개수 (초과 시 가장 먼저 저장된 주소부터 제거)
  static const int maximumCachedAddressCount = 500;

  final Future<LocationAddress?> Function(double latitude, double longitude) _fetchAddress;
  // LinkedHashMap: 저장 순서 유지 > 첫 키가 가장 오래된 주소
  final LinkedHashMap<String, LocationAddress> _addressByCacheKey = LinkedHashMap<String, LocationAddress>();
  final Map<String, Future<LocationAddress?>> _pendingFetchByCacheKey = {};

  /// 좌표 > 주소 (캐시 > 진행 중 요청 공유 > 새 조회), 반환 좌표는 요청 값, 실패 시 null
  Future<LocationAddress?> lookup(double latitude, double longitude) async {
    final cacheKey = toCacheKey(latitude, longitude);

    final cachedAddress = _addressByCacheKey[cacheKey];
    if (cachedAddress != null) return _withRequestedCoordinates(cachedAddress, latitude, longitude);

    final fetchedAddress = await (_pendingFetchByCacheKey[cacheKey] ??= _fetchAndStore(cacheKey, latitude, longitude));
    if (fetchedAddress == null) return null;
    return _withRequestedCoordinates(fetchedAddress, latitude, longitude);
  }

  /// 좌표 > 캐시 키 '{위도},{경도}' (소수 4자리 반올림)
  static String toCacheKey(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(_cacheKeyFractionDigits)},${longitude.toStringAsFixed(_cacheKeyFractionDigits)}';

  /// 캐시·진행 중 요청 전체 비우기
  void clear() {
    _addressByCacheKey.clear();
    _pendingFetchByCacheKey.clear();
  }

  /// 조회 1회: 성공만 캐시, 예외는 null (진행 중 표시는 성공·실패 공통 제거)
  Future<LocationAddress?> _fetchAndStore(String cacheKey, double latitude, double longitude) async {
    try {
      // Future.sync: 동기 throw도 비동기 실패로 받아 진행 중 등록 이후에 제거되게 함
      final fetchedAddress = await Future.sync(() => _fetchAddress(latitude, longitude));
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

  /// 주소 저장 > 최대 개수 초과분 오래된 순 제거
  void _storeAddress(String cacheKey, LocationAddress address) {
    _addressByCacheKey[cacheKey] = address;
    while (_addressByCacheKey.length > maximumCachedAddressCount) {
      _addressByCacheKey.remove(_addressByCacheKey.keys.first);
    }
  }

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
