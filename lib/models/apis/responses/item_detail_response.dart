import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/enums/item_condition.dart';

part 'item_detail_response.g.dart';

@JsonSerializable()
class ItemDetailResponse {
  final String? itemId;
  final String? memberId;
  final String? itemName;
  final String? itemDescription;
  final ItemCategories? itemCategory;
  final ItemCondition? itemCondition;
  final List<String>? itemTradeOptions;
  final int? likeCount;
  final int? price;
  final DateTime? createdDate;
  final List<String>? imageUrls;
  final List<String>? itemCustomTags;

  ItemDetailResponse({
    this.itemId,
    this.memberId,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemTradeOptions,
    this.likeCount,
    this.price,
    this.createdDate,
    this.imageUrls,
    this.itemCustomTags,
  });

  factory ItemDetailResponse.fromJson(Map<String, dynamic> json) => 
      _$ItemDetailResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$ItemDetailResponseToJson(this);
} 