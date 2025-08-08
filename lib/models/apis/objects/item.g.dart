// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.parse(json['createdDate'] as String),
      updatedDate: json['updatedDate'] == null
          ? null
          : DateTime.parse(json['updatedDate'] as String),
      itemId: json['itemId'] as String?,
      member: json['member'] == null
          ? null
          : Member.fromJson(json['member'] as Map<String, dynamic>),
      itemName: json['itemName'] as String?,
      itemDescription: json['itemDescription'] as String?,
      itemCategory: json['itemCategory'] as String?,
      itemCondition: json['itemCondition'] as String?,
      itemTradeOptions: (json['itemTradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likeCount: (json['likeCount'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      aiPrice: json['aiPrice'] as bool?,
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'createdDate': instance.createdDate?.toIso8601String(),
      'updatedDate': instance.updatedDate?.toIso8601String(),
      'itemId': instance.itemId,
      'member': instance.member?.toJson(),
      'itemName': instance.itemName,
      'itemDescription': instance.itemDescription,
      'itemCategory': instance.itemCategory,
      'itemCondition': instance.itemCondition,
      'itemTradeOptions': instance.itemTradeOptions,
      'likeCount': instance.likeCount,
      'price': instance.price,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'aiPrice': instance.aiPrice,
    };
