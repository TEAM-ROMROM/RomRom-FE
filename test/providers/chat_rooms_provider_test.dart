import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';
import 'package:romrom_fe/providers/chat_repository_provider.dart';
import 'package:romrom_fe/providers/chat_rooms_provider.dart';
import 'package:romrom_fe/repositories/chat_repository.dart';

/// 서버 채팅방 목록을 흉내 내는 가짜 저장소 (생성·삭제 결과는 재조회로만 보임)
class FakeChatRepository implements ChatRepository {
  List<ChatRoomDetailDto> serverRooms = [];
  int getChatRoomsCallCount = 0;
  int createChatRoomCallCount = 0;
  int deleteChatRoomCallCount = 0;
  bool shouldFailDelete = false;
  // 첫 페이지가 마지막인지, 다음 페이지(1 이상)·첫 페이지 조회 실패 여부
  bool isFirstPageLast = true;
  bool shouldFailNextPage = false;
  bool shouldFailFirstPage = false;
  // 페이지별 서버 방 (없으면 serverRooms)
  Map<int, List<ChatRoomDetailDto>> roomsByPage = {};
  // 조회 요청 기록 (페이지 번호, 페이지 크기)
  final List<(int, int)> requestedPages = [];

  @override
  Future<PagedChatRoomDetail> getChatRooms({required int pageNumber, int pageSize = 10}) async {
    getChatRoomsCallCount++;
    requestedPages.add((pageNumber, pageSize));
    if (pageNumber > 0 && shouldFailNextPage) throw Exception('next page failed');
    if (pageNumber == 0 && shouldFailFirstPage) throw Exception('first page failed');
    return PagedChatRoomDetail(
      content: roomsByPage[pageNumber] ?? serverRooms,
      last: pageNumber > 0 || isFirstPageLast,
    );
  }

  @override
  Future<ChatRoom> createChatRoom({required String opponentMemberId, required String tradeRequestHistoryId}) async {
    createChatRoomCallCount++;
    serverRooms = [...serverRooms, ChatRoomDetailDto(chatRoomId: 'created')];
    return ChatRoom(chatRoomId: 'created');
  }

  @override
  Future<void> deleteChatRoom({required String chatRoomId}) async {
    deleteChatRoomCallCount++;
    if (shouldFailDelete) throw Exception('boom');
    serverRooms = serverRooms.where((room) => room.chatRoomId != chatRoomId).toList();
  }

  // 방별 알림 끄기 요청 기록 (방 ID, 요청 값) / 서버 확정 값 (null > 요청 값 그대로)
  final List<(String, bool)> requestedNotificationMutes = [];
  bool? isConfirmedNotificationMuted;
  bool shouldFailNotificationMute = false;

  @override
  Future<bool> updateNotificationMute({required String chatRoomId, required bool isNotificationMuted}) async {
    requestedNotificationMutes.add((chatRoomId, isNotificationMuted));
    if (shouldFailNotificationMute) throw Exception('mute failed');
    return isConfirmedNotificationMuted ?? isNotificationMuted;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// 미반영 재조회(unawaited) 완료 대기
Future<void> flushMicrotasks() => Future<void>.delayed(Duration.zero);

void main() {
  group('chatRoomsProvider 생성·삭제', () {
    late FakeChatRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeChatRepository()..serverRooms = [ChatRoomDetailDto(chatRoomId: 'a')];
      container = ProviderContainer(overrides: [chatRepositoryProvider.overrideWithValue(fakeRepository)]);
    });
    tearDown(() => container.dispose());

    test('deleteRoom은 저장소 삭제 1회 후 서버 재조회로 목록을 갱신한다', () async {
      await container.read(chatRoomsProvider.future);
      final fetchCountBeforeDelete = fakeRepository.getChatRoomsCallCount;

      await container.read(chatRoomsProvider.notifier).deleteRoom('a');
      await flushMicrotasks();

      expect(fakeRepository.deleteChatRoomCallCount, 1);
      expect(fakeRepository.getChatRoomsCallCount, fetchCountBeforeDelete + 1);
      expect(container.read(chatRoomsProvider).valueOrNull?.rooms, isEmpty);
    });

    test('deleteRoom 실패 시 예외를 전달하고 재조회하지 않는다', () async {
      await container.read(chatRoomsProvider.future);
      final fetchCountBeforeDelete = fakeRepository.getChatRoomsCallCount;
      fakeRepository.shouldFailDelete = true;

      await expectLater(container.read(chatRoomsProvider.notifier).deleteRoom('a'), throwsException);
      await flushMicrotasks();

      expect(fakeRepository.getChatRoomsCallCount, fetchCountBeforeDelete);
      expect(container.read(chatRoomsProvider).valueOrNull?.rooms.map((room) => room.chatRoomId), ['a']);
    });

    test('createRoom은 생성된 방을 반환하고 서버 재조회로 목록에 반영한다', () async {
      await container.read(chatRoomsProvider.future);
      final fetchCountBeforeCreate = fakeRepository.getChatRoomsCallCount;

      final createdRoom = await container
          .read(chatRoomsProvider.notifier)
          .createRoom(opponentMemberId: 'opponent', tradeRequestHistoryId: 'history');
      await flushMicrotasks();

      expect(createdRoom.chatRoomId, 'created');
      expect(fakeRepository.createChatRoomCallCount, 1);
      expect(fakeRepository.getChatRoomsCallCount, fetchCountBeforeCreate + 1);
      expect(container.read(chatRoomsProvider).valueOrNull?.rooms.map((room) => room.chatRoomId), contains('created'));
    });
  });

