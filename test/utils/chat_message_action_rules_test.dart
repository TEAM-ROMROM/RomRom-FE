import 'package:flutter_test/flutter_test.dart';
import 'package:romrom_fe/enums/chat_appointment_status.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_appointment.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/utils/chat_message_action_rules.dart';
import 'package:romrom_fe/utils/date_time_display_utils.dart';

void main() {
  final now = DateTime(2026, 11, 5, 12);
  const myMemberId = 'me';
  const opponentMemberId = 'opponent';

  ChatMessage buildMessage({
    String? chatMessageId = 'message-1',
    String senderId = myMemberId,
    MessageType type = MessageType.text,
    DateTime? createdDate,
    bool? isDeleted,
    ChatAppointment? appointment,
  }) => ChatMessage(
    chatMessageId: chatMessageId,
    senderId: senderId,
    type: type,
    createdDate: createdDate ?? now.subtract(const Duration(hours: 1)),
    content: '안녕하세요',
    isDeleted: isDeleted,
    appointment: appointment,
  );

  group('canDeleteChatMessage', () {
    test('내 글·사진·위치 메시지는 24시간 안이면 삭제 가능', () {
      for (final type in [MessageType.text, MessageType.image, MessageType.location]) {
        expect(
          canDeleteChatMessage(
            message: buildMessage(type: type),
            myMemberId: myMemberId,
            now: now,
          ),
          isTrue,
        );
      }
    });

    test('24시간이 지나면 삭제 불가', () {
      final oldMessage = buildMessage(createdDate: now.subtract(myMessageDeletableDuration));
      expect(canDeleteChatMessage(message: oldMessage, myMemberId: myMemberId, now: now), isFalse);
    });

    test('상대 메시지·삭제된 메시지·약속 메시지·시스템 메시지·로컬 메시지는 삭제 불가', () {
      final notDeletableMessages = [
        buildMessage(senderId: opponentMemberId),
        buildMessage(isDeleted: true),
        buildMessage(appointment: ChatAppointment(status: ChatAppointmentStatus.proposed)),
        buildMessage(type: MessageType.system),
        buildMessage(type: MessageType.tradeCompleteRequest),
        buildMessage(chatMessageId: 'local_1'),
        buildMessage(chatMessageId: null),
      ];
      for (final message in notDeletableMessages) {
        expect(canDeleteChatMessage(message: message, myMemberId: myMemberId, now: now), isFalse);
      }
    });
  });

  group('canReportChatMessage', () {
    test('상대 메시지만 신고 가능 (삭제된 메시지 제외)', () {
      expect(
        canReportChatMessage(
          message: buildMessage(senderId: opponentMemberId),
          myMemberId: myMemberId,
        ),
        isTrue,
      );
      expect(canReportChatMessage(message: buildMessage(), myMemberId: myMemberId), isFalse);
      expect(
        canReportChatMessage(
          message: buildMessage(senderId: opponentMemberId, isDeleted: true),
          myMemberId: myMemberId,
        ),
        isFalse,
      );
    });
  });

  group('약속 버튼 노출', () {
    final future = now.add(const Duration(days: 1));

    test('수락: 제안 받은 사람 + 제안 상태 + 약속 시각 전', () {
      final proposed = ChatAppointment(status: ChatAppointmentStatus.proposed, appointmentAt: future);
      expect(
        canAcceptAppointment(
          appointment: proposed,
          proposerMemberId: opponentMemberId,
          myMemberId: myMemberId,
          now: now,
        ),
        isTrue,
      );
      expect(
        canAcceptAppointment(appointment: proposed, proposerMemberId: myMemberId, myMemberId: myMemberId, now: now),
        isFalse,
      );
      final past = ChatAppointment(
        status: ChatAppointmentStatus.proposed,
        appointmentAt: now.subtract(const Duration(minutes: 1)),
      );
      expect(
        canAcceptAppointment(appointment: past, proposerMemberId: opponentMemberId, myMemberId: myMemberId, now: now),
        isFalse,
      );
      final accepted = ChatAppointment(status: ChatAppointmentStatus.accepted, appointmentAt: future);
      expect(
        canAcceptAppointment(
          appointment: accepted,
          proposerMemberId: opponentMemberId,
          myMemberId: myMemberId,
          now: now,
        ),
        isFalse,
      );
    });

    test('취소: 제안·확정 상태만 (취소됨·모르는 상태 > 숨김)', () {
      expect(canCancelAppointment(appointment: ChatAppointment(status: ChatAppointmentStatus.proposed)), isTrue);
      expect(canCancelAppointment(appointment: ChatAppointment(status: ChatAppointmentStatus.accepted)), isTrue);
      expect(canCancelAppointment(appointment: ChatAppointment(status: ChatAppointmentStatus.canceled)), isFalse);
      expect(canCancelAppointment(appointment: ChatAppointment()), isFalse);
    });
  });

  group('replaceMessageById', () {
    test('같은 ID 메시지를 변경본으로 교체, 시각 없는 변경본은 기존 시각 유지', () {
      final original = buildMessage(chatMessageId: 'a');
      final other = buildMessage(chatMessageId: 'b');
      final updated = ChatMessage(chatMessageId: 'a', content: deletedChatMessagePlaceholder, isDeleted: true);

      final replaced = replaceMessageById(messages: [original, other], updatedMessage: updated)!;

      expect(replaced.first.isDeleted, isTrue);
      expect(replaced.first.content, deletedChatMessagePlaceholder);
      expect(replaced.first.createdDate, original.createdDate);
      expect(replaced.last, same(other));
    });

    test('목록에 없는 ID·ID 없는 변경본 > null', () {
      final messages = [buildMessage(chatMessageId: 'a')];
      expect(
        replaceMessageById(
          messages: messages,
          updatedMessage: ChatMessage(chatMessageId: 'z'),
        ),
        isNull,
      );
      expect(replaceMessageById(messages: messages, updatedMessage: ChatMessage()), isNull);
    });
  });

  group('약속 입력 검증·표시', () {
    test('장소 1~50자 + 지금 이후만 유효', () {
      final future = now.add(const Duration(hours: 1));
      expect(isAppointmentProposalValid(appointmentAt: future, placeName: '군자역', now: now), isTrue);
      expect(isAppointmentProposalValid(appointmentAt: future, placeName: '   ', now: now), isFalse);
      expect(isAppointmentProposalValid(appointmentAt: future, placeName: '가' * 51, now: now), isFalse);
      expect(isAppointmentProposalValid(appointmentAt: now, placeName: '군자역', now: now), isFalse);
    });

    test('약속 일시 문구·서버 전송 문자열', () {
      final appointmentAt = DateTime(2026, 11, 6, 15);
      expect(formatAppointmentDateTime(appointmentAt), '11월 6일 (금) 오후 3:00');
      expect(formatServerLocalDateTime(appointmentAt), '2026-11-06T15:00:00');
    });
  });
}
