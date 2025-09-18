// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeResponse _$TradeResponseFromJson(Map<String, dynamic> json) =>
    TradeResponse(
      item: json['item'] == null
          ? null
          : Item.fromJson(json['item'] as Map<String, dynamic>),
      itemImages: (json['itemImages'] as List<dynamic>?)
          ?.map((e) => ItemImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      tradeOptions: (json['tradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      tradeResponsePage: json['tradeResponsePage'] == null
          ? null
          : PageTradeResponse.fromJson(
              json['tradeResponsePage'] as Map<String, dynamic>),
      itemDetailPage: json['itemDetailPage'] == null
          ? null
          : TradeItemDetailPage.fromJson(
              json['itemDetailPage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$TradeResponseToJson(TradeResponse instance) =>
    <String, dynamic>{
      'item': instance.item?.toJson(),
      'itemImages': instance.itemImages?.map((e) => e.toJson()).toList(),
      'tradeOptions': instance.tradeOptions,
      'tradeResponsePage': instance.tradeResponsePage?.toJson(),
      'itemDetailPage': instance.itemDetailPage?.toJson(),
    };

PageTradeResponse _$PageTradeResponseFromJson(Map<String, dynamic> json) =>
    PageTradeResponse(
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => TradeResponseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      totalElements: (json['totalElements'] as num?)?.toInt(),
      last: json['last'] as bool?,
      size: (json['size'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      numberOfElements: (json['numberOfElements'] as num?)?.toInt(),
      first: json['first'] as bool?,
      empty: json['empty'] as bool?,
    );

Map<String, dynamic> _$PageTradeResponseToJson(PageTradeResponse instance) =>
    <String, dynamic>{
      'content': instance.content?.map((e) => e.toJson()).toList(),
      'totalPages': instance.totalPages,
      'totalElements': instance.totalElements,
      'last': instance.last,
      'size': instance.size,
      'number': instance.number,
      'numberOfElements': instance.numberOfElements,
      'first': instance.first,
      'empty': instance.empty,
    };

TradeResponseItem _$TradeResponseItemFromJson(Map<String, dynamic> json) =>
    TradeResponseItem(
      item: json['item'] == null
          ? null
          : Item.fromJson(json['item'] as Map<String, dynamic>),
      itemImages: (json['itemImages'] as List<dynamic>?)
          ?.map((e) => ItemImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      tradeOptions: (json['tradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TradeResponseItemToJson(TradeResponseItem instance) =>
    <String, dynamic>{
      'item': instance.item?.toJson(),
      'itemImages': instance.itemImages?.map((e) => e.toJson()).toList(),
      'tradeOptions': instance.tradeOptions,
    };

TradeItemDetailPage _$TradeItemDetailPageFromJson(Map<String, dynamic> json) =>
    TradeItemDetailPage(
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      totalElements: (json['totalElements'] as num?)?.toInt(),
      last: json['last'] as bool?,
      size: (json['size'] as num?)?.toInt(),
      number: (json['number'] as num?)?.toInt(),
      numberOfElements: (json['numberOfElements'] as num?)?.toInt(),
      first: json['first'] as bool?,
      empty: json['empty'] as bool?,
    );

Map<String, dynamic> _$TradeItemDetailPageToJson(
        TradeItemDetailPage instance) =>
    <String, dynamic>{
      'content': instance.content?.map((e) => e.toJson()).toList(),
      'totalPages': instance.totalPages,
      'totalElements': instance.totalElements,
      'last': instance.last,
      'size': instance.size,
      'number': instance.number,
      'numberOfElements': instance.numberOfElements,
      'first': instance.first,
      'empty': instance.empty,
    };
