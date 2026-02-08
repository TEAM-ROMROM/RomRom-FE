// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_pageable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiPageable _$ApiPageableFromJson(Map<String, dynamic> json) => ApiPageable(
  pageNumber: json['pageNumber'] == null ? 0 : _intFromJson(json['pageNumber']),
  pageSize: json['pageSize'] == null ? 0 : _intFromJson(json['pageSize']),
  offset: json['offset'] == null ? 0 : _intFromJson(json['offset']),
  paged: json['paged'] == null ? false : _boolFromJson(json['paged']),
  unpaged: json['unpaged'] == null ? false : _boolFromJson(json['unpaged']),
  sort: json['sort'] == null ? null : ApiSort.fromJson(json['sort'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ApiPageableToJson(ApiPageable instance) => <String, dynamic>{
  'pageNumber': instance.pageNumber,
  'pageSize': instance.pageSize,
  'offset': instance.offset,
  'paged': instance.paged,
  'unpaged': instance.unpaged,
  'sort': instance.sort?.toJson(),
};

ApiSort _$ApiSortFromJson(Map<String, dynamic> json) =>
    ApiSort(empty: json['empty'] as bool?, sorted: json['sorted'] as bool?, unsorted: json['unsorted'] as bool?);

Map<String, dynamic> _$ApiSortToJson(ApiSort instance) => <String, dynamic>{
  'empty': instance.empty,
  'sorted': instance.sorted,
  'unsorted': instance.unsorted,
};
