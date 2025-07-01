// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemDetail _$ItemDetailFromJson(Map<String, dynamic> json) => ItemDetail(
      itemId: json['itemId'] as String?,
      memberId: json['memberId'] as String?,
      itemName: json['itemName'] as String?,
      itemDescription: json['itemDescription'] as String?,
      itemCategory: json['itemCategory'] as String?,
      itemCondition: json['itemCondition'] as String?,
      itemTradeOptions: (json['itemTradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likeCount: (json['likeCount'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      createdDate: json['createdDate'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      itemCustomTags: (json['itemCustomTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ItemDetailToJson(ItemDetail instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'memberId': instance.memberId,
      'itemName': instance.itemName,
      'itemDescription': instance.itemDescription,
      'itemCategory': instance.itemCategory,
      'itemCondition': instance.itemCondition,
      'itemTradeOptions': instance.itemTradeOptions,
      'likeCount': instance.likeCount,
      'price': instance.price,
      'createdDate': instance.createdDate,
      'imageUrls': instance.imageUrls,
      'itemCustomTags': instance.itemCustomTags,
    };
