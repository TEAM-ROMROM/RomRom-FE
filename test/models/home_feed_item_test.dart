import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/home_feed_item.dart';

/// 피드 변환 검증: 결과 순서·id 입력 순서 유지, 주소는 전달받은 표시 문자열 그대로
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
}
