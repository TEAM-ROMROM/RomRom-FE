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
      itemName: json['itemName'] as String?,
      itemDescription: json['itemDescription'] as String?,
      itemCategory: json['itemCategory'] as String?,
      itemCondition: json['itemCondition'] as String?,
      tradeOptions: (json['tradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      price: (json['price'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
      'createdDate': instance.createdDate?.toIso8601String(),
      'updatedDate': instance.updatedDate?.toIso8601String(),
      'itemId': instance.itemId,
      'itemName': instance.itemName,
      'itemDescription': instance.itemDescription,
      'itemCategory': instance.itemCategory,
      'itemCondition': instance.itemCondition,
      'tradeOptions': instance.tradeOptions,
      'price': instance.price,
    };
