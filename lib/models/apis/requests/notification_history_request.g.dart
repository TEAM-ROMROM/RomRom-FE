// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHistoryRequest _$NotificationHistoryRequestFromJson(Map<String, dynamic> json) =>
    NotificationHistoryRequest(
      notificationHistoryId: json['notificationHistoryId'] as String?,
      notificationType: json['notificationType'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
      publishedAt: json['publishedAt'] == null ? null : DateTime.parse(json['publishedAt'] as String),
      pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );

Map<String, dynamic> _$NotificationHistoryRequestToJson(NotificationHistoryRequest instance) => <String, dynamic>{
  'notificationHistoryId': instance.notificationHistoryId,
  'notificationType': instance.notificationType,
  'title': instance.title,
  'body': instance.body,
  'payload': instance.payload,
  'publishedAt': instance.publishedAt?.toIso8601String(),
  'pageNumber': instance.pageNumber,
  'pageSize': instance.pageSize,
};
