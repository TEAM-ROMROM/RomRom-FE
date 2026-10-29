import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/home_feed_item.dart';

/// 피드 변환 검증: 주소 병렬 변환 후에도 결과 순서·id가 입력 순서대로 유지
void main() {
  test('fromItems > 결과 순서·id 입력 순서 유지, 좌표 없음·변환 실패 > 미지정', () async {
    final items = [
      Item(itemId: 'item-a', itemName: '첫째'),
      // 테스트 환경: dotenv 미로드 > 주소 조회 실패 > '미지정'
      Item(itemId: 'item-b', itemName: '둘째', latitude: 37.5665, longitude: 126.9780),
      Item(itemId: 'item-c', itemName: '셋째'),
    ];

    final feedItems = await HomeFeedItem.fromItems(items, startIndex: 10);

    expect(feedItems.map((feedItem) => feedItem.itemUuid), ['item-a', 'item-b', 'item-c']);
    expect(feedItems.map((feedItem) => feedItem.id), [11, 12, 13]);
    expect(feedItems.map((feedItem) => feedItem.location), ['미지정', '미지정', '미지정']);
    expect(feedItems[1].latitude, 37.5665);
  });
}
