// lib/states/chat_rooms_state.dart
import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';

@immutable
class ChatRoomsState {
  /// 차단(blocked == true) 제외 + lastMessageTime 내림차순 정렬된 채팅방 목록.
  final List<ChatRoomDetailDto> rooms;

  /// 마지막으로 로드한 페이지 번호 (0-based).
  final int currentPage;

  /// 다음 페이지가 존재하는지 여부.
  final bool hasMore;

  /// rooms는 생성 시점에 항상 최신순 정렬되어 보관된다.
  /// 채팅방 목록의 단일 소유자이므로, 모든 갱신 경로(초기 로드/새로고침/페이징/WS 수신)가
  /// 이 생성자를 거치며 정렬이 보장된다 (이슈 #884).
  ChatRoomsState({List<ChatRoomDetailDto> rooms = const [], this.currentPage = 0, this.hasMore = true})
    : rooms = _sortByRecent(rooms);

  /// lastMessageTime 내림차순(최신이 위), null은 맨 뒤. 884 원본 로직 그대로.
  static List<ChatRoomDetailDto> _sortByRecent(List<ChatRoomDetailDto> rooms) {
    final sorted = [...rooms];
    sorted.sort((a, b) {
      final ta = a.lastMessageTime;
      final tb = b.lastMessageTime;
      if (ta == null && tb == null) return 0;
      if (ta == null) return 1;
      if (tb == null) return -1;
      return tb.compareTo(ta);
    });
    return sorted;
  }

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
