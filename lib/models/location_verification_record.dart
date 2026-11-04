import 'package:flutter/foundation.dart';
import 'package:romrom_fe/enums/location_verification_method.dart';

/// 동네 인증 기록 1건: 회원 ID, 인증 시각, 인증 좌표, 인증 방식 (앱 로컬 저장, 서버 인증 플래그는 #973)
@immutable
class LocationVerificationRecord {
  final String memberId;
  final DateTime verifiedAt;
  final double latitude;
  final double longitude;
  final LocationVerificationMethod method;

  const LocationVerificationRecord({
    required this.memberId,
    required this.verifiedAt,
    required this.latitude,
    required this.longitude,
    this.method = LocationVerificationMethod.gps,
  });

  /// 저장 JSON > 기록 (필수 값 누락·형식 오류 > null)
  static LocationVerificationRecord? tryFromJson(Map<String, dynamic> json) {
    final memberId = json['memberId'];
    final verifiedAt = DateTime.tryParse(json['verifiedAt']?.toString() ?? '');
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    if (memberId is! String || memberId.isEmpty || verifiedAt == null) return null;
    if (latitude is! num || longitude is! num) return null;
    return LocationVerificationRecord(
      memberId: memberId,
      verifiedAt: verifiedAt,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      method: LocationVerificationMethod.fromStorageValue(json['method']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'memberId': memberId,
    'verifiedAt': verifiedAt.toIso8601String(),
    'latitude': latitude,
    'longitude': longitude,
    'method': method.storageValue,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationVerificationRecord &&
          other.memberId == memberId &&
          other.verifiedAt == verifiedAt &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.method == method;

  @override
  int get hashCode => Object.hash(memberId, verifiedAt, latitude, longitude, method);

  @override
  String toString() => 'LocationVerificationRecord(memberId: $memberId, verifiedAt: $verifiedAt, method: $method)';
}
