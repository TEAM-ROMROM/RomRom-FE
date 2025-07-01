// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemResponse _$ItemResponseFromJson(Map<String, dynamic> json) => ItemResponse(
      item: json['item'] == null
          ? null
          : Item.fromJson(json['item'] as Map<String, dynamic>),
      itemImages: (json['itemImages'] as List<dynamic>?)
          ?.map((e) => ItemImage.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemCustomTags: (json['itemCustomTags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      likeStatus: json['likeStatus'] as String?,
      likeCount: (json['likeCount'] as num?)?.toInt(),
      itemDetailPage: json['itemDetailPage'] == null
          ? null
          : PageItemDetail.fromJson(
              json['itemDetailPage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ItemResponseToJson(ItemResponse instance) =>
    <String, dynamic>{
      'item': instance.item,
      'itemImages': instance.itemImages,
      'itemCustomTags': instance.itemCustomTags,
      'likeStatus': instance.likeStatus,
      'likeCount': instance.likeCount,
      'itemDetailPage': instance.itemDetailPage,
    };

PageItemDetail _$PageItemDetailFromJson(Map<String, dynamic> json) =>
    PageItemDetail(
      content: (json['content'] as List<dynamic>?)
          ?.map((e) => ItemDetail.fromJson(e as Map<String, dynamic>))
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

Map<String, dynamic> _$PageItemDetailToJson(PageItemDetail instance) =>
    <String, dynamic>{
      'content': instance.content,
      'totalPages': instance.totalPages,
      'totalElements': instance.totalElements,
      'last': instance.last,
      'size': instance.size,
      'number': instance.number,
      'numberOfElements': instance.numberOfElements,
      'first': instance.first,
      'empty': instance.empty,
    };
