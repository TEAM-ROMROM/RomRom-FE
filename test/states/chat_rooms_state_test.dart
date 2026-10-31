import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';

ChatRoomDetailDto room(String id, DateTime? t) => ChatRoomDetailDto(chatRoomId: id, lastMessageTime: t);

void main() {
  group('ChatRoomsState 정렬', () {
    test('생성자는 rooms를 lastMessageTime 내림차순으로 정렬한다', () {
      final state = ChatRoomsState(
        rooms: [room('a', DateTime(2026, 1, 1)), room('b', DateTime(2026, 3, 1)), room('c', DateTime(2026, 2, 1))],
      );
      expect(state.rooms.map((r) => r.chatRoomId).toList(), ['b', 'c', 'a']);
    });

    test('lastMessageTime이 null인 방은 맨 뒤로 간다', () {
      final state = ChatRoomsState(rooms: [room('a', null), room('b', DateTime(2026, 1, 1))]);
      expect(state.rooms.map((r) => r.chatRoomId).toList(), ['b', 'a']);
    });

    test('copyWith로 rooms를 바꿔도 정렬이 유지된다', () {
      final state = ChatRoomsState(rooms: [room('a', DateTime(2026, 1, 1))]);
      final next = state.copyWith(rooms: [room('x', DateTime(2026, 1, 1)), room('y', DateTime(2026, 5, 1))]);
      expect(next.rooms.map((r) => r.chatRoomId).toList(), ['y', 'x']);
    });

    test('정렬은 원본 입력 리스트를 변형하지 않는다', () {
      final input = [room('a', DateTime(2026, 1, 1)), room('b', DateTime(2026, 5, 1))];
      ChatRoomsState(rooms: input);
      expect(input.map((r) => r.chatRoomId).toList(), ['a', 'b']);
    });
  });
}
