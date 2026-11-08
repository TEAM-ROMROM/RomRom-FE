// lib/models/apis/objects/member_location.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'member_location.g.dart';

@JsonSerializable(explicitToJson: true)
class MemberLocation extends BaseEntity {
  final String? memberLocationId;
  final String? member;
  final double? longitude;
  final double? latitude;
  final String? siDo;
  final String? siGunGu;
  final String? eupMyoenDong;
  final String? ri;

  /// 동네 인증 여부 (서버 단일 원본, 구버전 서버 > null)
  final bool? isLocationVerified;

  /// 동네 인증 시각 (미인증 > null)
  final DateTime? locationVerifiedAt;

  /// 동네 인증 방식 서버 값 (GPS / MANUAL_OUTSIDE_SERVICE_AREA, 미인증 > null)
  final String? locationVerificationMethod;

  MemberLocation({
    super.createdDate,
    super.updatedDate,
    this.memberLocationId,
    this.member,
    this.longitude,
    this.latitude,
    this.siDo,
    this.siGunGu,
    this.eupMyoenDong,
    this.ri,
    this.isLocationVerified,
    this.locationVerifiedAt,
    this.locationVerificationMethod,
  });

  factory MemberLocation.fromJson(Map<String, dynamic> json) => _$MemberLocationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MemberLocationToJson(this);
}
