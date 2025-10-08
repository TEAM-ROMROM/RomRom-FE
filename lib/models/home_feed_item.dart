import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';

class HomeFeedItem {
  final int id;
  final String? itemUuid; // 서버 UUID
  final String name; // 물품 이름
  final int price;
  final String location;
  final DateTime date;
  final ItemCondition itemCondition;
  final List<ItemTradeOption> transactionTypes;
  final String profileUrl;
  final int likeCount;
  final List<String> imageUrls;
  final String description;
  final bool hasAiAnalysis;
  final bool aiPrice; // AI 가격 여부
  final double? latitude; // 위도
  final double? longitude; // 경도
  final bool isLiked; // 좋아요 상태
  final String? authorMemberId; // 게시글 작성자 ID

  HomeFeedItem({
    required this.id,
    this.itemUuid,
    required this.name,
    required this.price,
    required this.location,
    required this.date,
    required this.itemCondition,
    required this.transactionTypes,
    required this.profileUrl,
    required this.likeCount,
    required this.imageUrls,
    required this.description,
    this.hasAiAnalysis = false,
    this.aiPrice = false,
    this.latitude,
    this.longitude,
    this.isLiked = false,
    this.authorMemberId,
  });
}
