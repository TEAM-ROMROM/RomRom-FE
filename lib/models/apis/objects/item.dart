// lib/models/apis/objects/item.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'item.g.dart';

@JsonSerializable(explicitToJson: true)
class Item extends BaseEntity {
  final String? itemId;
  final Member? member;
  final String? itemName;
  final String? itemDescription;
  final String? itemCategory;
  final String? itemCondition;
  final List<String>? itemTradeOptions;
  final int? likeCount;
  final int? price;
  final double? longitude; // 경도
  final double? latitude; // 위도

  Item({
    super.createdDate,
    super.updatedDate,
    this.itemId,
    this.member,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemTradeOptions,
    this.likeCount,
    this.price,
    this.longitude,
    this.latitude,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}
