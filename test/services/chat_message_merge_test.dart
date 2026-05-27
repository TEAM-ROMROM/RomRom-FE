import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/screens/chat_room_screen.dart';

void main() {
  // mergeServerMessages: reverse 정렬(index 0 = 최신) 목록 기준.
  // - 서버 메시지 중 현재 목록에 없는 것만 추가
  // - 이미 있으면 서버 버전으로 교체
  // - 낙관적 로컬 메시지(id가 'local_'/'uploading_' 접두)는 보존
  group('mergeServerMessages', () {
    ChatMessage msg(String? id, String content, int epochMs, {String? sender}) => ChatMessage(
      chatRoomId: 'room1',
      chatMessageId: id,
      senderId: sender ?? 'me',
      content: content,
      type: MessageType.text,
      createdDate: DateTime.fromMillisecondsSinceEpoch(epochMs),
    );

    test('현재 목록에 없는 서버 메시지를 병합한다', () {
      final current = [msg('s2', 'b', 2000)];
      final server = [msg('s2', 'b', 2000), msg('s1', 'a', 1000)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.map((m) => m.chatMessageId).toList(), ['s2', 's1']);
    });

    test('중복 ID는 추가하지 않고 서버 버전으로 교체한다', () {
      final current = [msg('s1', 'old', 1000)];
      final server = [msg('s1', 'new', 1500)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.length, 1);
      expect(result.first.content, 'new');
      expect(result.first.createdDate, DateTime.fromMillisecondsSinceEpoch(1500));
    });

    test('낙관적 로컬 메시지는 보존한다', () {
      final current = [msg('local_123', '보내는중', 3000), msg('s1', 'a', 1000)];
      final server = [msg('s1', 'a', 1000)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.any((m) => m.chatMessageId == 'local_123'), isTrue);
    });

    test('결과는 createdDate 내림차순(최신 먼저)으로 정렬한다', () {
      final current = <ChatMessage>[];
      final server = [msg('s1', 'a', 1000), msg('s3', 'c', 3000), msg('s2', 'b', 2000)];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.map((m) => m.chatMessageId).toList(), ['s3', 's2', 's1']);
    });

    test('createdDate가 null인 메시지는 맨 뒤로 정렬한다', () {
      final current = <ChatMessage>[];
      final server = [
        msg('s1', 'a', 1000),
        ChatMessage(chatRoomId: 'room1', chatMessageId: 'sNull', senderId: 'me', content: 'x', type: MessageType.text),
      ];

      final result = mergeServerMessages(current: current, serverMessages: server);

      expect(result.last.chatMessageId, 'sNull');
    });
  });
}
