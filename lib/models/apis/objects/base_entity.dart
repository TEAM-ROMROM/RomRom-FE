// lib/models/apis/objects/base_entity.dart
import 'package:json_annotation/json_annotation.dart';

part 'base_entity.g.dart';

@JsonSerializable()
class BaseEntity {
  final DateTime? createdDate;
  final DateTime? updatedDate;

  BaseEntity({this.createdDate, this.updatedDate});

  factory BaseEntity.fromJson(Map<String, dynamic> json) => _$BaseEntityFromJson(json);
  Map<String, dynamic> toJson() => _$BaseEntityToJson(this);
}