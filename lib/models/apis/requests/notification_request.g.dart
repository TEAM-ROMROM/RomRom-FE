// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationRequest _$NotificationRequestFromJson(Map<String, dynamic> json) => NotificationRequest(
  fcmToken: json['fcmToken'] as String?,
  deviceType: json['deviceType'] as String?,
  title: json['title'] as String?,
  body: json['body'] as String?,
);

Map<String, dynamic> _$NotificationRequestToJson(NotificationRequest instance) => <String, dynamic>{
  'fcmToken': instance.fcmToken,
  'deviceType': instance.deviceType,
  'title': instance.title,
  'body': instance.body,
};
