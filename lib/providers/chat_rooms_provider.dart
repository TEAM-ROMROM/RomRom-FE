// lib/providers/chat_rooms_provider.dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';
import 'package:romrom_fe/states/chat_rooms_state.dart';
import 'package:romrom_fe/utils/chat_room_list_rules.dart';
import 'package:romrom_fe/utils/single_flight.dart';

final chatRoomsProvider = AsyncNotifierProvider<ChatRoomsNotifier, ChatRoomsState>(ChatRoomsNotifier.new);

class ChatRoomsNotifier extends AsyncNotifier<ChatRoomsState> {
  ChatRepository get _repo => ref.read(chatRepositoryProvider);

  /// 한 페이지 크기. 기존 chat_tab_screen._pageSize 와 동일.
  static const int _pageSize = 10;

  // 첫 페이지 병합 재조회 동시 1회 (모르는 방 메시지 연속 수신·탭 전환 겹침)
  SingleFlight<void> _firstPageRefreshFlight = SingleFlight<void>();

  // 재조회 후에도 목록에 없는 방 ID (나간 방·차단 방 > 메시지마다 재조회 방지, 전체 새로고침 시 초기화)
  final Set<String> _ignoredUnknownRoomIds = {};

  @override
  Future<ChatRoomsState> build() {
    // invalidate 후 Notifier 재사용 > 세션별 필드 초기화
    _firstPageRefreshFlight = SingleFlight<void>();
    _ignoredUnknownRoomIds.clear();
    return _fetchPage0();
  }

  Future<List<ChatRoomDetailDto>> _fetchFirstPageRooms() async {
    final paged = await _repo.getChatRooms(pageNumber: 0, pageSize: _pageSize);
    return paged.content.where((r) => r.blocked != true).toList();
  }

  Future<ChatRoomsState> _fetchPage0() async {
    final paged = await _repo.getChatRooms(pageNumber: 0, pageSize: _pageSize);
    final filtered = paged.content.where((r) => r.blocked != true).toList();
    return ChatRoomsState(rooms: filtered, currentPage: 0, hasMore: !paged.last);
  }

  /// 전체 새로고침 (1페이지 재로드, 페이징 리셋).
  /// 재조회 실패 시 이전 목록을 유지한 채 에러만 덧씌운다 (화면 blank 방지).
  Future<void> reload() async {
    _ignoredUnknownRoomIds.clear();
    final next = await AsyncValue.guard(_fetchPage0);
    state = next.hasError ? next.copyWithPrevious(state) : next;
  }

  /// 첫 페이지만 재조회해 기존 목록에 병합 (새 방 추가·기존 방 갱신, 이후 페이지·페이징 위치 유지)
  /// 탭 전환·모르는 방 메시지용 백그라운드 갱신 > 실패 시 기존 목록 유지 (동시 호출은 1회로 묶음)
  Future<void> refreshFirstPage() => _firstPageRefreshFlight.run(_mergeFirstPage);

  Future<void> _mergeFirstPage() async {
    try {
      final firstPageRooms = await _fetchFirstPageRooms();
      final currentState = state.valueOrNull;
      if (currentState == null) return;
      state = AsyncData(
        currentState.copyWith(
          rooms: mergeFirstPageRooms(currentRooms: currentState.rooms, firstPageRooms: firstPageRooms),
        ),
      );
    } catch (_) {
      // 백그라운드 갱신 실패는 무시 — 기존 목록 유지, 다음 탭 전환·당겨서 새로고침에서 재시도
    }
  }

  /// 채팅방 생성 > 목록 재조회 > 생성(또는 기존) 방 반환
  /// (재조회는 기다리지 않음: 채팅방 이동 지연 방지, 실패해도 이전 목록 유지)
  Future<ChatRoom> createRoom({required String opponentMemberId, required String tradeRequestHistoryId}) async {
    final createdRoom = await _repo.createChatRoom(
      opponentMemberId: opponentMemberId,
      tradeRequestHistoryId: tradeRequestHistoryId,
    );
    unawaited(reload());
    return createdRoom;
  }

  /// 채팅방 삭제(나가기) > 목록 재조회 (삭제 실패 시 예외 전달, 재조회 생략)
  Future<void> deleteRoom(String chatRoomId) async {
    await _repo.deleteChatRoom(chatRoomId: chatRoomId);
    unawaited(reload());
  }

  /// 다음 페이지 로드 (무한스크롤). 실패 시 기존 목록 유지 + 예외 전달 (화면이 안내)
  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore) return;
    final nextPage = cur.currentPage + 1;
    final paged = await _repo.getChatRooms(pageNumber: nextPage, pageSize: _pageSize);
    final filtered = paged.content.where((r) => r.blocked != true).toList();
    state = AsyncData(cur.copyWith(rooms: [...cur.rooms, ...filtered], currentPage: nextPage, hasMore: !paged.last));
  }

  /// WS 새 메시지 도착 시: 해당 방 last*/unread 업데이트.
  /// (목록 순서는 ChatRoomsState 가 lastMessageTime 내림차순 자동 정렬 — 이슈 #884)
  /// [myMemberId]: 내가 보낸 메시지이면 unreadCount 를 증가하지 않음.
  /// 목록에 없는 roomId > 첫 페이지 병합 재조회 (연속 수신 1회로 묶음, 상대가 새로 만든 방은 탭 전환 재조회가 보정)
  void onMessageReceived({required ChatMessage message, required String? myMemberId}) {
    final cur = state.valueOrNull;
    if (cur == null || message.chatRoomId == null) return;

    final roomId = message.chatRoomId!;
    final idx = cur.rooms.indexWhere((r) => r.chatRoomId == roomId);
    if (idx == -1) {
      if (!_ignoredUnknownRoomIds.contains(roomId)) unawaited(_refreshForUnknownRoom(roomId));
      return;
    }

    final room = cur.rooms[idx];

    // 내가 보낸 메시지면 unreadCount 증가하지 않음
    final newUnreadCount = (message.senderId == myMemberId) ? (room.unreadCount ?? 0) : (room.unreadCount ?? 0) + 1;

    final updated = room.copyWith(
      lastMessageContent: message.content ?? '',
      lastMessageTime: message.createdDate ?? DateTime.now(),
      unreadCount: newUnreadCount,
    );

    // 해당 방만 갱신한다. 목록 순서는 ChatRoomsState 생성자가
    // lastMessageTime 내림차순으로 자동 정렬하므로 수동 맨앞 이동은 불필요 (이슈 #884).
    final newRooms = [...cur.rooms];
    newRooms[idx] = updated;
    state = AsyncData(cur.copyWith(rooms: newRooms));
  }

  /// 모르는 방 메시지: 첫 페이지 병합 재조회 > 그래도 없으면 무시 목록에 기록
  Future<void> _refreshForUnknownRoom(String roomId) async {
    await refreshFirstPage();
    final isStillUnknown = !(state.valueOrNull?.rooms.any((room) => room.chatRoomId == roomId) ?? false);
    if (isStillUnknown) _ignoredUnknownRoomIds.add(roomId);
  }

  /// 채팅방 입장 시 unreadCount 를 0으로 초기화.
  void markRoomAsRead(String chatRoomId) {
    final cur = state.valueOrNull;
    if (cur == null) return;
    final idx = cur.rooms.indexWhere((r) => r.chatRoomId == chatRoomId);
    if (idx == -1) return;
    final updated = cur.rooms[idx].copyWith(unreadCount: 0);
    final newRooms = [...cur.rooms];
    newRooms[idx] = updated;
    state = AsyncData(cur.copyWith(rooms: newRooms));
  }
}
