import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';
import 'package:romrom_fe/models/apis/responses/item_detail.dart';

part 'trade_response.g.dart';

@JsonSerializable(explicitToJson: true)
class TradeResponse {
  final Item? item;
  final List<ItemImage>? itemImages;
  final List<String>? tradeOptions;
  final PageTradeResponse? tradeResponsePage;
  final TradeItemDetailPage? itemDetailPage;

  TradeResponse({
    this.item,
    this.itemImages,
    this.tradeOptions,
    this.tradeResponsePage,
    this.itemDetailPage,
  });

  factory TradeResponse.fromJson(Map<String, dynamic> json) => _$TradeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TradeResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PageTradeResponse {
  final List<TradeResponseItem>? content;
  final int? totalPages;
  final int? totalElements;
  final bool? last;
  final int? size;
  final int? number;
  final int? numberOfElements;
  final bool? first;
  final bool? empty;

  PageTradeResponse({
    this.content,
    this.totalPages,
    this.totalElements,
    this.last,
    this.size,
    this.number,
    this.numberOfElements,
    this.first,
    this.empty,
  });

  factory PageTradeResponse.fromJson(Map<String, dynamic> json) => 
      _$PageTradeResponseFromJson(json);
  
  Map<String, dynamic> toJson() => _$PageTradeResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TradeResponseItem {
  final Item? item;
  final List<ItemImage>? itemImages;
  final List<String>? tradeOptions;

  TradeResponseItem({
    this.item,
    this.itemImages,
    this.tradeOptions,
  });

  factory TradeResponseItem.fromJson(Map<String, dynamic> json) => 
      _$TradeResponseItemFromJson(json);
  
  Map<String, dynamic> toJson() => _$TradeResponseItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TradeItemDetailPage {
  final List<ItemDetail>? content;
  final int? totalPages;
  final int? totalElements;
  final bool? last;
  final int? size;
  final int? number;
  final int? numberOfElements;
  final bool? first;
  final bool? empty;

  TradeItemDetailPage({
    this.content,
    this.totalPages,
    this.totalElements,
    this.last,
    this.size,
    this.number,
    this.numberOfElements,
    this.first,
    this.empty,
  });

  factory TradeItemDetailPage.fromJson(Map<String, dynamic> json) => 
      _$TradeItemDetailPageFromJson(json);
  
  Map<String, dynamic> toJson() => _$TradeItemDetailPageToJson(this);
}