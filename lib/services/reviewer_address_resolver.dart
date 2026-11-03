import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/responses/trade_response.dart';
import 'package:romrom_fe/services/item_address_resolver.dart';
import 'package:romrom_fe/services/location_service.dart';
import 'package:romrom_fe/utils/location_utils.dart';

/// 후기 작성자 좌표 > 표시 주소 변환: 저장 주소 없는 작성자만, 회원별 1회, 병렬 조회
/// 조회는 LocationService 캐시 경유 (네트워크 동시 수 제한·디스크 캐시는 AddressLookupCache 담당, 테스트에서 [AddressLookup] 교체)
class ReviewerAddressResolver {
  ReviewerAddressResolver({AddressLookup? lookupAddress})
    : _lookupAddress = lookupAddress ?? LocationService().getAddressFromCoordinates;

  final AddressLookup _lookupAddress;

  /// 후기 목록 > 회원 ID별 '시군구 읍면동' (저장 주소 있음·좌표 없음·회원 ID 없음 제외, 조회 실패 회원은 결과에서 빠짐)
  Future<Map<String, String>> resolveMissingAddresses(List<TradeReview> reviews) async {
    final positionByMemberId = <String, NLatLng>{};
    for (final review in reviews) {
      final reviewer = review.reviewerMember;
      if (reviewer == null || _hasStoredAddress(reviewer)) continue;
      final memberId = reviewer.memberId;
      final latitude = reviewer.latitude;
      final longitude = reviewer.longitude;
      if (memberId == null || latitude == null || longitude == null) continue;
      positionByMemberId.putIfAbsent(memberId, () => NLatLng(latitude, longitude));
    }

    final memberIds = positionByMemberId.keys.toList();
    final addresses = await Future.wait(
      memberIds.map((memberId) => _lookupFormattedAddressOrNull(memberId, positionByMemberId[memberId]!)),
    );
    return {
      for (var index = 0; index < memberIds.length; index++)
        if (addresses[index] != null) memberIds[index]: addresses[index]!,
    };
  }

  bool _hasStoredAddress(Member reviewer) => reviewer.locationAddress?.isNotEmpty ?? false;

  /// 좌표 1건 > '시군구 읍면동' (결과 없음·예외 > null)
  Future<String?> _lookupFormattedAddressOrNull(String memberId, NLatLng position) async {
    try {
      final address = await _lookupAddress(position);
      return address == null ? null : LocationUtils.formatMediumAddress(address);
    } catch (error) {
      debugPrint('[profile review] reviewer address lookup failed for $memberId : $error');
      return null;
    }
  }
}
