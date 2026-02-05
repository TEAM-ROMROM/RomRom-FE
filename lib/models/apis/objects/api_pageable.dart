import 'package:json_annotation/json_annotation.dart';

part 'api_pageable.g.dart';

int _intFromJson(Object? v) => (v as num?)?.toInt() ?? 0;
bool _boolFromJson(Object? v) => (v as bool?) ?? false;

@JsonSerializable(explicitToJson: true)
class ApiPageable {
  @JsonKey(fromJson: _intFromJson)
  final int pageNumber;

  @JsonKey(fromJson: _intFromJson)
  final int pageSize;

  @JsonKey(fromJson: _intFromJson)
  final int offset;

  @JsonKey(fromJson: _boolFromJson)
  final bool paged;

  @JsonKey(fromJson: _boolFromJson)
  final bool unpaged;

  final ApiSort? sort; // sort 모델이 있으면 유지

  const ApiPageable({
    this.pageNumber = 0,
    this.pageSize = 0,
    this.offset = 0,
    this.paged = false,
    this.unpaged = false,
    this.sort,
  });

  factory ApiPageable.fromJson(Map<String, dynamic> json) => _$ApiPageableFromJson(json);
  Map<String, dynamic> toJson() => _$ApiPageableToJson(this);
}

@JsonSerializable()
class ApiSort {
  final bool? empty;
  final bool? sorted;
  final bool? unsorted;

  const ApiSort({this.empty, this.sorted, this.unsorted});

  factory ApiSort.fromJson(Map<String, dynamic> json) => _$ApiSortFromJson(json);
  Map<String, dynamic> toJson() => _$ApiSortToJson(this);
}
