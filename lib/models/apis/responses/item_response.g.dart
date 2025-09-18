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
      content: (json['content'] as List<dynamic>)
          .map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: Page.fromJson(json['page'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemPageToJson(ItemPage instance) => <String, dynamic>{
      'content': instance.content,
      'page': instance.page,
    };

Page _$PageFromJson(Map<String, dynamic> json) => Page(
      size: (json['size'] as num).toInt(),
      number: (json['number'] as num).toInt(),
      totalElements: (json['totalElements'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
    );

Map<String, dynamic> _$PageToJson(Page instance) => <String, dynamic>{
      'size': instance.size,
      'number': instance.number,
      'totalElements': instance.totalElements,
      'totalPages': instance.totalPages,
    };
