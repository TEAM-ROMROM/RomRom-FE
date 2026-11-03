import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/home_feed_removal_position.dart';

/// 피드 축소 후 보던 위치: 보던 물품 유지, 빠졌으면 다음 남은 물품
void main() {
  test('보던 물품 앞 물품이 빠지면 같은 물품을 가리키도록 index 당김', () {
    expect(
      resolveFeedIndexAfterRemoval(
        previousItems: ['a', 'b', 'c', 'd'],
        remainingItems: ['b', 'd'],
        previousFeedIndex: 3,
      ),
      1,
    );
  });

  test('보던 물품이 빠지면 그 자리의 다음 남은 물품', () {
    expect(
      resolveFeedIndexAfterRemoval(previousItems: ['a', 'b', 'c'], remainingItems: ['a', 'c'], previousFeedIndex: 1),
      1,
    );
  });

  test('뒤 물품만 빠지면 index 그대로', () {
    expect(
      resolveFeedIndexAfterRemoval(previousItems: ['a', 'b', 'c'], remainingItems: ['a', 'b'], previousFeedIndex: 1),
      1,
    );
  });

  test('범위 밖 index는 이전 목록 길이까지만 셈', () {
    expect(resolveFeedIndexAfterRemoval(previousItems: ['a', 'b'], remainingItems: ['b'], previousFeedIndex: 5), 1);
  });
}
