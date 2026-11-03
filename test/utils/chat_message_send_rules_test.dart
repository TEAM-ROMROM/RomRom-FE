import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/utils/chat_message_send_rules.dart';

/// 테스트용 메시지 (createdDate: 로컬이면 내 기기 전송 시각, 서버면 서버 시각)
ChatMessage buildMessage(
  String id, {
  String sender = 'me',
  MessageType type = MessageType.text,
  String? content,
  DateTime? createdDate,
  List<String>? imageUrls,
  double? latitude,
  double? longitude,
}) {
  return ChatMessage(
    chatRoomId: 'room1',
    chatMessageId: id,
    senderId: sender,
    type: type,
    content: content,
    createdDate: createdDate,
    imageUrls: imageUrls,
    latitude: latitude,
    longitude: longitude,
  );
}

void main() {
  final sentAt = DateTime(2026, 11, 3, 12);

  group('findMatchingPendingLocalMessageId 시각 기준', () {
    test('로컬 전송 시각 <-> 에코 수신 시각으로 판정 (서버 시각이 크게 달라도 짝지음)', () {
      final pending = {'local_1': buildMessage('local_1', content: '안녕', createdDate: sentAt)};
      // 서버 시계·시간대가 9시간 어긋난 에코
      final echo = buildMessage('s1', content: '안녕', createdDate: sentAt.add(const Duration(hours: 9)));

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: echo,
          myMemberId: 'me',
          receivedAt: sentAt.add(const Duration(seconds: 2)),
        ),
        'local_1',
      );
    });

    test('수신 시각이 전송 후 대기 한도를 넘으면 짝짓지 않음, 상대 메시지·다른 내용도 null', () {
      final pending = {'local_1': buildMessage('local_1', content: '안녕', createdDate: sentAt)};
      final lateReceivedAt = sentAt.add(pendingLocalMessageEchoWindow + const Duration(seconds: 1));

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s1', content: '안녕'),
          myMemberId: 'me',
          receivedAt: lateReceivedAt,
        ),
        isNull,
      );
      for (final incoming in [
        buildMessage('s2', sender: 'other', content: '안녕'),
        buildMessage('s3', content: '다른 말'),
      ]) {
        expect(
          findMatchingPendingLocalMessageId(
            pendingLocalMessages: pending,
            incomingMessage: incoming,
            myMemberId: 'me',
            receivedAt: sentAt,
          ),
          isNull,
        );
      }
    });

    test('같은 내용 대기 메시지가 여럿이면 가장 오래된 것부터', () {
      final pending = {
        'local_1': buildMessage('local_1', content: '네', createdDate: sentAt),
        'local_2': buildMessage('local_2', content: '네', createdDate: sentAt.add(const Duration(seconds: 1))),
      };

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s1', content: '네'),
          myMemberId: 'me',
          receivedAt: sentAt.add(const Duration(seconds: 2)),
        ),
        'local_1',
      );
    });
  });

  group('findMatchingPendingLocalMessageId 사진·위치', () {
    test('사진은 주소 집합이 같은 것과 짝 (A 거부·B 에코 > B와 짝)', () {
      final pending = {
        'local_a': buildMessage('local_a', type: MessageType.image, imageUrls: const ['a1', 'a2'], createdDate: sentAt),
        'local_b': buildMessage('local_b', type: MessageType.image, imageUrls: const ['b1'], createdDate: sentAt),
      };

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s1', type: MessageType.image, imageUrls: const ['b1']),
          myMemberId: 'me',
          receivedAt: sentAt,
        ),
        'local_b',
      );
    });

    test('사진 주소가 다르면 짝짓지 않음', () {
      final pending = {
        'local_a': buildMessage('local_a', type: MessageType.image, imageUrls: const ['a1'], createdDate: sentAt),
      };

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s1', type: MessageType.image, imageUrls: const ['x1']),
          myMemberId: 'me',
          receivedAt: sentAt,
        ),
        isNull,
      );
    });

    test('에코에 사진 주소가 없으면 같은 종류 중 가장 오래된 것과 순서대로 짝', () {
      final pending = {
        'local_a': buildMessage('local_a', type: MessageType.image, imageUrls: const ['a1'], createdDate: sentAt),
        'local_b': buildMessage('local_b', type: MessageType.image, imageUrls: const ['b1'], createdDate: sentAt),
      };

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s1', type: MessageType.image),
          myMemberId: 'me',
          receivedAt: sentAt,
        ),
        'local_a',
      );
    });

    test('위치는 위도·경도가 같은 것과 짝, 다르면 null', () {
      final pending = {
        'local_a': buildMessage(
          'local_a',
          type: MessageType.location,
          latitude: 37.1,
          longitude: 127.1,
          createdDate: sentAt,
        ),
        'local_b': buildMessage(
          'local_b',
          type: MessageType.location,
          latitude: 37.2,
          longitude: 127.2,
          createdDate: sentAt,
        ),
      };

      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s1', type: MessageType.location, latitude: 37.2, longitude: 127.2),
          myMemberId: 'me',
          receivedAt: sentAt,
        ),
        'local_b',
      );
      expect(
        findMatchingPendingLocalMessageId(
          pendingLocalMessages: pending,
          incomingMessage: buildMessage('s2', type: MessageType.location, latitude: 35.0, longitude: 129.0),
          myMemberId: 'me',
          receivedAt: sentAt,
        ),
        isNull,
      );
    });
  });

  group('findPendingLocalIdsConfirmedByServer', () {
    test('서버 목록에 있는 내 메시지와 짝지은 로컬 ID (서버 시각 무관)', () {
      final pending = {
        'local_1': buildMessage('local_1', content: '안녕', createdDate: sentAt),
        'local_2': buildMessage('local_2', content: '못 보냄', createdDate: sentAt),
      };
      final serverMessages = [
        buildMessage('s1', content: '안녕', createdDate: sentAt.add(const Duration(hours: 9))),
        buildMessage('s2', sender: 'other', content: '못 보냄'),
      ];

      expect(
        findPendingLocalIdsConfirmedByServer(
          pendingLocalMessages: pending,
          serverMessages: serverMessages,
          myMemberId: 'me',
          displayedMessageIds: const {},
        ),
        {'local_1'},
      );
    });

    test('이미 화면에 확정·표시된 서버 메시지는 후보에서 제외 (같은 내용 연속 전송 시 실패 메시지 보존)', () {
      // S1 '네'는 이미 확정 표시, L2 '네'는 실패
      final pending = {'local_2': buildMessage('local_2', content: '네', createdDate: sentAt)};
      final serverMessages = [buildMessage('s1', content: '네')];

      expect(
        findPendingLocalIdsConfirmedByServer(
          pendingLocalMessages: pending,
          serverMessages: serverMessages,
          myMemberId: 'me',
          displayedMessageIds: const {'s1'},
        ),
        isEmpty,
      );
    });

    test('서버 메시지 하나는 로컬 메시지 하나와만 짝', () {
      final pending = {
        'local_1': buildMessage('local_1', content: 'ㅋ', createdDate: sentAt),
        'local_2': buildMessage('local_2', content: 'ㅋ', createdDate: sentAt),
      };

      expect(
        findPendingLocalIdsConfirmedByServer(
          pendingLocalMessages: pending,
          serverMessages: [buildMessage('s1', content: 'ㅋ')],
          myMemberId: 'me',
          displayedMessageIds: const {},
        ),
        {'local_1'},
      );
    });
  });

  group('hasPendingTextAwaitingEcho (텍스트 전송 잠금)', () {
    test('실패 아닌 대기 텍스트가 있을 때만 true (사진·위치·실패 텍스트는 잠그지 않음)', () {
      final pending = {
        'local_1': buildMessage('local_1', content: '실패', createdDate: sentAt),
        'local_2': buildMessage('local_2', type: MessageType.image, imageUrls: const ['a']),
      };

      expect(hasPendingTextAwaitingEcho(pendingLocalMessages: pending, failedLocalMessageIds: {'local_1'}), isFalse);
      expect(hasPendingTextAwaitingEcho(pendingLocalMessages: pending, failedLocalMessageIds: {}), isTrue);
    });
  });

  group('resolveIncomingEcho (내 에코 처리 결정)', () {
    test('예전 실패 메시지의 늦은 에코는 그 메시지를 확정하고, 다른 대기 텍스트 잠금은 유지', () {
      final pending = {
        'local_1': buildMessage('local_1', content: '첫째', createdDate: sentAt),
        'local_2': buildMessage('local_2', content: '둘째', createdDate: sentAt.add(const Duration(seconds: 20))),
      };

      final decision = resolveIncomingEcho(
        pendingLocalMessages: pending,
        supersededLocalMessages: const {},
        incomingMessage: buildMessage('s1', content: '첫째'),
        myMemberId: 'me',
        receivedAt: sentAt.add(const Duration(seconds: 25)),
      );
      final remainingPending = Map.of(pending)..remove(decision.confirmedLocalId);

      expect(decision.confirmedLocalId, 'local_1');
      expect(decision.absorbedSupersededLocalId, isNull);
      expect(hasPendingTextAwaitingEcho(pendingLocalMessages: remainingPending, failedLocalMessageIds: {}), isTrue);
    });

    test('다시 보내기로 대체된 원래 메시지의 늦은 에코 > 대기 메시지 없으면 흡수(화면에 추가 안 함)', () {
      final superseded = {'local_old': buildMessage('local_old', content: '네', createdDate: sentAt)};

      final decision = resolveIncomingEcho(
        pendingLocalMessages: const {},
        supersededLocalMessages: superseded,
        incomingMessage: buildMessage('s1', content: '네'),
        myMemberId: 'me',
        receivedAt: sentAt.add(const Duration(seconds: 15)),
      );

      expect(decision.confirmedLocalId, isNull);
      expect(decision.absorbedSupersededLocalId, 'local_old');
    });

    test('대기 메시지와 대체 메시지가 모두 맞으면 대기 메시지 확정이 먼저 (둘 중 하나만 표시)', () {
      final decision = resolveIncomingEcho(
        pendingLocalMessages: {'local_retry': buildMessage('local_retry', content: '네', createdDate: sentAt)},
        supersededLocalMessages: {'local_old': buildMessage('local_old', content: '네', createdDate: sentAt)},
        incomingMessage: buildMessage('s1', content: '네'),
        myMemberId: 'me',
        receivedAt: sentAt,
      );

      expect(decision.confirmedLocalId, 'local_retry');
      expect(decision.absorbedSupersededLocalId, isNull);
    });

    test('어느 것과도 맞지 않으면 새 메시지', () {
      final decision = resolveIncomingEcho(
        pendingLocalMessages: const {},
        supersededLocalMessages: const {},
        incomingMessage: buildMessage('s1', content: '새 글'),
        myMemberId: 'me',
        receivedAt: sentAt,
      );

      expect(decision.confirmedLocalId, isNull);
      expect(decision.absorbedSupersededLocalId, isNull);
    });
  });
}
