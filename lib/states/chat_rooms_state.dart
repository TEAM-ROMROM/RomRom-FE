// lib/states/chat_rooms_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';

@immutable
class ChatRoomsState {
  /// 차단(blocked == true) 제외된 채팅방 목록.
  final List<ChatRoomDetailDto> rooms;

  /// 마지막으로 로드한 페이지 번호 (0-based).
  final int currentPage;

  /// 다음 페이지가 존재하는지 여부.
  final bool hasMore;

  const ChatRoomsState({this.rooms = const [], this.currentPage = 0, this.hasMore = true});

  ChatRoomsState copyWith({List<ChatRoomDetailDto>? rooms, int? currentPage, bool? hasMore}) => ChatRoomsState(
    rooms: rooms ?? this.rooms,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatRoomsState &&
          runtimeType == other.runtimeType &&
          listEquals(rooms, other.rooms) &&
          currentPage == other.currentPage &&
          hasMore == other.hasMore;

  @override
  int get hashCode => Object.hash(Object.hashAll(rooms), currentPage, hasMore);

  @override
  String toString() => 'ChatRoomsState(rooms: ${rooms.length}, page: $currentPage, hasMore: $hasMore)';
}
