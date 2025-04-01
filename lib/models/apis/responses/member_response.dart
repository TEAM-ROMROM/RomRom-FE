// lib/models/apis/responses/member_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/member_location.dart';

part 'member_response.g.dart';

@JsonSerializable(explicitToJson: true)
class MemberResponse {
  final Member? member;
  final MemberLocation? memberLocation;

  MemberResponse({
    this.member,
    this.memberLocation,
  });

  factory MemberResponse.fromJson(Map<String, dynamic> json) =>
      _$MemberResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MemberResponseToJson(this);
}