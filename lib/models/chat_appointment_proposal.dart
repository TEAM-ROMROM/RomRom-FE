import 'package:flutter/foundation.dart';

/// 약속 잡기 시트 입력 결과: 일시·장소 이름, 지도에서 고른 좌표 (선택)
@immutable
class ChatAppointmentProposal {
  final DateTime appointmentAt;
  final String placeName;
  final double? latitude;
  final double? longitude;

  const ChatAppointmentProposal({required this.appointmentAt, required this.placeName, this.latitude, this.longitude});
}
