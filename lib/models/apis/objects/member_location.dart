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
  });

  factory MemberLocation.fromJson(Map<String, dynamic> json) => _$MemberLocationFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MemberLocationToJson(this);
}
