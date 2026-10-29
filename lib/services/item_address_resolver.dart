import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/location_address.dart';
import 'package:romrom_fe/services/location_service.dart';

/// 좌표 > 주소 조회 함수 (실패 시 null)
typedef AddressLookup = Future<LocationAddress?> Function(NLatLng position);

/// 물품 좌표 > 표시 주소 변환: 피드·좋아요 표시 문자열, 물품 address 채움
/// 조회는 LocationService 캐시 경유 (테스트에서 [AddressLookup] 교체)
class ItemAddressResolver {
  ItemAddressResolver({AddressLookup? lookupAddress})
    : _lookupAddress = lookupAddress ?? LocationService().getAddressFromCoordinates;

  // 좌표 없음·조회 실패 시 표시 문구
  static const String unknownLocationText = '미지정';

  final AddressLookup _lookupAddress;

  /// 물품 좌표 > '시도 시군구 읍면동' (좌표 없음·조회 결과 없음 > '미지정')
  Future<String> resolveLocationText(Item item) async {
    final position = _toPosition(item);
    if (position == null) return unknownLocationText;
    final address = await _lookupAddress(position);
    if (address == null) return unknownLocationText;
    return '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
  }

  /// 물품 목록 > 표시 주소 목록 (병렬 조회, 결과 순서 = 입력 순서)
  Future<List<String>> resolveLocationTexts(List<Item> items) => Future.wait(items.map(resolveLocationText));

  /// 물품 좌표 > address 채움 후 반환 (앞뒤 공백 제거, 좌표 없음·빈 주소·조회 실패 > '미지정')
  Future<String> resolveAndCacheAddress(Item item) async {
    item.address = await _resolveTrimmedAddress(item);
    return item.address!;
  }

  /// 물품 목록 address 일괄 채움 (병렬)
  Future<void> resolveAndCacheAddresses(Iterable<Item> items) => Future.wait(items.map(resolveAndCacheAddress));

  Future<String> _resolveTrimmedAddress(Item item) async {
    final position = _toPosition(item);
    if (position == null) return unknownLocationText;
    try {
      final address = await _lookupAddress(position);
      if (address == null) return unknownLocationText;
      final trimmedAddress = '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}'.trim();
      return trimmedAddress.isEmpty ? unknownLocationText : trimmedAddress;
    } catch (_) {
      return unknownLocationText;
    }
  }

  NLatLng? _toPosition(Item item) {
    final latitude = item.latitude;
    final longitude = item.longitude;
    if (latitude == null || longitude == null) return null;
    return NLatLng(latitude, longitude);
  }
}
