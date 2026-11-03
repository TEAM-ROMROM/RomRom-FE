import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_message_send_status.dart';
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

    test('서버 확인 전 로컬 메시지(전송 중·실패)는 건너뛰고 서버 메시지에 읽음 표시', () {
      final messagesWithPending = [
        buildChatMessage('local_9_1', createdDate: baseTime.add(const Duration(minutes: 4))),
        ...messages,
      ];
      final id = findLastReadMyMessageId(
        messages: messagesWithPending,
        myMemberId: 'me',
        opponentState: ChatUserState(isPresent: true),
      );
      expect(id, 'mine3');
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

  group('shouldShowDateDivider (reverse 목록: index 0 = 최신)', () {
    test('메시지 1개 > 가장 오래된 메시지라 구분선 표시', () {
      final messages = [buildChatMessage('m1', createdDate: baseTime)];
      expect(shouldShowDateDivider(messages: messages, index: 0), isTrue);
    });

    test('같은 날짜 > 가장 오래된 메시지 위에만 구분선', () {
      final messages = [
        buildChatMessage('m3', createdDate: DateTime(2026, 11, 1, 23, 59)),
        buildChatMessage('m2', createdDate: DateTime(2026, 11, 1, 9, 5)),
        buildChatMessage('m1', createdDate: DateTime(2026, 11, 1, 0, 0)),
      ];
      expect(shouldShowDateDivider(messages: messages, index: 0), isFalse);
      expect(shouldShowDateDivider(messages: messages, index: 1), isFalse);
      expect(shouldShowDateDivider(messages: messages, index: 2), isTrue);
    });

    test('자정 경계 (23:59 > 00:00) > 새 날짜 첫 메시지 위에 구분선', () {
      final messages = [
        buildChatMessage('m2', createdDate: DateTime(2026, 11, 1, 0, 0)),
        buildChatMessage('m1', createdDate: DateTime(2026, 10, 31, 23, 59)),
      ];
      expect(shouldShowDateDivider(messages: messages, index: 0), isTrue);
      expect(shouldShowDateDivider(messages: messages, index: 1), isTrue);
    });

    test('UTC 시각도 로컬 날짜로 판정 (시간대 무관)', () {
      final messages = [
        buildChatMessage('m2', createdDate: DateTime(2026, 11, 1, 0, 5).toUtc()),
        buildChatMessage('m1', createdDate: DateTime(2026, 10, 31, 23, 55).toUtc()),
      ];
      expect(shouldShowDateDivider(messages: messages, index: 0), isTrue);

      final sameLocalDate = [
        buildChatMessage('m2', createdDate: DateTime(2026, 11, 1, 23, 55).toUtc()),
        buildChatMessage('m1', createdDate: DateTime(2026, 11, 1, 0, 5)),
      ];
      expect(shouldShowDateDivider(messages: sameLocalDate, index: 0), isFalse);
    });

    test('시각 없는 메시지 > 구분선 없음, 비교는 시각 있는 더 오래된 메시지와', () {
      final messages = [
        buildChatMessage('m3', createdDate: DateTime(2026, 11, 1, 10)),
        buildChatMessage('local_1'),
        buildChatMessage('m1', createdDate: DateTime(2026, 11, 1, 9)),
      ];
      expect(shouldShowDateDivider(messages: messages, index: 1), isFalse);
      expect(shouldShowDateDivider(messages: messages, index: 0), isFalse);

      final nextDay = [buildChatMessage('m3', createdDate: DateTime(2026, 11, 2, 10)), ...messages.skip(1)];
      expect(shouldShowDateDivider(messages: nextDay, index: 0), isTrue);
    });

    test('여러 날짜 > 날짜가 바뀌는 메시지마다 구분선 (구분선 수 = 날짜 수)', () {
      final messages = [
        buildChatMessage('m4', createdDate: DateTime(2026, 11, 3, 8)),
        buildChatMessage('m3', createdDate: DateTime(2026, 11, 1, 20)),
        buildChatMessage('m2', createdDate: DateTime(2026, 11, 1, 8)),
        buildChatMessage('m1', createdDate: DateTime(2025, 12, 31, 22)),
      ];
      final dividerIndexes = [
        for (int index = 0; index < messages.length; index++)
          if (shouldShowDateDivider(messages: messages, index: index)) index,
      ];
      expect(dividerIndexes, [0, 2, 3]);
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

  group('resolveMessageSendStatus', () {
    test('실패 목록에 있으면 실패, 서버 응답 대기 중이면 전송 중, 그 외 전송 완료', () {
      expect(
        resolveMessageSendStatus(
          messageId: 'local_1',
          pendingLocalMessageIds: {'local_1'},
          failedLocalMessageIds: {'local_1'},
        ),
        ChatMessageSendStatus.failed,
      );
      expect(
        resolveMessageSendStatus(messageId: 'local_1', pendingLocalMessageIds: {'local_1'}, failedLocalMessageIds: {}),
        ChatMessageSendStatus.sending,
      );
      expect(
        resolveMessageSendStatus(messageId: 'server_1', pendingLocalMessageIds: {'local_1'}, failedLocalMessageIds: {}),
        ChatMessageSendStatus.sent,
      );
      expect(
        resolveMessageSendStatus(messageId: null, pendingLocalMessageIds: {'local_1'}, failedLocalMessageIds: {}),
        ChatMessageSendStatus.sent,
      );
    });
  });

  group('appendOlderMessages', () {
    test('이미 있는 ID는 빼고 이전 메시지를 목록 뒤(오래된 쪽)에 붙인다', () {
      final current = [buildChatMessage('m3'), buildChatMessage('m2')];
      final olderPage = [buildChatMessage('m2'), buildChatMessage('m1'), buildChatMessage('m0')];

      final merged = appendOlderMessages(current: current, olderMessages: olderPage);

      expect(merged.map((message) => message.chatMessageId), ['m3', 'm2', 'm1', 'm0']);
    });

    test('ID 없는 이전 메시지는 그대로 붙인다', () {
      final merged = appendOlderMessages(current: [buildChatMessage('m1')], olderMessages: [buildChatMessage(null)]);

      expect(merged.length, 2);
    });
  });

  group('mergeServerEchoIntoLocalMessage 위치', () {
    test('위도·경도는 서버 값 우선, 없으면 로컬 값 유지', () {
      final localMessage = ChatMessage(
        chatMessageId: 'local_1',
        senderId: 'me',
        type: MessageType.location,
        latitude: 37.1,
        longitude: 127.1,
      );
      final serverMessage = ChatMessage(chatMessageId: 's1', senderId: 'me', type: MessageType.location);

      final merged = mergeServerEchoIntoLocalMessage(localMessage: localMessage, serverMessage: serverMessage);

      expect(merged.latitude, 37.1);
      expect(merged.longitude, 127.1);
    });
  });

  group('buildLocalMessageId', () {
    test('접두어가 붙고 호출마다 다른 ID를 만든다', () {
      final firstId = buildLocalMessageId(prefix: localTradeRequestIdPrefix);
      final secondId = buildLocalMessageId(prefix: localTradeRequestIdPrefix);

      expect(firstId.startsWith(localTradeRequestIdPrefix), isTrue);
      expect(firstId, isNot(secondId));
    });
  });
}
