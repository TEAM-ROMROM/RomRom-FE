// lib/models/apis/responses/trade_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
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

  /// 탈퇴 전 안내용 진행 중 거래 (대기·채팅 중·교환 완료 요청, 구버전 서버 > 빈 목록) (#1008)
  @JsonKey(fromJson: _tradeHistoryListFromJson, toJson: _tradeHistoryListToJson)
  final List<TradeRequestHistory> ongoingTradeRequestHistories;

  TradeResponse({
    this.tradeRequestHistory,
    this.tradeRequestHistoryPage,
    this.itemPage,
    this.tradeRequestHistoryExists,
    this.tradeReviewPage,
    this.ongoingTradeRequestHistories = const [],
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
  final bool? isNew;

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

  /// 읽음 여부만 바꾼 새 이력 (나머지 필드 공유)
  TradeRequestHistory copyWithIsNew(bool? isNew) => TradeRequestHistory(
    tradeRequestHistoryId: tradeRequestHistoryId,
    takeItem: takeItem,
    giveItem: giveItem,
    itemTradeOptions: itemTradeOptions,
    tradeStatus: tradeStatus,
    isNew: isNew,
    createdDate: createdDate,
    updatedDate: updatedDate,
  );
}

/// 요청 카드 표시값: 물품 정보가 아니라 요청 자체의 시각·거래 방식·요청자
extension TradeRequestHistoryDisplayX on TradeRequestHistory {
  /// 요청 생성 시각 (없으면 null, 물품 등록일로 대체하지 않음)
  DateTime? get requestedDate => createdDate;

  /// 요청 시 고른 거래 방식 (모르는 서버 값 제외)
  List<ItemTradeOption> get requestedTradeOptions => ItemTradeOption.fromServerNamesSkippingUnknown(itemTradeOptions);

  /// 요청 보낸 회원 (요청 보낸 물품 giveItem의 회원, 응답에 없으면 null)
  Member? get requester => giveItem.member;
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
