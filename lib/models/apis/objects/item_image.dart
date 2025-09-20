// lib/models/apis/objects/item_image.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'item_image.g.dart';

@JsonSerializable(
  explicitToJson: true,
)
class ItemImage extends BaseEntity {
  final String? itemImageId;
  final String? filePath; // null 가능 (샘플에 null)
  final String? imageUrl;

  ItemImage({
    super.createdDate,
    super.updatedDate,
    this.itemImageId,
    this.filePath,
    this.imageUrl,
  });

  factory ItemImage.fromJson(Map<String, dynamic> json) =>
      _$ItemImageFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ItemImageToJson(this);
}
