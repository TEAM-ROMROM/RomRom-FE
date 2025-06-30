// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_detail_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemDetailResponse _$ItemDetailResponseFromJson(Map<String, dynamic> json) =>
    ItemDetailResponse(
      itemId: json['itemId'] as String?,
      memberId: json['memberId'] as String?,
      itemName: json['itemName'] as String?,
      itemDescription: json['itemDescription'] as String?,
      itemCategory:
          $enumDecodeNullable(_$ItemCategoriesEnumMap, json['itemCategory']),
      itemCondition:
          $enumDecodeNullable(_$ItemConditionEnumMap, json['itemCondition']),
      itemTradeOptions: (json['itemTradeOptions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likeCount: (json['likeCount'] as num?)?.toInt(),
      price: (json['price'] as num?)?.toInt(),
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.parse(json['createdDate'] as String),
      imageUrls: (json['imageUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      itemCustomTags: (json['itemCustomTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$ItemDetailResponseToJson(ItemDetailResponse instance) =>
    <String, dynamic>{
      'itemId': instance.itemId,
      'memberId': instance.memberId,
      'itemName': instance.itemName,
      'itemDescription': instance.itemDescription,
      'itemCategory': _$ItemCategoriesEnumMap[instance.itemCategory],
      'itemCondition': _$ItemConditionEnumMap[instance.itemCondition],
      'itemTradeOptions': instance.itemTradeOptions,
      'likeCount': instance.likeCount,
      'price': instance.price,
      'createdDate': instance.createdDate?.toIso8601String(),
      'imageUrls': instance.imageUrls,
      'itemCustomTags': instance.itemCustomTags,
    };

const _$ItemCategoriesEnumMap = {
  ItemCategories.womensClothing: 'womensClothing',
  ItemCategories.mensClothing: 'mensClothing',
  ItemCategories.shoes: 'shoes',
  ItemCategories.bagsWallets: 'bagsWallets',
  ItemCategories.watches: 'watches',
  ItemCategories.jewelry: 'jewelry',
  ItemCategories.fashionAccessories: 'fashionAccessories',
  ItemCategories.electronics: 'electronics',
  ItemCategories.largeAppliances: 'largeAppliances',
  ItemCategories.smallAppliances: 'smallAppliances',
  ItemCategories.sportsLeisure: 'sportsLeisure',
  ItemCategories.vehicles: 'vehicles',
  ItemCategories.starGoods: 'starGoods',
  ItemCategories.kidult: 'kidult',
  ItemCategories.artCollection: 'artCollection',
  ItemCategories.musicInstruments: 'musicInstruments',
  ItemCategories.booksTicketsStationery: 'booksTicketsStationery',
  ItemCategories.beauty: 'beauty',
  ItemCategories.furnitureInterior: 'furnitureInterior',
  ItemCategories.homeKitchen: 'homeKitchen',
  ItemCategories.toolsIndustrial: 'toolsIndustrial',
  ItemCategories.food: 'food',
  ItemCategories.babyProducts: 'babyProducts',
  ItemCategories.petSupplies: 'petSupplies',
  ItemCategories.etc: 'etc',
  ItemCategories.talentServiceExchange: 'talentServiceExchange',
};

const _$ItemConditionEnumMap = {
  ItemCondition.newItem: 'newItem',
  ItemCondition.lightlyUsed: 'lightlyUsed',
  ItemCondition.moderatelyUsed: 'moderatelyUsed',
  ItemCondition.heavilyUsed: 'heavilyUsed',
};