  group('chatRoomsProvider 모르는 방 메시지·다음 페이지 실패', () {
    late FakeChatRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeChatRepository()..serverRooms = [ChatRoomDetailDto(chatRoomId: 'a')];
      container = ProviderContainer(overrides: [chatRepositoryProvider.overrideWithValue(fakeRepository)]);
    });
    tearDown(() => container.dispose());

    ChatMessage buildIncomingMessage(String chatRoomId) =>
        ChatMessage(chatRoomId: chatRoomId, senderId: 'other', content: '안녕', type: MessageType.text);

    test('목록에 없는 방(새로고침으로 밀려난 방 등) 메시지가 연달아 오면 첫 페이지 재조회 1회로 병합한다', () async {
      await container.read(chatRoomsProvider.future);
      final fetchCountBeforeMessage = fakeRepository.getChatRoomsCallCount;
      fakeRepository.serverRooms = [ChatRoomDetailDto(chatRoomId: 'a'), ChatRoomDetailDto(chatRoomId: 'pushed')];

      final notifier = container.read(chatRoomsProvider.notifier);
      notifier.onMessageReceived(message: buildIncomingMessage('pushed'), myMemberId: 'me');
      notifier.onMessageReceived(message: buildIncomingMessage('pushed'), myMemberId: 'me');
      await flushMicrotasks();

      expect(fakeRepository.getChatRoomsCallCount, fetchCountBeforeMessage + 1);
      expect(container.read(chatRoomsProvider).valueOrNull?.rooms.map((room) => room.chatRoomId), contains('pushed'));
    });

    test('재조회 후에도 목록에 없는 방(나간 방·차단 방)은 기록해 다음 메시지부터 재조회하지 않는다', () async {
      await container.read(chatRoomsProvider.future);
      final notifier = container.read(chatRoomsProvider.notifier);

      notifier.onMessageReceived(message: buildIncomingMessage('left'), myMemberId: 'me');
      await flushMicrotasks();
      final fetchCountAfterFirstRefresh = fakeRepository.getChatRoomsCallCount;
      notifier.onMessageReceived(message: buildIncomingMessage('left'), myMemberId: 'me');
      await flushMicrotasks();

      expect(fakeRepository.getChatRoomsCallCount, fetchCountAfterFirstRefresh);
    });

    test('refreshFirstPage는 첫 페이지를 기존 목록에 병합하고 이후 페이지·페이징 위치를 유지한다', () async {
      fakeRepository.isFirstPageLast = false;
      fakeRepository.roomsByPage = {
        0: [ChatRoomDetailDto(chatRoomId: 'a', unreadCount: 0)],
        1: [ChatRoomDetailDto(chatRoomId: 'old')],
      };
      await container.read(chatRoomsProvider.future);
      await container.read(chatRoomsProvider.notifier).loadMore();
      fakeRepository.roomsByPage = {
        0: [ChatRoomDetailDto(chatRoomId: 'a', unreadCount: 3), ChatRoomDetailDto(chatRoomId: 'new')],
      };

      await container.read(chatRoomsProvider.notifier).refreshFirstPage();

      final roomsState = container.read(chatRoomsProvider).valueOrNull!;
      expect(roomsState.rooms.map((room) => room.chatRoomId), containsAll(['a', 'old', 'new']));
      expect(roomsState.rooms.firstWhere((room) => room.chatRoomId == 'a').unreadCount, 3);
      expect(roomsState.currentPage, 1);
    });

    test('refreshFirstPage 실패 시 기존 목록 유지 (조용히 무시)', () async {
      await container.read(chatRoomsProvider.future);
      fakeRepository.shouldFailFirstPage = true;

      await container.read(chatRoomsProvider.notifier).refreshFirstPage();

      expect(container.read(chatRoomsProvider).valueOrNull?.rooms.map((room) => room.chatRoomId), ['a']);
      expect(container.read(chatRoomsProvider).hasError, isFalse);
    });

    test('목록에 있는 방 메시지는 재조회 없이 안 읽음 수만 올린다', () async {
      await container.read(chatRoomsProvider.future);
      final fetchCountBeforeMessage = fakeRepository.getChatRoomsCallCount;

      container
          .read(chatRoomsProvider.notifier)
          .onMessageReceived(message: buildIncomingMessage('a'), myMemberId: 'me');
      await flushMicrotasks();

      expect(fakeRepository.getChatRoomsCallCount, fetchCountBeforeMessage);
      expect(container.read(chatRoomsProvider).valueOrNull?.rooms.single.unreadCount, 1);
    });

