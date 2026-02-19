// lib/models/apis/responses/notification_history_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/notification_history.dart';

part 'notification_history_response.g.dart';

@JsonSerializable(explicitToJson: true)
class NotificationHistoryResponse {
  final NotificationHistory? notificationHistory;

  final NotificationHistoryPage? notificationHistoryPage;

  final int? unReadCount; // 안읽은 알림 개수

  NotificationHistoryResponse({this.notificationHistory, this.notificationHistoryPage, this.unReadCount});

  factory NotificationHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$NotificationHistoryResponseFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationHistoryResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NotificationHistoryPage {
  @JsonKey(fromJson: _int64FromJson)
  final int? totalElements;

  final int? totalPages;
  final bool? last;
  final bool? first;
  final int? numberOfElements;
  final int? size;

  @JsonKey(fromJson: _notificationHistoriesFromJson, toJson: _notificationHistoriesToJson)
  final List<NotificationHistory>? content;

  final int? number;
  final bool? empty;

  NotificationHistoryPage({
    this.totalElements,
    this.totalPages,
    this.last,
    this.first,
    this.numberOfElements,
    this.size,
    this.content,
    this.number,
    this.empty,
  });

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

int _int64FromJson(Object? v) => (v is num) ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? 0);
