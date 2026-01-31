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

  MemberResponse({this.member, this.memberLocation, this.memberItemCategories});

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