    test('다음 페이지 조회 실패 시 예외를 전달하고 기존 목록을 유지한다', () async {
      fakeRepository.isFirstPageLast = false;
      fakeRepository.shouldFailNextPage = true;
      await container.read(chatRoomsProvider.future);

      await expectLater(container.read(chatRoomsProvider.notifier).loadMore(), throwsException);

      final roomsState = container.read(chatRoomsProvider).valueOrNull;
      expect(roomsState?.rooms.map((room) => room.chatRoomId), ['a']);
      expect(roomsState?.hasMore, isTrue);
    });
  });

  group('chatRoomsProvider 불러온 페이지 유지 재조회 (#984)', () {
    late FakeChatRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeChatRepository()
        ..isFirstPageLast = false
        ..roomsByPage = {
          0: [ChatRoomDetailDto(chatRoomId: 'a')],
          1: [ChatRoomDetailDto(chatRoomId: 'page2')],
        };
      container = ProviderContainer(overrides: [chatRepositoryProvider.overrideWithValue(fakeRepository)]);
    });
    tearDown(() => container.dispose());

    test('refreshLoadedPages는 불러온 페이지 수만큼 page 0에서 한 번에 조회하고 페이징 위치를 유지한다', () async {
      await container.read(chatRoomsProvider.future);
      await container.read(chatRoomsProvider.notifier).loadMore();
      fakeRepository.roomsByPage = {
        0: [ChatRoomDetailDto(chatRoomId: 'a'), ChatRoomDetailDto(chatRoomId: 'page2', unreadCount: 1)],
      };

      await container.read(chatRoomsProvider.notifier).refreshLoadedPages();

      expect(fakeRepository.requestedPages.last, (0, 20));
      final roomsState = container.read(chatRoomsProvider).valueOrNull!;
      expect(roomsState.rooms.map((room) => room.chatRoomId), unorderedEquals(['a', 'page2']));
      expect(roomsState.currentPage, 1, reason: '다음 페이지 이어 불러오기 위치 유지');
    });

    test('refreshLoadedPages 실패 > 기존 목록 유지 (조용히 무시)', () async {
      await container.read(chatRoomsProvider.future);
      await container.read(chatRoomsProvider.notifier).loadMore();
      fakeRepository.shouldFailFirstPage = true;

      await container.read(chatRoomsProvider.notifier).refreshLoadedPages();

      final roomsState = container.read(chatRoomsProvider);
      expect(roomsState.hasError, isFalse);
      expect(roomsState.valueOrNull?.rooms.map((room) => room.chatRoomId), unorderedEquals(['a', 'page2']));
    });

    test('2페이지 방에서 나가기(삭제) > 1페이지로 줄지 않고 불러온 범위 재조회', () async {
      await container.read(chatRoomsProvider.future);
      await container.read(chatRoomsProvider.notifier).loadMore();
      fakeRepository.roomsByPage = {
        0: [ChatRoomDetailDto(chatRoomId: 'a')],
      };

      await container.read(chatRoomsProvider.notifier).deleteRoom('page2');
      await flushMicrotasks();

      expect(fakeRepository.requestedPages.last, (0, 20));
      expect(container.read(chatRoomsProvider).valueOrNull?.currentPage, 1);
    });
  });

  group('chatRoomsProvider 방별 알림 끄기', () {
    late FakeChatRepository fakeRepository;
    late ProviderContainer container;

    setUp(() {
      fakeRepository = FakeChatRepository()
        ..serverRooms = [ChatRoomDetailDto(chatRoomId: 'a'), ChatRoomDetailDto(chatRoomId: 'b')];
      container = ProviderContainer(overrides: [chatRepositoryProvider.overrideWithValue(fakeRepository)]);
    });
    tearDown(() => container.dispose());

    test('setNotificationMuted는 서버 확정 값으로 해당 방만 갱신하고 확정 값을 반환한다', () async {
      await container.read(chatRoomsProvider.future);
      fakeRepository.isConfirmedNotificationMuted = true;

      final isConfirmedMuted = await container
          .read(chatRoomsProvider.notifier)
          .setNotificationMuted(chatRoomId: 'a', isNotificationMuted: true);

      final rooms = container.read(chatRoomsProvider).valueOrNull!.rooms;
      expect(isConfirmedMuted, isTrue);
      expect(fakeRepository.requestedNotificationMutes, [('a', true)]);
      expect(rooms.firstWhere((room) => room.chatRoomId == 'a').isNotificationMuted, isTrue);
      expect(rooms.firstWhere((room) => room.chatRoomId == 'b').isNotificationMuted, isNull);
    });

    test('setNotificationMuted 실패 시 예외 전달, 목록 유지', () async {
      await container.read(chatRoomsProvider.future);
      fakeRepository.shouldFailNotificationMute = true;

      await expectLater(
        container.read(chatRoomsProvider.notifier).setNotificationMuted(chatRoomId: 'a', isNotificationMuted: true),
        throwsException,
      );
      final rooms = container.read(chatRoomsProvider).valueOrNull!.rooms;
      expect(rooms.firstWhere((room) => room.chatRoomId == 'a').isNotificationMuted, isNull);
    });
  });
}
