// lib/models/apis/requests/member_request.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'member_request.g.dart';

@JsonSerializable(explicitToJson: true)
class MemberRequest {
  final Member? member;
  final List<int>? preferredCategories;
  final double? longitude;
  final double? latitude;
  final String? siDo;
  final String? siGunGu;
  final String? eupMyoenDong;
  final String? ri;
  final String? fullAddress;
  final String? roadAddress;

  MemberRequest({
    this.member,
    this.preferredCategories,
    this.longitude,
    this.latitude,
    this.siDo,
    this.siGunGu,
    this.eupMyoenDong,
    this.ri,
    this.fullAddress,
    this.roadAddress,
  });

  factory MemberRequest.fromJson(Map<String, dynamic> json) =>
      _$MemberRequestFromJson(json);
  Map<String, dynamic> toJson() => _$MemberRequestToJson(this);
}