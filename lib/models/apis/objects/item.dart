// lib/models/apis/objects/item.dart
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';
import 'package:romrom_fe/models/apis/objects/item_image.dart';
import 'package:romrom_fe/services/location_service.dart';

part 'item.g.dart';

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
  List<String> get imageUrlList =>
      itemImages?.map((e) => e.imageUrl).whereType<String>().toList() ??
      const [];
  String? get primaryImageUrl =>
      imageUrlList.isNotEmpty ? imageUrlList.first : null;
}

extension ItemAddressResolver on Item {
  Future<String> resolveAndCacheAddress() async {
    const fallback = '미지정';
    if (latitude == null || longitude == null) {
      address = fallback;
      return address!;
    }
    try {
      final addr = await LocationService()
          .getAddressFromCoordinates(NLatLng(latitude!, longitude!));
      address = (addr == null)
          ? fallback
          : '${addr.siDo} ${addr.siGunGu} ${addr.eupMyoenDong}'.trim();
      if (address!.isEmpty) address = fallback;
      return address!;
    } catch (_) {
      address = fallback;
      return address!;
    }
  }

  String get displayLocation => address ?? '미지정';
}
