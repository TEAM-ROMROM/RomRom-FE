import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/utils/chat_room_list_rules.dart';

void main() {
  group('mergeFirstPageRooms', () {
    test('첫 페이지 방은 새 값으로 교체·추가, 첫 페이지에 없는 기존 방은 유지', () {
      final currentRooms = [ChatRoomDetailDto(chatRoomId: 'a', unreadCount: 0), ChatRoomDetailDto(chatRoomId: 'old')];
      final firstPageRooms = [ChatRoomDetailDto(chatRoomId: 'a', unreadCount: 2), ChatRoomDetailDto(chatRoomId: 'new')];

      final merged = mergeFirstPageRooms(currentRooms: currentRooms, firstPageRooms: firstPageRooms);

      expect(merged.map((room) => room.chatRoomId), unorderedEquals(['a', 'old', 'new']));
      expect(merged.firstWhere((room) => room.chatRoomId == 'a').unreadCount, 2);
    });
  });
}
