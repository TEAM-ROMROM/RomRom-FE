// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemResponse _$ItemResponseFromJson(Map<String, dynamic> json) => ItemResponse(
      item: json['item'] == null
          ? null
          : Item.fromJson(json['item'] as Map<String, dynamic>),
      itemPage: json['itemPage'] == null
          ? null
          : ItemPage.fromJson(json['itemPage'] as Map<String, dynamic>),
      isLiked: json['isLiked'] as bool?,
    );

Map<String, dynamic> _$ItemResponseToJson(ItemResponse instance) =>
    <String, dynamic>{
      'item': instance.item,
      'itemPage': instance.itemPage,
      'isLiked': instance.isLiked,
    };

ItemPage _$ItemPageFromJson(Map<String, dynamic> json) => ItemPage(
      content: _itemsFromJson(json['content']),
      page: ApiPage.fromJson(json['page'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemPageToJson(ItemPage instance) => <String, dynamic>{
      'content': _itemsToJson(instance.content),
      'page': instance.page,
    };
