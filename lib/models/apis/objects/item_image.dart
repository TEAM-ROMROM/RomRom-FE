// lib/models/apis/objects/item_image.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'item_image.g.dart';

@JsonSerializable(explicitToJson: true)
class ItemImage extends BaseEntity {
  final String? itemImageId;
  final String? item;
  final String? imageUrl;
  final String? filePath;
  final String? originalFileName;
  final String? uploadedFileName;
  final int? fileSize;

  ItemImage({
    super.createdDate,
    super.updatedDate,
    this.itemImageId,
    this.item,
    this.imageUrl,
    this.filePath,
    this.originalFileName,
    this.uploadedFileName,
    this.fileSize,
  });

  factory ItemImage.fromJson(Map<String, dynamic> json) => _$ItemImageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ItemImageToJson(this);
}