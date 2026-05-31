import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_condition.dart' as item_cond;
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/services/location_service.dart';

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
  });

  /// API 응답(Item)을 HomeFeedItem 리스트로 변환.
  /// 위치 좌표를 주소 텍스트로 변환하기 위해 비동기.
  /// [startIndex]는 id 생성 기점 (기존 코드와 호환).
  static Future<List<HomeFeedItem>> fromItems(List<Item> details, {int startIndex = 0}) async {
    final feedItems = <HomeFeedItem>[];

    for (int index = 0; index < details.length; index++) {
      final d = details[index];

      ItemCondition cond = ItemCondition.sealed;
      try {
        cond = item_cond.ItemCondition.values.firstWhere((e) => e.serverName == d.itemCondition);
      } catch (_) {}

      final opts = <ItemTradeOption>[];
      if (d.itemTradeOptions != null) {
        for (final s in d.itemTradeOptions!) {
          try {
            opts.add(ItemTradeOption.values.firstWhere((e) => e.serverName == s));
          } catch (_) {}
        }
      }

      String locationText = '미지정';
      if (d.latitude != null && d.longitude != null) {
        final address = await LocationService().getAddressFromCoordinates(NLatLng(d.latitude!, d.longitude!));
        if (address != null) {
          locationText = '${address.siDo} ${address.siGunGu} ${address.eupMyoenDong}';
        }
      }

      feedItems.add(
        HomeFeedItem(
          id: index + startIndex + 1,
          itemUuid: d.itemId,
          name: d.itemName ?? ' ',
          price: d.price ?? 0,
          location: locationText,
          date: d.createdDate is DateTime ? d.createdDate as DateTime : DateTime.now(),
          itemCondition: cond,
          transactionTypes: opts,
          accountStatus: d.member?.accountStatus,
          profileUrl: d.member?.profileUrl ?? '',
          likeCount: d.likeCount ?? 0,
          imageUrls: d.imageUrlList,
          description: d.itemDescription ?? '',
          hasAiAnalysis: false,
          latitude: d.latitude,
          longitude: d.longitude,
          authorMemberId: d.member?.memberId,
        ),
      );
    }

    return feedItems;
  }
}
