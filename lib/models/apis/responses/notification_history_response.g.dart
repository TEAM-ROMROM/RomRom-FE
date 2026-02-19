// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHistoryResponse _$NotificationHistoryResponseFromJson(Map<String, dynamic> json) =>
    NotificationHistoryResponse(
      notificationHistory: _notificationHistoriesFromJson(json['notificationHistory']),
      notificationHistoryPage: json['notificationHistoryPage'] == null
          ? null
          : NotificationHistoryPage.fromJson(json['notificationHistoryPage'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NotificationHistoryResponseToJson(NotificationHistoryResponse instance) => <String, dynamic>{
  'notificationHistory': _notificationHistoriesToJson(instance.notificationHistory),
  'notificationHistoryPage': instance.notificationHistoryPage?.toJson(),
};

NotificationHistoryPage _$NotificationHistoryPageFromJson(Map<String, dynamic> json) => NotificationHistoryPage(
  page: json['page'] == null ? null : ApiPage.fromJson(json['page'] as Map<String, dynamic>),
  unReadCount: (json['unReadCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$NotificationHistoryPageToJson(NotificationHistoryPage instance) => <String, dynamic>{
  'page': instance.page?.toJson(),
  'unReadCount': instance.unReadCount,
};
