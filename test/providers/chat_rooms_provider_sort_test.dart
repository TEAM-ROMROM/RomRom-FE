import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';

ChatRoomDetailDto room(String id, DateTime t) => ChatRoomDetailDto(chatRoomId: id, lastMessageTime: t);

void main() {
  group('WS 수신 후 정렬 시나리오', () {
    test('오래된 방의 lastMessageTime을 최신으로 갱신하면 맨 위로 올라온다', () {
      // 초기: b(최신) > c > a(가장 오래됨)
      final state = ChatRoomsState(
        rooms: [room('a', DateTime(2026, 1, 1)), room('b', DateTime(2026, 3, 1)), room('c', DateTime(2026, 2, 1))],
      );
      expect(state.rooms.map((r) => r.chatRoomId).toList(), ['b', 'c', 'a']);

      // onMessageReceived와 동일하게 a 방의 시각만 갱신 (맨앞 이동 안 함)
      final idx = state.rooms.indexWhere((r) => r.chatRoomId == 'a');
      final newRooms = [...state.rooms];
      newRooms[idx] = state.rooms[idx].copyWith(lastMessageTime: DateTime(2026, 4, 1));
      final next = state.copyWith(rooms: newRooms);

      // State 자동 정렬로 a가 최상단
      expect(next.rooms.map((r) => r.chatRoomId).toList(), ['a', 'b', 'c']);
    });
  });
}
