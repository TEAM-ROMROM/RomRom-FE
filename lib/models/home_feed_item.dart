import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/enums/price_tag.dart';

class HomeFeedItem {
  final int id;
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

  HomeFeedItem({
    required this.id,
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
  });
}
