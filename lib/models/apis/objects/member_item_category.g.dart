// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_item_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberItemCategory _$MemberItemCategoryFromJson(Map<String, dynamic> json) => MemberItemCategory(
  memberItemCategoryId: json['memberItemCategoryId'] as String?,
  itemCategory: json['itemCategory'] as String?,
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
);

Map<String, dynamic> _$MemberItemCategoryToJson(MemberItemCategory instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'memberItemCategoryId': instance.memberItemCategoryId,
  'itemCategory': instance.itemCategory,
};
