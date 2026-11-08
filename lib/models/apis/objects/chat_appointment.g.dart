// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatAppointment _$ChatAppointmentFromJson(Map<String, dynamic> json) => ChatAppointment(
  appointmentAt: json['appointmentAt'] == null ? null : DateTime.parse(json['appointmentAt'] as String),
  placeName: json['placeName'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  status: $enumDecodeNullable(
    _$ChatAppointmentStatusEnumMap,
    json['status'],
    unknownValue: JsonKey.nullForUndefinedEnumValue,
  ),
  statusChangedMemberId: json['statusChangedMemberId'] as String?,
);

Map<String, dynamic> _$ChatAppointmentToJson(ChatAppointment instance) => <String, dynamic>{
  'appointmentAt': instance.appointmentAt?.toIso8601String(),
  'placeName': instance.placeName,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'status': _$ChatAppointmentStatusEnumMap[instance.status],
  'statusChangedMemberId': instance.statusChangedMemberId,
};

const _$ChatAppointmentStatusEnumMap = {
  ChatAppointmentStatus.proposed: 'PROPOSED',
  ChatAppointmentStatus.accepted: 'ACCEPTED',
  ChatAppointmentStatus.canceled: 'CANCELED',
};
