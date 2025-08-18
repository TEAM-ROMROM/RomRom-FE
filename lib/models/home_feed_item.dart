import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/price_tag.dart';

class HomeFeedItem {
  final int id;
  final String? itemUuid; // 서버 UUID
  final int price;
  final String location;
  final String date;
  final ItemCondition itemCondition;
  final List<ItemTradeOption> transactionTypes;
  final PriceTag? priceTag;
  final String profileImageUrl;
  final int likeCount;
  final List<String> imageUrls;
  final String description;
  final bool hasAiAnalysis;
  final bool aiPrice; // AI 가격 여부
  final double? latitude; // 위도
  final double? longitude; // 경도
  final bool isLiked; // 좋아요 상태

  HomeFeedItem({
    required this.id,
    this.itemUuid,
    required this.price,
    required this.location,
    required this.date,
    required this.itemCondition,
    required this.transactionTypes,
    this.priceTag,
    required this.profileImageUrl,
    required this.likeCount,
    required this.imageUrls,
    required this.description,
    this.hasAiAnalysis = false,
    this.aiPrice = false,
    this.latitude,
    this.longitude,
    this.isLiked = false,
  });
}
