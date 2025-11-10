// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberResponse _$MemberResponseFromJson(Map<String, dynamic> json) =>
    MemberResponse(
      member: json['member'] == null
          ? null
          : Member.fromJson(json['member'] as Map<String, dynamic>),
      memberLocation: json['memberLocation'] == null
          ? null
          : MemberLocation.fromJson(
              json['memberLocation'] as Map<String, dynamic>,
            ),
      memberItemCategories: _memberItemCategoriesFromJson(
        json['memberItemCategories'],
      ),
    );

Map<String, dynamic> _$MemberResponseToJson(MemberResponse instance) =>
    <String, dynamic>{
      'member': instance.member?.toJson(),
      'memberLocation': instance.memberLocation?.toJson(),
      'memberItemCategories': _memberItemCategoriesToJson(
        instance.memberItemCategories,
      ),
    };
