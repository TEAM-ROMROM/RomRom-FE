// lib/models/apis/responses/trade_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

part 'trade_response.g.dart';

@JsonSerializable(explicitToJson: true)
class TradeResponse {
  final TradeRequestHistory? tradeRequestHistory;
  final PagedTradeRequestHistory? tradeRequestHistoryPage;
  final PagedItem? itemPage;

  TradeResponse({
    this.tradeRequestHistory,
    this.tradeRequestHistoryPage,
    this.itemPage,
  });

  factory TradeResponse.fromJson(Map<String, dynamic> json) =>
      _$TradeResponseFromJson(json);
  Map<String, dynamic> toJson() => _$TradeResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TradeRequestHistory extends BaseEntity {
  final String? tradeRequestHistoryId;

  @JsonKey(fromJson: _itemFromJson, toJson: _itemToJson)
  final Item takeItem;

  @JsonKey(fromJson: _itemFromJson, toJson: _itemToJson)
  final Item giveItem;

  @JsonKey(fromJson: _stringListFromJson, toJson: _stringListToJson)
  final List<String> itemTradeOptions;

  final String? tradeStatus;
  bool? isNew;

  TradeRequestHistory({
    required this.tradeRequestHistoryId,
    required this.takeItem,
    required this.giveItem,
    required this.itemTradeOptions,
    required this.tradeStatus,
    this.isNew,
    super.createdDate,
    super.updatedDate,
  });

  factory TradeRequestHistory.fromJson(Map<String, dynamic> json) =>
      _$TradeRequestHistoryFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TradeRequestHistoryToJson(this);
}

/// Paged<TradeRequestHistory>
@JsonSerializable(explicitToJson: true)
class PagedTradeRequestHistory {
  @JsonKey(fromJson: _tradeHistoryListFromJson, toJson: _tradeHistoryListToJson)
  final List<TradeRequestHistory> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedTradeRequestHistory({required this.content, required this.page});

  factory PagedTradeRequestHistory.fromJson(Map<String, dynamic> json) =>
      _$PagedTradeRequestHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$PagedTradeRequestHistoryToJson(this);
}

/// Paged<Item>
@JsonSerializable(explicitToJson: true)
class PagedItem {
  @JsonKey(fromJson: _itemsFromJson, toJson: _itemsToJson)
  final List<Item> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedItem({required this.content, required this.page});

  factory PagedItem.fromJson(Map<String, dynamic> json) =>
      _$PagedItemFromJson(json);
  Map<String, dynamic> toJson() => _$PagedItemToJson(this);
}

/// ---------- converters ----------
Item _itemFromJson(Object? value) {
  if (value is Map<String, dynamic>) return Item.fromJson(value);
  // null 또는 잘못된 타입이면 빈 Item으로
  return Item();
}

Map<String, dynamic> _itemToJson(Item v) => v.toJson();

List<String> _stringListFromJson(Object? value) {
  if (value is List) {
    return value.whereType<String>().toList();
  }
  return const <String>[];
}

Object _stringListToJson(List<String> list) => list;

List<TradeRequestHistory> _tradeHistoryListFromJson(Object? value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>() // null 제거
        .map(TradeRequestHistory.fromJson)
        .toList();
  }
  return const <TradeRequestHistory>[];
}

Object _tradeHistoryListToJson(List<TradeRequestHistory> list) =>
    list.map((e) => e.toJson()).toList();

List<Item> _itemsFromJson(Object? value) {
  if (value is List) {
    return value
        .whereType<Map<String, dynamic>>() // null 제거
        .map(Item.fromJson)
        .toList();
  }
  return const <Item>[];
}

Object _itemsToJson(List<Item> list) => list.map((e) => e.toJson()).toList();

/// --------------------------------
