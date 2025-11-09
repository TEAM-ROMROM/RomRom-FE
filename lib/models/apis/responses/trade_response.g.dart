// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeResponse _$TradeResponseFromJson(Map<String, dynamic> json) =>
    TradeResponse(
      tradeRequestHistory: json['tradeRequestHistory'] == null
          ? null
          : TradeRequestHistory.fromJson(
              json['tradeRequestHistory'] as Map<String, dynamic>,
            ),
      tradeRequestHistoryPage: json['tradeRequestHistoryPage'] == null
          ? null
          : PagedTradeRequestHistory.fromJson(
              json['tradeRequestHistoryPage'] as Map<String, dynamic>,
            ),
      itemPage: json['itemPage'] == null
          ? null
          : PagedItem.fromJson(json['itemPage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TradeResponseToJson(TradeResponse instance) =>
    <String, dynamic>{
      'tradeRequestHistory': instance.tradeRequestHistory?.toJson(),
      'tradeRequestHistoryPage': instance.tradeRequestHistoryPage?.toJson(),
      'itemPage': instance.itemPage?.toJson(),
    };

TradeRequestHistory _$TradeRequestHistoryFromJson(Map<String, dynamic> json) =>
    TradeRequestHistory(
      tradeRequestHistoryId: json['tradeRequestHistoryId'] as String?,
      takeItem: _itemFromJson(json['takeItem']),
      giveItem: _itemFromJson(json['giveItem']),
      itemTradeOptions: _stringListFromJson(json['itemTradeOptions']),
      tradeStatus: json['tradeStatus'] as String?,
      isNew: json['isNew'] as bool?,
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.parse(json['createdDate'] as String),
      updatedDate: json['updatedDate'] == null
          ? null
          : DateTime.parse(json['updatedDate'] as String),
    );

Map<String, dynamic> _$TradeRequestHistoryToJson(
  TradeRequestHistory instance,
) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'tradeRequestHistoryId': instance.tradeRequestHistoryId,
  'takeItem': _itemToJson(instance.takeItem),
  'giveItem': _itemToJson(instance.giveItem),
  'itemTradeOptions': _stringListToJson(instance.itemTradeOptions),
  'tradeStatus': instance.tradeStatus,
  'isNew': instance.isNew,
};

PagedTradeRequestHistory _$PagedTradeRequestHistoryFromJson(
  Map<String, dynamic> json,
) => PagedTradeRequestHistory(
  content: _tradeHistoryListFromJson(json['content']),
  page: json['page'] == null
      ? null
      : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PagedTradeRequestHistoryToJson(
  PagedTradeRequestHistory instance,
) => <String, dynamic>{
  'content': _tradeHistoryListToJson(instance.content),
  'page': instance.page?.toJson(),
};

PagedItem _$PagedItemFromJson(Map<String, dynamic> json) => PagedItem(
  content: _itemsFromJson(json['content']),
  page: json['page'] == null
      ? null
      : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PagedItemToJson(PagedItem instance) => <String, dynamic>{
  'content': _itemsToJson(instance.content),
  'page': instance.page?.toJson(),
};
