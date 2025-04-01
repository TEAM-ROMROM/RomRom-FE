// lib/models/apis/responses/item_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'item_response.g.dart';

@JsonSerializable(explicitToJson: true)
class ItemResponse {
  final Member? member;
  final Item? item;
  final List<ItemImage>? itemImages;

  ItemResponse({
    this.member,
    this.item,
    this.itemImages,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) => _$ItemResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ItemResponseToJson(this);
}