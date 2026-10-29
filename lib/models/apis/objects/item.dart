// lib/models/apis/objects/item.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';

part 'item.g.dart';

@JsonSerializable(explicitToJson: true)
class Item extends BaseEntity {
  final String? itemId;
  final Member? member;
  final List<ItemImage>? itemImages;
  final String? itemName;
  final String? itemDescription;
  final String? itemCategory;
  final String? itemCondition;
  final String? itemStatus;
  final List<String>? itemTradeOptions;
  final int? likeCount;
  final int? price;
  final double? longitude;
  final double? latitude;
  final bool? isAiPredictedPrice;

  @JsonKey(includeFromJson: true)
  String? address;

  Item({
    super.createdDate,
    super.updatedDate,
    this.itemId,
    this.member,
    this.itemImages,
    this.itemName,
    this.itemDescription,
    this.itemCategory,
    this.itemCondition,
    this.itemStatus,
    this.itemTradeOptions,
    this.likeCount,
    this.price,
    this.longitude,
    this.latitude,
    this.isAiPredictedPrice,
    this.address, // 선택적 주입 가능
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

extension ItemImageX on Item {
  List<String> get imageUrlList => itemImages?.map((e) => e.imageUrl).whereType<String>().toList() ?? const [];
  String? get primaryImageUrl => imageUrlList.isNotEmpty ? imageUrlList.first : null;
}

/// 표시 주소 (address 미채움 > '미지정', 채움은 ItemAddressResolver)
extension ItemLocationX on Item {
  String get displayLocation => address ?? '미지정';
}
