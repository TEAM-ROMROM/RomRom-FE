import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

part 'item_request.g.dart';

@JsonSerializable()
class ItemRequest {
  String? memberId;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<File>? itemImages;
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

  ItemRequest({
    this.memberId,
    this.itemImages,
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
  });

  factory ItemRequest.fromJson(Map<String, dynamic> json) => _$ItemRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ItemRequestToJson(this);
} 