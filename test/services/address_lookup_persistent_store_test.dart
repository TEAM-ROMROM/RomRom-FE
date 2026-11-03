import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/storage_keys.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/address_lookup_persistent_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 주소 디스크 저장 검증: 저장 > 다시 읽기 (순서·필드 유지), 저장 없음·깨진 값 > 빈 목록
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = SharedPreferencesAddressLookupPersistentStore();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('저장 후 읽기 > 같은 순서, 시도·시군구·읍면동·리·현재 주소 유지', () async {
    await store.saveAddresses([
      MapEntry('37.0000,127.0000', LocationAddress(siDo: '서울특별시', siGunGu: '중구', eupMyoenDong: '태평로1가')),
      MapEntry(
        '37.1000,127.1000',
        LocationAddress(siDo: '경기도', siGunGu: '양평군', eupMyoenDong: '양평읍', ri: '양근리', currentAddress: '양근리'),
      ),
    ]);

    final loadedEntries = await store.loadAddresses();

    expect(loadedEntries.map((entry) => entry.key), ['37.0000,127.0000', '37.1000,127.1000']);
    expect(loadedEntries.first.value.siDoSiGunGuEupMyoenDongText, '서울특별시 중구 태평로1가');
    expect(loadedEntries.last.value.ri, '양근리');
    expect(loadedEntries.last.value.currentAddress, '양근리');
  });

  test('저장 없음 > 빈 목록', () async {
    expect(await store.loadAddresses(), isEmpty);
  });

  test('깨진 저장 값 > 빈 목록 (예외 없음)', () async {
    SharedPreferences.setMockInitialValues({StorageKeys.addressLookupCache.key: '{not a list'});

    expect(await store.loadAddresses(), isEmpty);
  });
}
