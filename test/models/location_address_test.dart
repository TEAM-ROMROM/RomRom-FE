import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/location_address.dart';

void main() {
  group('LocationAddress.siDoSiGunGuEupMyoenDongText', () {
    test('시도·시군구·읍면동 공백 1칸 연결, 리 제외', () {
      final address = LocationAddress(siDo: '서울특별시', siGunGu: '강남구', eupMyoenDong: '역삼동', ri: '1리');

      expect(address.siDoSiGunGuEupMyoenDongText, '서울특별시 강남구 역삼동');
    });

    test('빈 구역도 자리 유지 (앞뒤 공백 정리 없음 — 호출부별 trim 유지)', () {
      final address = LocationAddress(siDo: '', siGunGu: '', eupMyoenDong: '역삼동');

      expect(address.siDoSiGunGuEupMyoenDongText, '  역삼동');
      expect(address.siDoSiGunGuEupMyoenDongText.trim(), '역삼동');
    });
  });
}
