import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

  @override
  Future<PagedChatRoomDetail> getChatRooms({required int pageNumber, int pageSize = 10}) async {
    getChatRoomsCallCount++;
    return PagedChatRoomDetail(content: serverRooms);
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
}
