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
      item: json['item'] as String?,
      imageUrl: json['imageUrl'] as String?,
      filePath: json['filePath'] as String?,
      originalFileName: json['originalFileName'] as String?,
      uploadedFileName: json['uploadedFileName'] as String?,
      fileSize: (json['fileSize'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ItemImageToJson(ItemImage instance) => <String, dynamic>{
      'createdDate': instance.createdDate?.toIso8601String(),
      'updatedDate': instance.updatedDate?.toIso8601String(),
      'itemImageId': instance.itemImageId,
      'item': instance.item,
      'imageUrl': instance.imageUrl,
      'filePath': instance.filePath,
      'originalFileName': instance.originalFileName,
      'uploadedFileName': instance.uploadedFileName,
      'fileSize': instance.fileSize,
    };
