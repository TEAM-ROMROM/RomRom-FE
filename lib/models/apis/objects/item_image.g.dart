// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemImage _$ItemImageFromJson(Map<String, dynamic> json) => ItemImage(
  createdDate: json['createdDate'] == null
      ? null
      : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null
      ? null
      : DateTime.parse(json['updatedDate'] as String),
  itemImageId: json['itemImageId'] as String?,
  filePath: json['filePath'] as String?,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$ItemImageToJson(ItemImage instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'itemImageId': instance.itemImageId,
  'filePath': instance.filePath,
  'imageUrl': instance.imageUrl,
};
