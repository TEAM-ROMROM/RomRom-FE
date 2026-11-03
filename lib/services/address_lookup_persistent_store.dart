import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 좌표 > 주소 캐시 디스크 저장소: 앱 재시작 후에도 같은 좌표 재조회 방지
/// 순서 = 오래된 순 (AddressLookupCache의 제거 순서와 같음)
abstract class AddressLookupPersistentStore {
  /// 저장된 주소 전체 (캐시 키 > 주소, 오래된 순), 읽기 실패 시 빈 목록
  Future<List<MapEntry<String, LocationAddress>>> loadAddresses();

  /// 주소 전체 교체 저장 (오래된 순), 실패는 무시
  Future<void> saveAddresses(List<MapEntry<String, LocationAddress>> addressEntries);
}

/// 디스크 저장 안 함 (테스트·메모리 전용 캐시)
class NoOpAddressLookupPersistentStore implements AddressLookupPersistentStore {
  const NoOpAddressLookupPersistentStore();

  @override
  Future<List<MapEntry<String, LocationAddress>>> loadAddresses() async => const [];

  @override
  Future<void> saveAddresses(List<MapEntry<String, LocationAddress>> addressEntries) async {}
}

/// SharedPreferences JSON 저장: [[캐시 키, {siDo, siGunGu, eupMyoenDong, ri, currentAddress}], ...]
/// 좌표는 저장 안 함 (조회 시 요청 좌표로 다시 채움)
class SharedPreferencesAddressLookupPersistentStore implements AddressLookupPersistentStore {
  const SharedPreferencesAddressLookupPersistentStore();

  @override
  Future<List<MapEntry<String, LocationAddress>>> loadAddresses() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encodedAddresses = preferences.getString(StorageKeys.addressLookupCache.key);
      if (encodedAddresses == null) return const [];
      return (jsonDecode(encodedAddresses) as List<dynamic>).map(_toAddressEntry).toList();
    } catch (error) {
      debugPrint('[address lookup] persisted load failed : $error');
      return const [];
    }
  }

  @override
  Future<void> saveAddresses(List<MapEntry<String, LocationAddress>> addressEntries) async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encodedAddresses = jsonEncode([
        for (final entry in addressEntries) [entry.key, _toAddressJson(entry.value)],
      ]);
      await preferences.setString(StorageKeys.addressLookupCache.key, encodedAddresses);
    } catch (error) {
      debugPrint('[address lookup] persisted save failed : $error');
    }
  }

  /// [캐시 키, 주소 JSON] > 캐시 항목 (형식 다르면 예외 > 전체 로드 실패 처리)
  static MapEntry<String, LocationAddress> _toAddressEntry(dynamic encodedEntry) {
    final entryValues = encodedEntry as List<dynamic>;
    final addressJson = entryValues[1] as Map<String, dynamic>;
    return MapEntry(
      entryValues[0] as String,
      LocationAddress(
        siDo: addressJson['siDo'] as String,
        siGunGu: addressJson['siGunGu'] as String,
        eupMyoenDong: addressJson['eupMyoenDong'] as String,
        ri: addressJson['ri'] as String?,
        currentAddress: addressJson['currentAddress'] as String?,
      ),
    );
  }

  static Map<String, dynamic> _toAddressJson(LocationAddress address) => {
    'siDo': address.siDo,
    'siGunGu': address.siGunGu,
    'eupMyoenDong': address.eupMyoenDong,
    'ri': address.ri,
    'currentAddress': address.currentAddress,
  };
}
