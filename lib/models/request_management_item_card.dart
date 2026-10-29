import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';

/// 요청 관리 페이지의 물품 카드에 필요한 정보를 담는 데이터 모델
class RequestManagementItemCard {
  /// 물품 ID
  final String itemId;

  /// 물품 이미지 URL
  final String imageUrl;

  /// 물품 카테고리 (스포츠/레저 등)
  final String category;

  /// 물품 제목
  final String title;

  /// 물품 가격
  final int price;

  /// 좋아요 개수
  final int likeCount;

  /// AI 분석 적정가 여부
  final bool aiPrice;

  RequestManagementItemCard({
    required this.itemId,
    required this.imageUrl,
    required this.category,
    required this.title,
    required this.price,
    required this.likeCount,
    this.aiPrice = false,
  });

  /// 내 물품 > 요청관리 카드 (카테고리 표시 이름, 모르는·빈 카테고리 > '기타', 이름 없음 > titleFallback)
  factory RequestManagementItemCard.fromItem(Item item, {String titleFallback = ' '}) {
    return RequestManagementItemCard(
      itemId: item.itemId ?? '',
      imageUrl: item.primaryImageUrl ?? '',
      category: (ItemCategories.fromServerName(item.itemCategory) ?? ItemCategories.etc).label,
      title: item.itemName ?? titleFallback,
      price: item.price ?? 0,
      likeCount: item.likeCount ?? 0,
      aiPrice: item.isAiPredictedPrice ?? false,
    );
  }
}
