// 채팅 메시지 길게 누르기·약속 카드 판정 순수 함수: 삭제·신고 가능, 약속 수락·취소 버튼, 변경본 교체 (#1006)
import 'package:romrom_fe/enums/chat_appointment_status.dart';
import 'package:romrom_fe/enums/message_type.dart';
import 'package:romrom_fe/models/apis/objects/chat_appointment.dart';
import 'package:romrom_fe/models/apis/objects/chat_message.dart';
import 'package:romrom_fe/utils/chat_room_message_rules.dart';

// 내 메시지 삭제 가능 기간 (서버 규칙과 동일, 보낸 시각 기준)
const Duration myMessageDeletableDuration = Duration(hours: 24);

// 약속 장소 이름 최대 글자 수 (서버 검증과 동일)
const int appointmentPlaceNameMaximumLength = 50;

// 삭제된 메시지 말풍선 문구 (서버 본문 치환 문구와 동일)
const String deletedChatMessagePlaceholder = '삭제된 메시지입니다.';

// 길게 누르기 대상 메시지 타입 3개: 글, 사진, 위치 (시스템·거래 메시지 제외)
const Set<MessageType> _userSendableMessageTypes = {MessageType.text, MessageType.image, MessageType.location};

/// 서버에 저장된 사용자 메시지인지 (ID 있음, 낙관적 로컬 아님, 삭제 아님, 글·사진·위치)
bool _isServerUserMessage(ChatMessage message) {
  final messageId = message.chatMessageId;
  if (messageId == null || isLocalOptimisticMessageId(messageId)) return false;
  if (message.isDeleted == true) return false;
  return _userSendableMessageTypes.contains(message.type);
}

/// 내 메시지 삭제 가능 여부 (내 메시지, 보낸 지 24시간 이내, 약속 메시지 제외 > 약속은 취소로 처리)
bool canDeleteChatMessage({required ChatMessage message, required String? myMemberId, required DateTime now}) {
  if (myMemberId == null || message.senderId != myMemberId) return false;
  if (!_isServerUserMessage(message) || message.appointment != null) return false;
  final sentAt = message.createdDate;
  if (sentAt == null) return false;
  return now.difference(sentAt) < myMessageDeletableDuration;
}

/// 메시지 신고 가능 여부 (상대 메시지, 서버 저장분, 삭제 아님)
bool canReportChatMessage({required ChatMessage message, required String? myMemberId}) {
  if (myMemberId == null || message.senderId == myMemberId) return false;
  return _isServerUserMessage(message);
}

/// 약속 수락 버튼 노출 (제안 받은 사람, 제안 상태, 약속 시각 전)
bool canAcceptAppointment({
  required ChatAppointment appointment,
  required String? proposerMemberId,
  required String? myMemberId,
  required DateTime now,
}) {
  if (myMemberId == null || proposerMemberId == myMemberId) return false;
  if (appointment.status != ChatAppointmentStatus.proposed) return false;
  final appointmentAt = appointment.appointmentAt;
  return appointmentAt != null && appointmentAt.isAfter(now);
}

/// 약속 취소 버튼 노출 (양쪽 모두, 제안·확정 상태)
bool canCancelAppointment({required ChatAppointment appointment}) =>
    appointment.status == ChatAppointmentStatus.proposed || appointment.status == ChatAppointmentStatus.accepted;

/// 변경본 > 같은 ID 메시지 교체 (없으면 null > 호출부가 무시)
List<ChatMessage>? replaceMessageById({required List<ChatMessage> messages, required ChatMessage updatedMessage}) {
  final updatedId = updatedMessage.chatMessageId;
  if (updatedId == null) return null;
  final index = messages.indexWhere((message) => message.chatMessageId == updatedId);
  if (index == -1) return null;
  // 소켓 변경본에 시각이 빠진 경우 기존 시각 유지 (날짜 구분선·순서 보존)
  final mergedMessage = updatedMessage.createdDate == null
      ? updatedMessage.copyWith(createdDate: messages[index].createdDate)
      : updatedMessage;
  return [...messages]..[index] = mergedMessage;
}

/// 약속 제안 입력 검증 (장소 1~50자, 약속 시각이 지금 이후)
bool isAppointmentProposalValid({required DateTime appointmentAt, required String placeName, required DateTime now}) {
  final trimmedPlaceName = placeName.trim();
  if (trimmedPlaceName.isEmpty || trimmedPlaceName.length > appointmentPlaceNameMaximumLength) return false;
  return appointmentAt.isAfter(now);
}
