import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';
import 'package:romrom_fe/utils/chat_room_unread_rules.dart';

ChatMessage buildMessage(String id, {String sender = 'other'}) =>
    ChatMessage(chatRoomId: 'room1', chatMessageId: id, senderId: sender);

/// 진입 시 안 읽은 첫 메시지 판정 (#987): 최신부터 상대 메시지 N번째, 못 찾으면 이전 페이지 한도까지
void main() {
  group('findFirstUnreadMessageId', () {
    // reverse 목록 (index 0 = 최신)
    final messages = [
      buildMessage('m6'),
      buildMessage('m5', sender: 'me'),
      buildMessage('m4'),
      buildMessage('m3'),
      buildMessage('m2', sender: 'me'),
      buildMessage('m1'),
    ];

    test('안 읽음 3 > 내 메시지 건너뛰고 상대 메시지 3번째가 첫 안 읽음', () {
      expect(findFirstUnreadMessageId(messages: messages, myMemberId: 'me', unreadCount: 3), 'm3');
    });

    test('안 읽음 1 > 가장 최신 상대 메시지', () {
      expect(findFirstUnreadMessageId(messages: messages, myMemberId: 'me', unreadCount: 1), 'm6');
    });

    test('안 읽음 0·회원 ID 없음 > 구분선 없음', () {
      expect(findFirstUnreadMessageId(messages: messages, myMemberId: 'me', unreadCount: 0), isNull);
      expect(findFirstUnreadMessageId(messages: messages, myMemberId: null, unreadCount: 2), isNull);
    });

    test('불러온 범위의 상대 메시지보다 안 읽음이 많음 > null (이전 페이지 조회 대상)', () {
      expect(findFirstUnreadMessageId(messages: messages, myMemberId: 'me', unreadCount: 5), isNull);
    });

    test('서버 확인 전 로컬 메시지는 계산 제외', () {
      final withLocalMessage = [buildMessage('${localMessageIdPrefix}1', sender: 'other'), ...messages];
      expect(findFirstUnreadMessageId(messages: withLocalMessage, myMemberId: 'me', unreadCount: 1), 'm6');
    });
  });

  group('shouldLoadOlderPageForUnread', () {
    test('못 찾음·남은 페이지·한도 안 > 더 불러옴', () {
      expect(
        shouldLoadOlderPageForUnread(
          isFirstUnreadFound: false,
          unreadCount: 80,
          hasMoreOlderMessages: true,
          loadedOlderPageCount: 0,
        ),
        isTrue,
      );
    });

    test('찾음·끝 페이지·한도 도달 > 중단 (맨 아래로)', () {
      expect(
        shouldLoadOlderPageForUnread(
          isFirstUnreadFound: true,
          unreadCount: 80,
          hasMoreOlderMessages: true,
          loadedOlderPageCount: 0,
        ),
        isFalse,
      );
      expect(
        shouldLoadOlderPageForUnread(
          isFirstUnreadFound: false,
          unreadCount: 80,
          hasMoreOlderMessages: false,
          loadedOlderPageCount: 0,
        ),
        isFalse,
      );
      expect(
        shouldLoadOlderPageForUnread(
          isFirstUnreadFound: false,
          unreadCount: 500,
          hasMoreOlderMessages: true,
          loadedOlderPageCount: maximumUnreadSearchOlderPageCount,
        ),
        isFalse,
      );
    });
  });

  test('findUnreadCountOfRoom > 목록에 있으면 그 방 안 읽음 수, 없으면 null', () {
    final rooms = [
      ChatRoomDetailDto(chatRoomId: 'room1', unreadCount: 4),
      ChatRoomDetailDto(chatRoomId: 'room2', unreadCount: 0),
    ];
    expect(findUnreadCountOfRoom(rooms: rooms, chatRoomId: 'room1'), 4);
    expect(findUnreadCountOfRoom(rooms: rooms, chatRoomId: 'room-unknown'), isNull);
  });
}
