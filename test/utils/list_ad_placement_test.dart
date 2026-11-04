import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/utils/list_ad_placement.dart';

/// 목록 광고 배치: 콘텐츠 index <-> 광고 포함 목록 index
void main() {
  /// 배치대로 목록을 펼친 결과 (광고 'ad', 콘텐츠는 index 문자열)
  List<String> expandList(ListAdPlacement placement, int contentCount) => [
    for (var listIndex = 0; listIndex < placement.listItemCount(contentCount); listIndex++)
      placement.isAdAtListIndex(listIndex, contentCount) ? 'ad' : '${placement.contentIndexAtListIndex(listIndex)}',
  ];

  group('채팅방 목록 (3번째 방 뒤 1개)', () {
    const placement = ListAdPlacement.chatRoomList;

    test('방 3개 미만 > 광고 없음', () {
      expect(placement.adCount(2), 0);
      expect(expandList(placement, 2), ['0', '1']);
    });

    test('방 3개 이상 > 3번째 방 뒤 1개만', () {
      expect(expandList(placement, 3), ['0', '1', '2', 'ad']);
      expect(expandList(placement, 20).where((entry) => entry == 'ad').length, 1);
      expect(expandList(placement, 5), ['0', '1', '2', 'ad', '3', '4']);
    });
  });

  group('물품 목록 (8개마다 1개)', () {
    const placement = ListAdPlacement.itemList;

    test('8개 미만 > 광고 없음', () {
      expect(placement.listItemCount(7), 7);
    });

    test('8번째·16번째 뒤 광고, 콘텐츠 순서·누락 없음', () {
      final expanded = expandList(placement, 17);
      expect(expanded.length, 19);
      expect(expanded[8], 'ad');
      expect(expanded[17], 'ad');
      final contentIndices = expanded.where((entry) => entry != 'ad').map(int.parse).toList();
      expect(contentIndices, List.generate(17, (index) => index));
    });

    test('콘텐츠 index > 목록 index 왕복 일치', () {
      for (var contentIndex = 0; contentIndex < 40; contentIndex++) {
        final listIndex = placement.listIndexAtContentIndex(contentIndex);
        expect(placement.isAdAtListIndex(listIndex, 40), isFalse);
        expect(placement.contentIndexAtListIndex(listIndex), contentIndex);
      }
    });

    test('목록 범위 밖 index는 광고 아님', () {
      expect(placement.isAdAtListIndex(17, 10), isFalse);
      expect(placement.isAdAtListIndex(-1, 10), isFalse);
    });
  });
}
