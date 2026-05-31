// lib/providers/chat_rooms_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';

final chatRoomsProvider = AsyncNotifierProvider<ChatRoomsNotifier, ChatRoomsState>(ChatRoomsNotifier.new);

class ChatRoomsNotifier extends AsyncNotifier<ChatRoomsState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  /// 한 페이지 크기. 기존 chat_tab_screen._pageSize 와 동일.
  static const int _pageSize = 10;

  @override
  Future<ChatRoomsState> build() => _fetchPage0();

  Future<ChatRoomsState> _fetchPage0() async {
    final paged = await _repo.getChatRooms(pageNumber: 0, pageSize: _pageSize);
    final filtered = paged.content.where((r) => r.blocked != true).toList();
    return ChatRoomsState(rooms: filtered, currentPage: 0, hasMore: !paged.last);
  }

  /// 전체 새로고침 (1페이지 재로드, 페이징 리셋).
  /// 재조회 실패 시 이전 목록을 유지한 채 에러만 덧씌운다 (화면 blank 방지).
  Future<void> reload() async {
    final next = await AsyncValue.guard(_fetchPage0);
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  /// 다음 페이지 로드 (무한스크롤).
  Future<void> loadMore() async {
    final cur = state.value;
    if (cur == null || !cur.hasMore) return;
    try {
      final nextPage = cur.currentPage + 1;
      final paged = await _repo.getChatRooms(pageNumber: nextPage, pageSize: _pageSize);
      final filtered = paged.content.where((r) => r.blocked != true).toList();
      state = AsyncData(cur.copyWith(rooms: [...cur.rooms, ...filtered], currentPage: nextPage, hasMore: !paged.last));
    } catch (_) {
      // 페이징 실패는 조용히 처리 — 기존 목록 유지
    }
  }

  /// WS 새 메시지 도착 시: 해당 방 last*/unread 업데이트 + 맨 앞 이동.
  /// [myMemberId]: 내가 보낸 메시지이면 unreadCount 를 증가하지 않음.
  /// 목록에 없는 roomId는 무시 (기존 동작 유지).
  void onMessageReceived({required ChatMessage message, required String? myMemberId}) {
    final cur = state.value;
    if (cur == null || message.chatRoomId == null) return;

    final roomId = message.chatRoomId!;
    final idx = cur.rooms.indexWhere((r) => r.chatRoomId == roomId);
    if (idx == -1) return;

    final room = cur.rooms[idx];

    // 내가 보낸 메시지면 unreadCount 증가하지 않음
    final newUnreadCount = (message.senderId == myMemberId) ? (room.unreadCount ?? 0) : (room.unreadCount ?? 0) + 1;

    final updated = room.copyWith(
      lastMessageContent: message.content ?? '',
      lastMessageTime: message.createdDate ?? DateTime.now(),
      unreadCount: newUnreadCount,
    );

    final reordered = [updated, ...cur.rooms.where((r) => r.chatRoomId != roomId)];
    state = AsyncData(cur.copyWith(rooms: reordered));
  }

  /// 채팅방 입장 시 unreadCount 를 0으로 초기화.
  void markRoomAsRead(String chatRoomId) {
    final cur = state.value;
    if (cur == null) return;
    final idx = cur.rooms.indexWhere((r) => r.chatRoomId == chatRoomId);
    if (idx == -1) return;
    final updated = cur.rooms[idx].copyWith(unreadCount: 0);
    final newRooms = [...cur.rooms];
    newRooms[idx] = updated;
    state = AsyncData(cur.copyWith(rooms: newRooms));
  }

  /// 방 나가기/삭제 후 목록에서 즉시 제거.
  void removeRoom(String chatRoomId) {
    final cur = state.value;
    if (cur == null) return;
    state = AsyncData(cur.copyWith(rooms: cur.rooms.where((r) => r.chatRoomId != chatRoomId).toList()));
  }
}
