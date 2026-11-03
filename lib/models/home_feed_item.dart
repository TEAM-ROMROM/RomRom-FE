import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

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
  final String? accountStatus; // 작성자 계정 상태
  final Item? sourceItem; // 목록 응답 원본 (상세 화면이 응답 전 먼저 그림)

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
    required this.accountStatus,
    this.hasAiAnalysis = false,
    this.aiPrice = false,
    this.latitude,
    this.longitude,
    this.isLiked = false,
    this.authorMemberId,
    this.sourceItem,
  });

  /// 상세 화면 첫 표시용 목록 원본 (같은 물품일 때만, 상세 응답 오면 교체)
  Item? previewItemFor(String itemId) {
    final previewItem = sourceItem;
    if (itemId.isEmpty || previewItem == null || previewItem.itemId != itemId) return null;
    return previewItem;
  }

  /// API 응답(Item) > HomeFeedItem 리스트 ([locationTexts]: 같은 순서의 표시 주소, ItemAddressResolver가 생성)
  /// [startIndex]는 id 생성 기점 (기존 코드와 호환).
  static List<HomeFeedItem> fromItems(List<Item> details, {int startIndex = 0, required List<String> locationTexts}) {
    assert(details.length == locationTexts.length, 'locationTexts must match details order and length');
    final feedItems = <HomeFeedItem>[];

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      // 모르는·없는 물품 상태 > 미개봉
      final cond = ItemCondition.fromServerName(d.itemCondition) ?? ItemCondition.sealed;
      final opts = ItemTradeOption.fromServerNamesSkippingUnknown(d.itemTradeOptions);

      feedItems.add(
        HomeFeedItem(
          id: index + startIndex + 1,
          itemUuid: d.itemId,
          name: d.itemName ?? ' ',
          price: d.price ?? 0,
          location: locationTexts[index],
          date: d.createdDate is DateTime ? d.createdDate as DateTime : DateTime.now(),
          itemCondition: cond,
          transactionTypes: opts,
          accountStatus: d.member?.accountStatus,
          profileUrl: d.member?.profileUrl ?? '',
          likeCount: d.likeCount ?? 0,
          imageUrls: d.imageUrlList,
          description: d.itemDescription ?? '',
          hasAiAnalysis: false,
          aiPrice: d.isAiPredictedPrice ?? false,
          latitude: d.latitude,
          longitude: d.longitude,
          authorMemberId: d.member?.memberId,
          sourceItem: d,
        ),
      );
    }

    return feedItems;
  }
}
