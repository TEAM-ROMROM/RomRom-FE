import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/states/item_like_state.dart';

void main() {
  group('ItemLikeState', () {
    test('copyWith는 지정한 필드만 변경한다', () {
      const s = ItemLikeState(isLiked: false, likeCount: 3);
      final next = s.copyWith(isLiked: true);
      expect(next.isLiked, isTrue);
      expect(next.likeCount, 3);
    });

    test('동일 값이면 == true', () {
      const a = ItemLikeState(isLiked: true, likeCount: 5);
      const b = ItemLikeState(isLiked: true, likeCount: 5);
      expect(a, equals(b));
    });
  });
}
