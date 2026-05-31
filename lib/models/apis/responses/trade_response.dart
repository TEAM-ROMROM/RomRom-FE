// lib/models/apis/responses/trade_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'trade_response.g.dart';

@JsonSerializable(explicitToJson: true)
class TradeResponse {
  final TradeRequestHistory? tradeRequestHistory;
  final PagedTradeRequestHistory? tradeRequestHistoryPage;
  final PagedItem? itemPage;
  final bool? tradeRequestHistoryExists; // 거래 요청 이력 존재 여부
  final PagedTradeReview? tradeReviewPage;

  TradeResponse({
    this.tradeRequestHistory,
    this.tradeRequestHistoryPage,
    this.itemPage,
    this.tradeRequestHistoryExists,
    this.tradeReviewPage,
  });

  factory TradeResponse.fromJson(Map<String, dynamic> json) => _$TradeResponseFromJson(json);
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

  factory TradeRequestHistory.fromJson(Map<String, dynamic> json) => _$TradeRequestHistoryFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TradeRequestHistoryToJson(this);
}

/// `Paged<TradeRequestHistory>`
@JsonSerializable(explicitToJson: true)
class PagedTradeRequestHistory {
  @JsonKey(fromJson: _tradeHistoryListFromJson, toJson: _tradeHistoryListToJson)
  final List<TradeRequestHistory> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedTradeRequestHistory({required this.content, required this.page});

  factory PagedTradeRequestHistory.fromJson(Map<String, dynamic> json) => _$PagedTradeRequestHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$PagedTradeRequestHistoryToJson(this);
}

/// `Paged<Item>`
@JsonSerializable(explicitToJson: true)
class PagedItem {
  @JsonKey(fromJson: _itemsFromJson, toJson: _itemsToJson)
  final List<Item> content;

  @JsonKey(name: 'page')
  final ApiPage? page;

  PagedItem({required this.content, required this.page});

  factory PagedItem.fromJson(Map<String, dynamic> json) => _$PagedItemFromJson(json);
  Map<String, dynamic> toJson() => _$PagedItemToJson(this);
}

/// Individual trade review
@JsonSerializable(explicitToJson: true)
class TradeReview extends BaseEntity {
  final String? tradeReviewId;
  final TradeRequestHistory? tradeRequestHistory;
  final Member? reviewerMember;
  final Member? reviewedMember;
  final String? tradeReviewRating;
  final List<String>? tradeReviewTags;
  final String? reviewComment;

  TradeReview({
    this.tradeReviewId,
    this.tradeRequestHistory,
    this.reviewerMember,
    this.reviewedMember,
    this.tradeReviewRating,
    this.tradeReviewTags,
    this.reviewComment,
    super.createdDate,
    super.updatedDate,
  });

  factory TradeReview.fromJson(Map<String, dynamic> json) => _$TradeReviewFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TradeReviewToJson(this);
}

/// `Paged<TradeReview>` — flat Spring Page structure
@JsonSerializable(explicitToJson: true)
class PagedTradeReview {
  @JsonKey(fromJson: _tradeReviewListFromJson, toJson: _tradeReviewListToJson)
  final List<TradeReview> content;

  final int? totalPages;
  final int? totalElements;
  final int? size;
  final int? number;
  final bool? last;
  final bool? first;
  final bool? empty;
  final int? numberOfElements;

  PagedTradeReview({
    required this.content,
    this.totalPages,
    this.totalElements,
    this.size,
    this.number,
    this.last,
    this.first,
    this.empty,
    this.numberOfElements,
  });

  factory PagedTradeReview.fromJson(Map<String, dynamic> json) => _$PagedTradeReviewFromJson(json);
  Map<String, dynamic> toJson() => _$PagedTradeReviewToJson(this);
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

Object _tradeHistoryListToJson(List<TradeRequestHistory> list) => list.map((e) => e.toJson()).toList();

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

List<TradeReview> _tradeReviewListFromJson(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().map(TradeReview.fromJson).toList();
  }
  return const <TradeReview>[];
}

Object _tradeReviewListToJson(List<TradeReview> list) => list.map((e) => e.toJson()).toList();

/// --------------------------------
