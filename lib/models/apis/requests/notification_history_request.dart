// lib/models/apis/requests/notification_history_request.dart
import 'package:json_annotation/json_annotation.dart';

part 'notification_history_request.g.dart';

@JsonSerializable()
class NotificationHistoryRequest {
  String? notificationHistoryId;
  String? notificationType;
  String? title;
  String? body;
  Map<String, dynamic>? payload;
  DateTime? publishedAt;
  int pageNumber;
  int pageSize;

  NotificationHistoryRequest({
    this.notificationHistoryId,
    this.notificationType,
    this.title,
    this.body,
    this.payload,
    this.publishedAt,
    this.pageNumber = 0,
    this.pageSize = 10,
  });

  factory NotificationHistoryRequest.fromJson(Map<String, dynamic> json) => _$NotificationHistoryRequestFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationHistoryRequestToJson(this);
}
