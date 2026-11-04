import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_appointment_status.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/models/apis/objects/chat_room_detail_dto.dart';
import 'package:romrom_fe/models/apis/responses/chat_response.dart';

void main() {
  group('채팅 확장 필드 파싱 (#1006)', () {
    test('약속 메시지: TEXT + appointment 필드 파싱', () {
      final message = ChatMessage.fromJson({
        'chatMessageId': 'm1',
        'type': 'TEXT',
        'content': '[약속] 11월 6일 (금) 오후 3:00 · 군자역',
        'appointment': {
          'appointmentAt': '2026-11-06T15:00:00',
          'placeName': '군자역',
          'latitude': 37.557,
          'longitude': 127.079,
          'status': 'PROPOSED',
          'statusChangedMemberId': null,
        },
      });

      expect(message.type, MessageType.text);
      expect(message.appointment?.status, ChatAppointmentStatus.proposed);
      expect(message.appointment?.appointmentAt, DateTime(2026, 11, 6, 15));
      expect(message.appointment?.placeName, '군자역');
    });

    test('모르는 약속 상태 값은 예외 없이 null', () {
      final message = ChatMessage.fromJson({
        'chatMessageId': 'm1',
        'type': 'TEXT',
        'appointment': {'status': 'RESCHEDULED'},
      });
      expect(message.appointment, isNotNull);
      expect(message.appointment?.status, isNull);
    });

    test('삭제된 메시지 isDeleted 파싱, 필드 없으면 null', () {
      expect(ChatMessage.fromJson({'type': 'TEXT', 'isDeleted': true}).isDeleted, isTrue);
      expect(ChatMessage.fromJson({'type': 'TEXT'}).isDeleted, isNull);
    });

    test('채팅방 목록 isNotificationMuted·응답 chatMessage 파싱', () {
      expect(ChatRoomDetailDto.fromJson({'chatRoomId': 'r1', 'isNotificationMuted': true}).isNotificationMuted, isTrue);
      final response = ChatRoomResponse.fromJson({
        'isNotificationMuted': false,
        'chatMessage': {'chatMessageId': 'm1', 'type': 'TEXT', 'isDeleted': true},
      });
      expect(response.isNotificationMuted, isFalse);
      expect(response.chatMessage?.isDeleted, isTrue);
    });
  });
}
