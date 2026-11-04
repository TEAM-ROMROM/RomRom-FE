// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeResponse _$TradeResponseFromJson(Map<String, dynamic> json) => TradeResponse(
  tradeRequestHistory: json['tradeRequestHistory'] == null
      ? null
      : TradeRequestHistory.fromJson(json['tradeRequestHistory'] as Map<String, dynamic>),
  tradeRequestHistoryPage: json['tradeRequestHistoryPage'] == null
      ? null
      : PagedTradeRequestHistory.fromJson(json['tradeRequestHistoryPage'] as Map<String, dynamic>),
  itemPage: json['itemPage'] == null ? null : PagedItem.fromJson(json['itemPage'] as Map<String, dynamic>),
  tradeRequestHistoryExists: json['tradeRequestHistoryExists'] as bool?,
  tradeReviewPage: json['tradeReviewPage'] == null
      ? null
      : PagedTradeReview.fromJson(json['tradeReviewPage'] as Map<String, dynamic>),
  tradeReviewStats: json['tradeReviewStats'] == null
      ? null
      : TradeReviewStats.fromJson(json['tradeReviewStats'] as Map<String, dynamic>),
  ongoingTradeRequestHistories: json['ongoingTradeRequestHistories'] == null
      ? const []
      : _tradeHistoryListFromJson(json['ongoingTradeRequestHistories']),
);

Map<String, dynamic> _$TradeResponseToJson(TradeResponse instance) => <String, dynamic>{
  'tradeRequestHistory': instance.tradeRequestHistory?.toJson(),
  'tradeRequestHistoryPage': instance.tradeRequestHistoryPage?.toJson(),
  'itemPage': instance.itemPage?.toJson(),
  'tradeRequestHistoryExists': instance.tradeRequestHistoryExists,
  'tradeReviewPage': instance.tradeReviewPage?.toJson(),
  'tradeReviewStats': instance.tradeReviewStats?.toJson(),
  'ongoingTradeRequestHistories': _tradeHistoryListToJson(instance.ongoingTradeRequestHistories),
};

TradeRequestHistory _$TradeRequestHistoryFromJson(Map<String, dynamic> json) => TradeRequestHistory(
  tradeRequestHistoryId: json['tradeRequestHistoryId'] as String?,
  takeItem: _itemFromJson(json['takeItem']),
  giveItem: _itemFromJson(json['giveItem']),
  itemTradeOptions: _stringListFromJson(json['itemTradeOptions']),
  tradeStatus: json['tradeStatus'] as String?,
  isNew: json['isNew'] as bool?,
  chatRoomId: json['chatRoomId'] as String?,
  extraChargeAmount: (json['extraChargeAmount'] as num?)?.toInt(),
  requestMessage: json['requestMessage'] as String?,
  checkedAt: json['checkedAt'] == null ? null : DateTime.parse(json['checkedAt'] as String),
  rejectedAt: json['rejectedAt'] == null ? null : DateTime.parse(json['rejectedAt'] as String),
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
);

Map<String, dynamic> _$TradeRequestHistoryToJson(TradeRequestHistory instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'tradeRequestHistoryId': instance.tradeRequestHistoryId,
  'takeItem': _itemToJson(instance.takeItem),
  'giveItem': _itemToJson(instance.giveItem),
  'itemTradeOptions': _stringListToJson(instance.itemTradeOptions),
  'tradeStatus': instance.tradeStatus,
  'isNew': instance.isNew,
  'chatRoomId': instance.chatRoomId,
  'extraChargeAmount': instance.extraChargeAmount,
  'requestMessage': instance.requestMessage,
  'checkedAt': instance.checkedAt?.toIso8601String(),
  'rejectedAt': instance.rejectedAt?.toIso8601String(),
};

