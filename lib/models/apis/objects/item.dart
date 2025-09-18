// lib/models/apis/objects/item.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';

part 'item.g.dart';

/// 백엔드 응답 키와 1:1 매칭된 Item 모델

@JsonSerializable(
  explicitToJson: true,
)
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

  /// 경도/위도 (백엔드가 int/float 혼용해도 json_serializable이 num->double로 안전 캐스팅)
  final double? longitude;
  final double? latitude;

  final bool? aiPrice;

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
    this.aiPrice,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ItemToJson(this);
}

extension ItemImageX on Item {
  List<String> get imageUrlList =>
      itemImages?.map((e) => e.imageUrl).whereType<String>().toList() ??
      const [];

  String? get primaryImageUrl {
    final urls = itemImages?.map((e) => e.imageUrl).whereType<String>();
    return (urls != null && urls.isNotEmpty) ? urls.first : null;
  }
}
