// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiPage _$ApiPageFromJson(Map<String, dynamic> json) => ApiPage(
  size: (json['size'] as num).toInt(),
  number: (json['number'] as num).toInt(),
  totalElements: (json['totalElements'] as num).toInt(),
  totalPages: (json['totalPages'] as num).toInt(),
);

Map<String, dynamic> _$ApiPageToJson(ApiPage instance) => <String, dynamic>{
  'size': instance.size,
  'number': instance.number,
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
};
