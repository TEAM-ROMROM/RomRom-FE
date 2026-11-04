import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/enums/chat_appointment_status.dart';

part 'chat_appointment.g.dart';

/// 약속 카드 정보 (ChatMessage.appointment, TEXT 메시지에 붙는 추가 필드)
@JsonSerializable()
class ChatAppointment {
  // 약속 일시 (서버 KST LocalDateTime > 기기 로컬 시각)
  final DateTime? appointmentAt;
  final String? placeName;
  final double? latitude;
  final double? longitude;
  // 모르는 상태 값 > null (옛 enum 예외로 목록 조회 실패 방지)
  @JsonKey(unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
  final ChatAppointmentStatus? status;
  // 마지막 상태 변경 회원 (수락·취소한 사람)
  final String? statusChangedMemberId;

  ChatAppointment({
    this.appointmentAt,
    this.placeName,
    this.latitude,
    this.longitude,
    this.status,
    this.statusChangedMemberId,
  });

  factory ChatAppointment.fromJson(Map<String, dynamic> json) => _$ChatAppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$ChatAppointmentToJson(this);
}
