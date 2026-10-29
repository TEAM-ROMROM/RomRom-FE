import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';

/// 물품 주소 변환 검증: 좌표 없음·조회 실패 > '미지정', 좌표 있음 > 캐시 주소 문자열, 결과 순서 유지
void main() {
  LocationAddress buildAddress({String siDo = '서울특별시', String siGunGu = '중구', String eupMyoenDong = '태평로1가'}) =>
      LocationAddress(siDo: siDo, siGunGu: siGunGu, eupMyoenDong: eupMyoenDong);

  group('resolveLocationText (피드·좋아요 목록 표시)', () {
    test('좌표 없음 > 미지정, 조회 안 함', () async {
      var lookupCount = 0;
      final resolver = ItemAddressResolver(
        lookupAddress: (position) async {
          lookupCount++;
          return buildAddress();
        },
      );

      expect(await resolver.resolveLocationText(Item(itemId: 'a')), '미지정');
      expect(await resolver.resolveLocationText(Item(itemId: 'b', latitude: 37.5)), '미지정');
      expect(lookupCount, 0);
    });

    test('좌표 있음 > 시도 시군구 읍면동, 조회 좌표 = 물품 좌표', () async {
      NLatLng? requestedPosition;
      final resolver = ItemAddressResolver(
        lookupAddress: (position) async {
          requestedPosition = position;
          return buildAddress();
        },
      );

      final locationText = await resolver.resolveLocationText(Item(latitude: 37.5665, longitude: 126.9780));

      expect(locationText, '서울특별시 중구 태평로1가');
      expect(requestedPosition?.latitude, 37.5665);
      expect(requestedPosition?.longitude, 126.9780);
    });

    test('조회 결과 null > 미지정', () async {
      final resolver = ItemAddressResolver(lookupAddress: (_) async => null);

      expect(await resolver.resolveLocationText(Item(latitude: 37.5, longitude: 127.0)), '미지정');
    });

    test('여러 물품 > 입력 순서대로 결과', () async {
      final resolver = ItemAddressResolver(
        lookupAddress: (position) async => buildAddress(eupMyoenDong: position.latitude.toString()),
      );

      final locationTexts = await resolver.resolveLocationTexts([
        Item(latitude: 1.0, longitude: 1.0),
        Item(),
        Item(latitude: 2.0, longitude: 2.0),
      ]);

      expect(locationTexts, ['서울특별시 중구 1.0', '미지정', '서울특별시 중구 2.0']);
    });
  });

  group('resolveAndCacheAddress (물품 address 채움)', () {
    test('좌표 없음 > address 미지정', () async {
      final resolver = ItemAddressResolver(lookupAddress: (_) async => buildAddress());
      final item = Item();

      expect(await resolver.resolveAndCacheAddress(item), '미지정');
      expect(item.address, '미지정');
      expect(item.displayLocation, '미지정');
    });

    test('좌표 있음 > address 채움 (앞뒤 공백 제거)', () async {
      final resolver = ItemAddressResolver(lookupAddress: (_) async => buildAddress(eupMyoenDong: ''));
      final item = Item(latitude: 37.5, longitude: 127.0);

      expect(await resolver.resolveAndCacheAddress(item), '서울특별시 중구');
      expect(item.address, '서울특별시 중구');
    });

    test('조회 null·빈 주소·예외 > address 미지정', () async {
      final nullResolver = ItemAddressResolver(lookupAddress: (_) async => null);
      final emptyResolver = ItemAddressResolver(
        lookupAddress: (_) async => buildAddress(siDo: '', siGunGu: '', eupMyoenDong: ''),
      );
      final throwingResolver = ItemAddressResolver(lookupAddress: (_) async => throw Exception('lookup failed'));

      for (final resolver in [nullResolver, emptyResolver, throwingResolver]) {
        final item = Item(latitude: 37.5, longitude: 127.0);
        expect(await resolver.resolveAndCacheAddress(item), '미지정');
        expect(item.address, '미지정');
      }
    });

    test('여러 물품 일괄 > 각 address 채움', () async {
      final resolver = ItemAddressResolver(lookupAddress: (_) async => buildAddress());
      final items = [Item(latitude: 1.0, longitude: 1.0), Item()];

      await resolver.resolveAndCacheAddresses(items);

      expect(items.map((item) => item.address), ['서울특별시 중구 태평로1가', '미지정']);
    });
  });
}
