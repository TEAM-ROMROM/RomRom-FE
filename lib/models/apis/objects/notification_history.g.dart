// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHistory _$NotificationHistoryFromJson(Map<String, dynamic> json) => NotificationHistory(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  notificationHistoryId: json['notificationHistoryId'] as String?,
  member: json['member'] == null ? null : Member.fromJson(json['member'] as Map<String, dynamic>),
  notificationType: json['notificationType'] as String?,
  title: json['title'] as String?,
  body: json['body'] as String?,
  payload: json['payload'] as Map<String, dynamic>?,
  isRead: json['isRead'] as bool?,
  publishedAt: json['publishedAt'] == null ? null : DateTime.parse(json['publishedAt'] as String),
);

Map<String, dynamic> _$NotificationHistoryToJson(NotificationHistory instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'notificationHistoryId': instance.notificationHistoryId,
  'member': instance.member?.toJson(),
  'notificationType': instance.notificationType,
  'title': instance.title,
  'body': instance.body,
  'payload': instance.payload,
  'isRead': instance.isRead,
  'publishedAt': instance.publishedAt?.toIso8601String(),
};