PagedTradeRequestHistory _$PagedTradeRequestHistoryFromJson(Map<String, dynamic> json) => PagedTradeRequestHistory(
  content: _tradeHistoryListFromJson(json['content']),
  page: json['page'] == null ? null : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PagedTradeRequestHistoryToJson(PagedTradeRequestHistory instance) => <String, dynamic>{
  'content': _tradeHistoryListToJson(instance.content),
  'page': instance.page?.toJson(),
};

PagedItem _$PagedItemFromJson(Map<String, dynamic> json) => PagedItem(
  content: _itemsFromJson(json['content']),
  page: json['page'] == null ? null : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PagedItemToJson(PagedItem instance) => <String, dynamic>{
  'content': _itemsToJson(instance.content),
  'page': instance.page?.toJson(),
};

TradeReview _$TradeReviewFromJson(Map<String, dynamic> json) => TradeReview(
  tradeReviewId: json['tradeReviewId'] as String?,
  tradeRequestHistory: json['tradeRequestHistory'] == null
      ? null
      : TradeRequestHistory.fromJson(json['tradeRequestHistory'] as Map<String, dynamic>),
  reviewerMember: json['reviewerMember'] == null
      ? null
      : Member.fromJson(json['reviewerMember'] as Map<String, dynamic>),
  reviewedMember: json['reviewedMember'] == null
      ? null
      : Member.fromJson(json['reviewedMember'] as Map<String, dynamic>),
  tradeReviewRating: json['tradeReviewRating'] as String?,
  tradeReviewTags: (json['tradeReviewTags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  reviewComment: json['reviewComment'] as String?,
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
);

Map<String, dynamic> _$TradeReviewToJson(TradeReview instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'tradeReviewId': instance.tradeReviewId,
  'tradeRequestHistory': instance.tradeRequestHistory?.toJson(),
  'reviewerMember': instance.reviewerMember?.toJson(),
  'reviewedMember': instance.reviewedMember?.toJson(),
  'tradeReviewRating': instance.tradeReviewRating,
  'tradeReviewTags': instance.tradeReviewTags,
  'reviewComment': instance.reviewComment,
};

TradeReviewStats _$TradeReviewStatsFromJson(Map<String, dynamic> json) => TradeReviewStats(
  totalReviewCount: (json['totalReviewCount'] as num?)?.toInt(),
  averageRatingScore: (json['averageRatingScore'] as num?)?.toDouble(),
  ratingCounts: (json['ratingCounts'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())),
  tagCounts: (json['tagCounts'] as Map<String, dynamic>?)?.map((k, e) => MapEntry(k, (e as num).toInt())),
);

Map<String, dynamic> _$TradeReviewStatsToJson(TradeReviewStats instance) => <String, dynamic>{
  'totalReviewCount': instance.totalReviewCount,
  'averageRatingScore': instance.averageRatingScore,
  'ratingCounts': instance.ratingCounts,
  'tagCounts': instance.tagCounts,
};

PagedTradeReview _$PagedTradeReviewFromJson(Map<String, dynamic> json) => PagedTradeReview(
  content: _tradeReviewListFromJson(json['content']),
  totalPages: (json['totalPages'] as num?)?.toInt(),
  totalElements: (json['totalElements'] as num?)?.toInt(),
  size: (json['size'] as num?)?.toInt(),
  number: (json['number'] as num?)?.toInt(),
  last: json['last'] as bool?,
  first: json['first'] as bool?,
  empty: json['empty'] as bool?,
  numberOfElements: (json['numberOfElements'] as num?)?.toInt(),
);

Map<String, dynamic> _$PagedTradeReviewToJson(PagedTradeReview instance) => <String, dynamic>{
  'content': _tradeReviewListToJson(instance.content),
  'totalPages': instance.totalPages,
  'totalElements': instance.totalElements,
  'size': instance.size,
  'number': instance.number,
  'last': instance.last,
  'first': instance.first,
  'empty': instance.empty,
  'numberOfElements': instance.numberOfElements,
};
