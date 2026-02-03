// lib/models/apis/objects/api_pageable.dart

import 'package:json_annotation/json_annotation.dart';

part 'api_pageable.g.dart';

/// Slice/Pageable 메타데이터용 공용 모델
@JsonSerializable()
class ApiPageable {
  /// 한 페이지(슬라이스)의 요소 개수
  final int size;

  /// 0-based 페이지(슬라이스) 인덱스
  final int number;

  const ApiPageable({
    required this.size,
    required this.number,
  });

  factory ApiPageable.fromJson(Map<String, dynamic> json) =>
      _$ApiPageableFromJson(json);

  Map<String, dynamic> toJson() => _$ApiPageableToJson(this);
}
