import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/item_condition.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/home_feed_item.dart';

/// 피드 변환 검증: 결과 순서·id 입력 순서 유지, 주소는 전달받은 표시 문자열 그대로, AI 가격 여부, 좋아요 여부, 상세 첫 표시용 원본
void main() {
  test('fromItems > 결과 순서·id 입력 순서 유지, location = 같은 순서의 주소 문자열', () {
    final items = [
      Item(itemId: 'item-a', itemName: '첫째'),
      Item(itemId: 'item-b', itemName: '둘째', latitude: 37.5665, longitude: 126.9780),
      Item(itemId: 'item-c', itemName: '셋째'),
    ];

    final feedItems = HomeFeedItem.fromItems(
      items,
      startIndex: 10,
      locationTexts: const ['미지정', '서울특별시 중구 태평로1가', '미지정'],
    );

    expect(feedItems.map((feedItem) => feedItem.itemUuid), ['item-a', 'item-b', 'item-c']);
    expect(feedItems.map((feedItem) => feedItem.id), [11, 12, 13]);
    expect(feedItems.map((feedItem) => feedItem.location), ['미지정', '서울특별시 중구 태평로1가', '미지정']);
    expect(feedItems[1].latitude, 37.5665);
  });

  test('fromItems > 모르는·없는 물품 상태는 미개봉, 모르는 거래 방식은 제외', () {
    final items = [
      Item(itemId: 'a', itemCondition: 'NEW_CONDITION', itemTradeOptions: ['NEW_OPTION', 'DIRECT_ONLY']),
      Item(itemId: 'b'),
      Item(itemId: 'c', itemCondition: 'HEAVILY_USED'),
    ];

    final feedItems = HomeFeedItem.fromItems(items, locationTexts: const ['', '', '']);

    expect(feedItems[0].itemCondition, ItemCondition.sealed);
    expect(feedItems[0].transactionTypes, [ItemTradeOption.directTradeOnly]);
    expect(feedItems[1].itemCondition, ItemCondition.sealed);
    expect(feedItems[1].transactionTypes, isEmpty);
    expect(feedItems[2].itemCondition, ItemCondition.heavilyUsed);
  });

  test('fromItems > AI 가격 여부는 목록 응답 값 (없으면 false), 상세 첫 표시용 원본 보관', () {
    final items = [
      Item(itemId: 'a', isAiPredictedPrice: true),
      Item(itemId: 'b', isAiPredictedPrice: false),
      Item(itemId: 'c'),
    ];

    final feedItems = HomeFeedItem.fromItems(items, locationTexts: const ['', '', '']);

    expect(feedItems.map((feedItem) => feedItem.aiPrice), [true, false, false]);
    expect(identical(feedItems[0].sourceItem, items[0]), true);
  });

  test('fromItems > 목록 응답 좋아요 여부 반영, 없으면(구버전 서버) false + 서버 값 없음 표시', () {
    final items = [Item(itemId: 'a', isLiked: true), Item(itemId: 'b', isLiked: false), Item(itemId: 'c')];

    final feedItems = HomeFeedItem.fromItems(items, locationTexts: const ['', '', '']);

    expect(feedItems.map((feedItem) => feedItem.isLiked), [true, false, false]);
    expect(feedItems.map((feedItem) => feedItem.hasServerLikeStatus), [true, true, false]);
  });

  test('previewItemFor > 같은 물품이면 목록 원본, 다른 물품·빈 id면 null (상세 첫 표시용)', () {
    final feedItem = HomeFeedItem.fromItems(
      [Item(itemId: 'a', itemName: '물품')],
      locationTexts: const [''],
    ).single;

    expect(feedItem.previewItemFor('a')?.itemName, '물품');
    expect(feedItem.previewItemFor('b'), isNull);
    expect(feedItem.previewItemFor(''), isNull);
  });
}
