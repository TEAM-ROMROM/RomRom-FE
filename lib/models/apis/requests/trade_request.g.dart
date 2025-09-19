// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TradeRequest _$TradeRequestFromJson(Map<String, dynamic> json) => TradeRequest(
      member: json['member'] == null
          ? null
          : Member.fromJson(json['member'] as Map<String, dynamic>),
      takeItemId: json['takeItemId'] as String?,
      giveItemId: json['giveItemId'] as String?,
      tradeRequestHistoryId: json['tradeRequestHistoryId'] as String?,
      tradeOptions: (json['tradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$TradeRequestToJson(TradeRequest instance) =>
    <String, dynamic>{
      'member': instance.member?.toJson(),
      'takeItemId': instance.takeItemId,
      'giveItemId': instance.giveItemId,
      'tradeRequestHistoryId': instance.tradeRequestHistoryId,
      'tradeOptions': instance.tradeOptions,
      'pageNumber': instance.pageNumber,
      'pageSize': instance.pageSize,
    };
