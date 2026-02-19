// lib/models/apis/responses/notification_history_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/api_page.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';

part 'notification_history_response.g.dart';

@JsonSerializable(explicitToJson: true)
class NotificationHistoryResponse {
  @JsonKey(fromJson: _notificationHistoriesFromJson, toJson: _notificationHistoriesToJson)
  final List<NotificationHistory>? notificationHistory;

  final NotificationHistoryPage? notificationHistoryPage;

  NotificationHistoryResponse({this.notificationHistory, this.notificationHistoryPage});

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationHistoryResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NotificationHistoryPage {
  final ApiPage? page;
  final int? unReadCount;

  NotificationHistoryPage({this.page, this.unReadCount});

  factory NotificationHistoryPage.fromJson(Map<String, dynamic> json) => _$NotificationHistoryPageFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationHistoryPageToJson(this);
}

// ----- 안전 파서 -----
List<NotificationHistory> _notificationHistoriesFromJson(Object? value) {
  if (value is List) {
    return value.whereType<Map<String, dynamic>>().map(NotificationHistory.fromJson).toList();
  }
  return const <NotificationHistory>[];
}

Object _notificationHistoriesToJson(List<NotificationHistory>? histories) =>
    histories?.map((e) => e.toJson()).toList() ?? [];
