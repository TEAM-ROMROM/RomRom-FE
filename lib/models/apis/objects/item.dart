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

  /// 우선노출(롬업) 종료 시각 (노출 이력 없으면 null)
  final DateTime? promotionExpiresAt;

  /// 우선노출 활성 여부 (서버 응답 시점 기준)
  final bool? isPromoted;

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
    this.promotionExpiresAt,
    this.isPromoted,
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

/// 우선노출 활성 판정: 종료 시각 있으면 현재 시각 기준 (만료 > 비활성), 없으면 서버 isPromoted
extension ItemPromotionX on Item {
  bool isPromotionActiveAt(DateTime now) {
    final expiresAt = promotionExpiresAt;
    if (expiresAt != null) return now.isBefore(expiresAt);
    return isPromoted ?? false;
  }

  /// 남은 노출 시간 (비활성·종료 시각 없음 > null)
  Duration? promotionRemainingAt(DateTime now) {
    final expiresAt = promotionExpiresAt;
    if (expiresAt == null || !isPromotionActiveAt(now)) return null;
    return expiresAt.difference(now);
  }
}

/// 표시 주소 (address 미채움 > '미지정', 채움은 ItemAddressResolver)
extension ItemLocationX on Item {
  String get displayLocation => address ?? '미지정';
}
