import 'package:json_annotation/json_annotation.dart';

/// 약속 카드 상태 (백엔드 ChatAppointmentStatus, 모르는 값 > null로 파싱)
enum ChatAppointmentStatus {
  @JsonValue('PROPOSED')
  proposed(label: '약속 제안'),
  @JsonValue('ACCEPTED')
  accepted(label: '약속 확정'),
  @JsonValue('CANCELED')
  canceled(label: '약속 취소');

  // 카드 머리글 문구
  final String label;

  const ChatAppointmentStatus({required this.label});
}
