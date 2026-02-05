// lib/models/apis/responses/member_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/member_location.dart';
import 'package:romrom_fe/models/apis/objects/member_item_category.dart';

part 'member_response.g.dart';

@JsonSerializable(explicitToJson: true)
class MemberResponse {
  final Member? member;
  final MemberLocation? memberLocation;
  @JsonKey(fromJson: _memberItemCategoriesFromJson, toJson: _memberItemCategoriesToJson)
  final List<MemberItemCategory>? memberItemCategories;

  /// 회원 목록 (차단 목록 조회 시 사용)
  @JsonKey(fromJson: _membersFromJson, toJson: _membersToJson)
  final List<Member>? members;

  MemberResponse({this.member, this.memberLocation, this.memberItemCategories, this.members});

  factory MemberResponse.fromJson(Map<String, dynamic> json) => _$MemberResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MemberResponseToJson(this);
}

// ----- 안전 파서 -----
List<MemberItemCategory> _memberItemCategoriesFromJson(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().map(MemberItemCategory.fromJson).toList();
  }
  return const <MemberItemCategory>[];
}

Object _memberItemCategoriesToJson(List<MemberItemCategory>? categories) =>
    categories?.map((e) => e.toJson()).toList() ?? [];

// ----- 회원 목록 파서 -----
List<Member> _membersFromJson(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().map(Member.fromJson).toList();
  }
  return const <Member>[];
}

Object _membersToJson(List<Member>? members) => members?.map((e) => e.toJson()).toList() ?? [];
