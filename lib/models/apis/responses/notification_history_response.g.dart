// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationHistoryResponse _$NotificationHistoryResponseFromJson(Map<String, dynamic> json) =>
    NotificationHistoryResponse(
      notificationHistory: json['notificationHistory'] == null
          ? null
          : NotificationHistory.fromJson(json['notificationHistory'] as Map<String, dynamic>),
      notificationHistoryPage: json['notificationHistoryPage'] == null
          ? null
          : NotificationHistoryPage.fromJson(json['notificationHistoryPage'] as Map<String, dynamic>),
      unReadCount: (json['unReadCount'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NotificationHistoryResponseToJson(NotificationHistoryResponse instance) => <String, dynamic>{
  'notificationHistory': instance.notificationHistory?.toJson(),
  'notificationHistoryPage': instance.notificationHistoryPage?.toJson(),
  'unReadCount': instance.unReadCount,
};

NotificationHistoryPage _$NotificationHistoryPageFromJson(Map<String, dynamic> json) => NotificationHistoryPage(
  totalElements: _int64FromJson(json['totalElements']),
  totalPages: (json['totalPages'] as num?)?.toInt(),
  last: json['last'] as bool?,
  first: json['first'] as bool?,
  numberOfElements: (json['numberOfElements'] as num?)?.toInt(),
  size: (json['size'] as num?)?.toInt(),
  content: _notificationHistoriesFromJson(json['content']),
  number: (json['number'] as num?)?.toInt(),
  empty: json['empty'] as bool?,
);

Map<String, dynamic> _$NotificationHistoryPageToJson(NotificationHistoryPage instance) => <String, dynamic>{
  'totalElements': instance.totalElements,
  'totalPages': instance.totalPages,
  'last': instance.last,
  'first': instance.first,
  'numberOfElements': instance.numberOfElements,
  'size': instance.size,
  'content': _notificationHistoriesToJson(instance.content),
  'number': instance.number,
  'empty': instance.empty,
};
