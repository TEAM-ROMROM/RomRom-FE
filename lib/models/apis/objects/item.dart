// lib/models/apis/objects/item.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'item.g.dart';

@JsonSerializable(explicitToJson: true)
class Item extends BaseEntity {
  final String? itemId;
  final String? itemName;
  final String? itemDescription;
  final String? itemCategory;
  final String? itemCondition;
  final List<String>? tradeOptions;
  final int? price;

  Item({
    super.createdDate,
    super.updatedDate,
    this.itemId,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.tradeOptions,
    this.price,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}