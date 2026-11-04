import 'package:romrom_fe/enums/location_verification_failure.dart';
import 'package:romrom_fe/models/location_address.dart';

/// 현재 GPS 위치 확인 결과 3종: 성공 > 좌표·정확도·동네 주소, 서비스 지역 밖 > 좌표·정확도(주소 없음), 실패 > 사유
class GpsLocationCheckResult {
  final LocationVerificationFailure? failure;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final LocationAddress? address;
  // 실제 GPS(가상 위치 아님, 정확도 통과)가 대한민국 밖 > 지도 직접 선택 허용
  final bool isOutsideServiceArea;

  const GpsLocationCheckResult._({
    this.failure,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.address,
    this.isOutsideServiceArea = false,
  });

  const GpsLocationCheckResult.failed(LocationVerificationFailure reason) : this._(failure: reason);

  const GpsLocationCheckResult.located({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required LocationAddress address,
  }) : this._(latitude: latitude, longitude: longitude, accuracyMeters: accuracyMeters, address: address);

  const GpsLocationCheckResult.outsideServiceArea({
    required double latitude,
    required double longitude,
    required double accuracyMeters,
  }) : this._(latitude: latitude, longitude: longitude, accuracyMeters: accuracyMeters, isOutsideServiceArea: true);

  bool get isLocated => failure == null && address != null && latitude != null && longitude != null;
}
