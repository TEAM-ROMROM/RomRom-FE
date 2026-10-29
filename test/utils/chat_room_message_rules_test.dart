import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_user_state.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';

/// 테스트용 메시지 생성 (reverse 목록 기준 시각은 밀리초)
ChatMessage buildChatMessage(
  String? id, {
  String sender = 'me',
  MessageType type = MessageType.text,
  String? content,
  DateTime? createdDate,
  List<String>? imageUrls,
}) {
  return ChatMessage(
    chatRoomId: 'room1',
    chatMessageId: id,
    senderId: sender,
    content: content,
    type: type,
    createdDate: createdDate,
    imageUrls: imageUrls,
  );
}

void main() {
  final baseTime = DateTime(2026, 10, 29, 12, 0);

  group('isActiveTradeRequestAt / hasActiveTradeRequest', () {
    test('더 최신 메시지에 취소·거절·완료 없으면 활성', () {
      final messages = [buildChatMessage('m2'), buildChatMessage('r1', type: MessageType.tradeCompleteRequest)];

      expect(isActiveTradeRequestAt(messages: messages, index: 1, isTradeCompleted: false), isTrue);
      expect(hasActiveTradeRequest(messages: messages, isTradeCompleted: false), isTrue);
    });

    test('더 최신 메시지에 거절·취소·완료 있으면 비활성', () {
      for (final closingType in [
        MessageType.tradeCompleteRequestRejected,
        MessageType.tradeCompleteRequestCanceled,
        MessageType.tradeCompleted,
      ]) {
        final messages = [
          buildChatMessage('c1', type: closingType),
          buildChatMessage('r1', type: MessageType.tradeCompleteRequest),
        ];
        expect(isActiveTradeRequestAt(messages: messages, index: 1, isTradeCompleted: false), isFalse);
      }
    });

    test('거래 완료 방은 항상 비활성, 요청 없으면 hasActiveTradeRequest false', () {
      final messages = [buildChatMessage('r1', type: MessageType.tradeCompleteRequest)];

      expect(isActiveTradeRequestAt(messages: messages, index: 0, isTradeCompleted: true), isFalse);
      expect(hasActiveTradeRequest(messages: [buildChatMessage('m1')], isTradeCompleted: false), isFalse);
    });
  });

  group('findLastReadMyMessageId', () {
    final messages = [
      buildChatMessage('mine3', createdDate: baseTime.add(const Duration(minutes: 3))),
      buildChatMessage('other2', sender: 'other', createdDate: baseTime.add(const Duration(minutes: 2))),
      buildChatMessage('mine1', createdDate: baseTime.add(const Duration(minutes: 1))),
    ];

    test('상대 재실 > 최신 내 메시지', () {
      final id = findLastReadMyMessageId(
        messages: messages,
        myMemberId: 'me',
        opponentState: ChatUserState(isPresent: true),
      );
      expect(id, 'mine3');
    });

    test('상대 퇴장 > 퇴장 시각 이전에 보낸 최신 내 메시지', () {
      final id = findLastReadMyMessageId(
        messages: messages,
        myMemberId: 'me',
        opponentState: ChatUserState(leftAt: baseTime.add(const Duration(minutes: 2))),
      );
      expect(id, 'mine1');
    });

    test('읽음 상태·내 ID 없으면 null', () {
      expect(findLastReadMyMessageId(messages: messages, myMemberId: 'me', opponentState: null), isNull);
      expect(
        findLastReadMyMessageId(messages: messages, myMemberId: null, opponentState: ChatUserState(isPresent: true)),
        isNull,
      );
    });
  });

  group('isGroupedWithOlderMessage / shouldShowMessageTime', () {
    final messages = [
      buildChatMessage('a3', createdDate: baseTime.add(const Duration(seconds: 30))),
      buildChatMessage('a2', createdDate: baseTime.add(const Duration(seconds: 10))),
      buildChatMessage('b1', sender: 'other', createdDate: baseTime),
    ];

    test('같은 발신자·같은 종류의 더 오래된 메시지가 있으면 묶음', () {
      expect(isGroupedWithOlderMessage(messages: messages, index: 0), isTrue);
      expect(isGroupedWithOlderMessage(messages: messages, index: 1), isFalse);
      // 가장 오래된 메시지는 비교 대상 없음
      expect(isGroupedWithOlderMessage(messages: messages, index: 2), isFalse);
    });

    test('종류가 다르면 묶지 않음', () {
      final mixedTypes = [buildChatMessage('i1', type: MessageType.image), buildChatMessage('t1')];
      expect(isGroupedWithOlderMessage(messages: mixedTypes, index: 0), isFalse);
    });

    test('최신 메시지는 시각 표시, 같은 발신자·같은 분이면 숨김, 발신자 바뀌면 표시', () {
      expect(shouldShowMessageTime(messages: messages, index: 0), isTrue);
      expect(shouldShowMessageTime(messages: messages, index: 1), isFalse);
      expect(shouldShowMessageTime(messages: messages, index: 2), isTrue);
    });

    test('같은 발신자라도 분이 다르면 시각 표시', () {
      final differentMinutes = [
        buildChatMessage('a2', createdDate: baseTime.add(const Duration(minutes: 1))),
        buildChatMessage('a1', createdDate: baseTime),
      ];
      expect(shouldShowMessageTime(messages: differentMinutes, index: 1), isTrue);
    });
  });

  group('findMatchingPendingLocalMessageId', () {
    final pendingLocalMessages = {
      'local_1': buildChatMessage('local_1', content: '안녕', createdDate: baseTime),
      'local_2': buildChatMessage('local_2', content: '사진을 보냈습니다.', createdDate: baseTime),
    };

    test('내 에코 + 같은 내용 + 10초 이내 > 로컬 ID', () {
      final echo = buildChatMessage(
        's1',
        content: '사진을 보냈습니다.',
        createdDate: baseTime.add(const Duration(seconds: 10)),
      );
      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pendingLocalMessages,
          incomingMessage: echo,
          myMemberId: 'me',
        ),
        'local_2',
      );
    });

    test('10초 초과·다른 내용·상대 메시지 > null', () {
      final lateEcho = buildChatMessage('s1', content: '안녕', createdDate: baseTime.add(const Duration(seconds: 11)));
      final otherContent = buildChatMessage('s2', content: '다른 말', createdDate: baseTime);
      final opponentMessage = buildChatMessage('s3', sender: 'other', content: '안녕', createdDate: baseTime);
      for (final incoming in [lateEcho, otherContent, opponentMessage]) {
        expect(
          findMatchingPendingLocalMessageId(
            pendingLocalMessages: pendingLocalMessages,
            incomingMessage: incoming,
            myMemberId: 'me',
          ),
          isNull,
        );
      }
    });
  });

  group('mergeServerEchoIntoLocalMessage', () {
    test('서버 값 우선, 빈 내용·빈 이미지는 로컬 값 유지', () {
      final local = buildChatMessage(
        'local_1',
        type: MessageType.image,
        content: '사진을 보냈습니다.',
        createdDate: baseTime,
        imageUrls: const ['local.webp'],
      );
      final server = buildChatMessage(
        's1',
        type: MessageType.image,
        content: '  ',
        createdDate: baseTime.add(const Duration(seconds: 1)),
        imageUrls: const [],
      );

      final confirmed = mergeServerEchoIntoLocalMessage(localMessage: local, serverMessage: server);

      expect(confirmed.chatMessageId, 's1');
      expect(confirmed.content, '사진을 보냈습니다.');
      expect(confirmed.imageUrls, ['local.webp']);
      expect(confirmed.createdDate, baseTime.add(const Duration(seconds: 1)));
    });
  });

  group('matchWebSocketImagePlaceholders', () {
    test('발신자별 순서대로 짝지음, 서버 이미지 부족하면 남은 임시 메시지 유지', () {
      final messages = [
        buildChatMessage('ws_img_2', type: MessageType.image),
        buildChatMessage('t1'),
        buildChatMessage('ws_img_1', type: MessageType.image),
        buildChatMessage('ws_img_3', sender: 'other', type: MessageType.image),
      ];
      final serverMessages = [
        buildChatMessage('s2', type: MessageType.image, imageUrls: const ['b.webp']),
        buildChatMessage('s0', type: MessageType.image, imageUrls: const []),
        buildChatMessage('s1', type: MessageType.text),
      ];

      final replacements = matchWebSocketImagePlaceholders(
        messages: messages,
        placeholderIds: {'ws_img_1', 'ws_img_2', 'ws_img_3'},
        serverMessages: serverMessages,
      );

      expect(replacements.length, 1);
      final (placeholderId, index, replacement) = replacements.single;
      expect(placeholderId, 'ws_img_2');
      expect(index, 0);
      expect(replacement.chatMessageId, 's2');
    });
  });
}
