import 'dart:async';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/reviewer_address_resolver.dart';

/// 후기 1건 (작성자 회원 ID·좌표·저장 주소 지정)
TradeReview buildReview({String? reviewerId, double? latitude, double? longitude, String? locationAddress}) {
  return TradeReview(
    reviewerMember: Member(
      memberId: reviewerId,
      latitude: latitude,
      longitude: longitude,
      locationAddress: locationAddress,
    ),
  );
}

/// 좌표 > 주소 (위도로 동 이름 구분)
LocationAddress buildAddress(double latitude) =>
    LocationAddress(siDo: '서울특별시', siGunGu: '중구', eupMyoenDong: '동-$latitude');

void main() {
  test('주소 없는 작성자 > 회원별 1회만, 모두 동시에 조회 시작 > 회원 ID별 시군구·읍면동', () async {
    final pendingLookups = <double, Completer<LocationAddress?>>{};
    final resolver = ReviewerAddressResolver(
      lookupAddress: (NLatLng position) => (pendingLookups[position.latitude] = Completer<LocationAddress?>()).future,
    );

    final resolving = resolver.resolveMissingAddresses([
      buildReview(reviewerId: 'first', latitude: 1, longitude: 1),
      buildReview(reviewerId: 'second', latitude: 2, longitude: 2),
      buildReview(reviewerId: 'first', latitude: 1, longitude: 1),
    ]);
    await Future<void>.delayed(Duration.zero);

    expect(pendingLookups.keys, [1, 2]);
    pendingLookups[2]!.complete(buildAddress(2));
    pendingLookups[1]!.complete(buildAddress(1));
    expect(await resolving, {'first': '중구 동-1.0', 'second': '중구 동-2.0'});
  });

  test('저장 주소 있음·좌표 없음·회원 ID 없음·작성자 없음 > 조회 안 함', () async {
    final lookedUpLatitudes = <double>[];
    final resolver = ReviewerAddressResolver(
      lookupAddress: (NLatLng position) async {
        lookedUpLatitudes.add(position.latitude);
        return buildAddress(position.latitude);
      },
    );

    final addresses = await resolver.resolveMissingAddresses([
      buildReview(reviewerId: 'has-address', latitude: 1, longitude: 1, locationAddress: '중구 명동'),
      buildReview(reviewerId: 'no-position'),
      buildReview(latitude: 3, longitude: 3),
      TradeReview(),
    ]);

    expect(lookedUpLatitudes, isEmpty);
    expect(addresses, isEmpty);
  });

  test('일부 조회 실패(결과 없음·예외) > 그 회원만 빠지고 나머지 결과 유지', () async {
    final resolver = ReviewerAddressResolver(
      lookupAddress: (NLatLng position) async {
        if (position.latitude == 1) return null;
        if (position.latitude == 2) throw Exception('lookup failed');
        return buildAddress(position.latitude);
      },
    );

    final addresses = await resolver.resolveMissingAddresses([
      buildReview(reviewerId: 'empty', latitude: 1, longitude: 1),
      buildReview(reviewerId: 'error', latitude: 2, longitude: 2),
      buildReview(reviewerId: 'ok', latitude: 3, longitude: 3),
    ]);

    expect(addresses, {'ok': '중구 동-3.0'});
  });
}
