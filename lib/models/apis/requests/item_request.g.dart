// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemRequest _$ItemRequestFromJson(Map<String, dynamic> json) => ItemRequest(
  memberId: json['memberId'] as String?,
  itemName: json['itemName'] as String?,
  itemDescription: json['itemDescription'] as String?,
  itemCategory: json['itemCategory'] as String?,
  itemCondition: json['itemCondition'] as String?,
  itemTradeOptions: (json['itemTradeOptions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  itemPrice: (json['itemPrice'] as num?)?.toInt(),
  itemCustomTags: (json['itemCustomTags'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  itemId: json['itemId'] as String?,
  pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
  pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
  longitude: (json['longitude'] as num?)?.toDouble(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  isAiPredictedPrice: json['isAiPredictedPrice'] as bool?,
  itemStatus: json['itemStatus'] as String?,
);

Map<String, dynamic> _$ItemRequestToJson(ItemRequest instance) =>
    <String, dynamic>{
      'memberId': instance.memberId,
      'itemName': instance.itemName,
      'itemDescription': instance.itemDescription,
      'itemCategory': instance.itemCategory,
      'itemCondition': instance.itemCondition,
      'itemTradeOptions': instance.itemTradeOptions,
      'itemPrice': instance.itemPrice,
      'itemCustomTags': instance.itemCustomTags,
      'itemId': instance.itemId,
      'pageNumber': instance.pageNumber,
      'pageSize': instance.pageSize,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'isAiPredictedPrice': instance.isAiPredictedPrice,
      'itemStatus': instance.itemStatus,
    };
