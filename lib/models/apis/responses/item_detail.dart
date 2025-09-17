import 'package:json_annotation/json_annotation.dart';

part 'item_detail.g.dart';

@JsonSerializable()
class ItemDetail {
  final String? itemId;
  final String? memberId;
  final String? profileUrl;
  final String? itemName;
  final String? itemDescription;
  final String? itemCategory;
  final String? itemCondition;
  final List<String>? itemTradeOptions;
  final int? likeCount;
  final int? price;
  final String? createdDate;
  final List<String>? itemImageUrls;
  final List<String>? itemCustomTags;
  final double? longitude;
  final double? latitude;
  final bool? aiPrice;

  ItemDetail({
    this.itemId,
    this.memberId,
    this.profileUrl,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemTradeOptions,
    this.likeCount,
    this.price,
    this.createdDate,
    this.itemImageUrls,
    this.itemCustomTags,
    this.longitude,
    this.latitude,
    this.aiPrice,
  });

  factory ItemDetail.fromJson(Map<String, dynamic> json) =>
      _$ItemDetailFromJson(json);

  Map<String, dynamic> toJson() => _$ItemDetailToJson(this);
}
