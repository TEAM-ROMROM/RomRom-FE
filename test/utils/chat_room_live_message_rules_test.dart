import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/utils/chat_room_live_message_rules.dart';

ChatMessage buildLiveMessage(String? id, {String sender = 'other', MessageType type = MessageType.text}) =>
    ChatMessage(chatRoomId: 'room1', chatMessageId: id, senderId: sender, type: type);

/// 채팅방 실시간 수신 판정: 조회 중 보관분 병합, 내 나가기 이벤트, 자동 스크롤 (#984)
void main() {
  group('findUnseenLiveMessages (진입 조회 중 수신분 병합)', () {
    test('조회 결과에 있는 ID는 제외, 없는 것만 도착 순서대로', () {
      final unseen = findUnseenLiveMessages(
        liveMessages: [buildLiveMessage('m2'), buildLiveMessage('m3'), buildLiveMessage('m4')],
        displayedMessages: [buildLiveMessage('m2'), buildLiveMessage('m1')],
      );

      expect(unseen.map((message) => message.chatMessageId), ['m3', 'm4']);
    });

    test('보관분 안 같은 ID 중복은 1개만, ID 없는 메시지는 유지', () {
      final unseen = findUnseenLiveMessages(
        liveMessages: [buildLiveMessage('m3'), buildLiveMessage('m3'), buildLiveMessage(null)],
        displayedMessages: const [],
      );

      expect(unseen.map((message) => message.chatMessageId), ['m3', null]);
    });
  });

  group('isOwnLeaveMessage (방 삭제 시 내 나가기 방송)', () {
    test('내가 보낸 system 메시지만 true', () {
      expect(
        isOwnLeaveMessage(
          message: buildLiveMessage('s1', sender: 'me', type: MessageType.system),
          myMemberId: 'me',
        ),
        isTrue,
      );
      expect(
        isOwnLeaveMessage(
          message: buildLiveMessage('s2', type: MessageType.system),
          myMemberId: 'me',
        ),
        isFalse,
      );
      expect(
        isOwnLeaveMessage(
          message: buildLiveMessage('t1', sender: 'me'),
          myMemberId: 'me',
        ),
        isFalse,
      );
    });

    test('내 ID 모름 > false (상대 퇴장 안내 유지)', () {
      expect(
        isOwnLeaveMessage(
          message: buildLiveMessage('s1', sender: 'me', type: MessageType.system),
          myMemberId: null,
        ),
        isFalse,
      );
    });
  });

  group('shouldAutoScrollOnIncomingMessage', () {
    test('맨 아래 근처 > 상대 메시지도 스크롤', () {
      expect(shouldAutoScrollOnIncomingMessage(isMyMessage: false, distanceFromBottomPixels: 0), isTrue);
      expect(
        shouldAutoScrollOnIncomingMessage(
          isMyMessage: false,
          distanceFromBottomPixels: nearBottomAutoScrollThresholdPixels,
        ),
        isTrue,
      );
    });

    test('이전 메시지 읽는 중 > 상대 메시지는 위치 유지, 내 메시지는 스크롤', () {
      const readingHistoryDistancePixels = nearBottomAutoScrollThresholdPixels + 1;
      expect(
        shouldAutoScrollOnIncomingMessage(isMyMessage: false, distanceFromBottomPixels: readingHistoryDistancePixels),
        isFalse,
      );
      expect(
        shouldAutoScrollOnIncomingMessage(isMyMessage: true, distanceFromBottomPixels: readingHistoryDistancePixels),
        isTrue,
      );
    });
  });

  group('새 메시지 알림 (#987)', () {
    test('isNearBottom > 자동 스크롤과 같은 기준 (기준 거리까지 근처, 넘으면 멀어짐)', () {
      expect(isNearBottom(distanceFromBottomPixels: nearBottomAutoScrollThresholdPixels), isTrue);
      expect(isNearBottom(distanceFromBottomPixels: nearBottomAutoScrollThresholdPixels + 1), isFalse);
    });

    test('countUnseenIncomingMessages > 자동 스크롤 안 된 상대 메시지만 +1', () {
      expect(countUnseenIncomingMessages(currentCount: 2, isMyMessage: false, isAutoScrolled: false), 3);
      expect(
        countUnseenIncomingMessages(currentCount: 2, isMyMessage: false, isAutoScrolled: true),
        2,
        reason: '맨 아래 근처에서 받아 따라 내려간 메시지',
      );
      expect(countUnseenIncomingMessages(currentCount: 2, isMyMessage: true, isAutoScrolled: true), 2);
    });

    test('formatNewMessageCountLabel > 개수 표시, 99 초과는 99+', () {
      expect(formatNewMessageCountLabel(3), '새 메시지 3');
      expect(formatNewMessageCountLabel(maximumDisplayedNewMessageCount), '새 메시지 99');
      expect(formatNewMessageCountLabel(maximumDisplayedNewMessageCount + 1), '새 메시지 99+');
    });
  });
}
