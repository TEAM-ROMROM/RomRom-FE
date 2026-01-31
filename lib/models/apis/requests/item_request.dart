import 'package:json_annotation/json_annotation.dart';

part 'item_request.g.dart';

@JsonSerializable()
class ItemRequest {
  String? memberId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<String>? itemImageUrls;
  String? itemName;
  String? itemDescription;
  String? itemCategory;
  String? itemCondition;
  List<String>? itemTradeOptions;
  int? itemPrice;
  List<String>? itemCustomTags;
  String? itemId;
  int pageNumber;
  int pageSize;
  double? longitude;
  double? latitude;
  bool? isAiPredictedPrice;
  String? itemStatus;
  double? radiusInMeters;
  int? minPrice;
  int? maxPrice;
  String? startDate;
  String? endDate;
  String? sortField;
  String? sortDirection;
  String? searchKeyword;

  ItemRequest({
    this.memberId,
    this.itemImageUrls,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemTradeOptions,
    this.itemPrice,
    this.itemCustomTags,
    this.itemId,
    this.pageNumber = 0,
    this.pageSize = 10,
    this.longitude,
    this.latitude,
    this.isAiPredictedPrice,
    this.itemStatus,
    this.radiusInMeters,
    this.minPrice,
    this.maxPrice,
    this.startDate,
    this.endDate,
    this.sortField,
    this.sortDirection,
    this.searchKeyword,
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) => _$ItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ItemRequestToJson(this);
}
