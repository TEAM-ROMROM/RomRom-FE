// lib/models/apis/requests/notification_request.dart
import 'package:json_annotation/json_annotation.dart';

part 'notification_request.g.dart';

@JsonSerializable()
class NotificationRequest {
  String? fcmToken;
  String? deviceType;
  String? title;
  String? body;

  NotificationRequest({this.fcmToken, this.deviceType, this.title, this.body});

  factory NotificationRequest.fromJson(Map<String, dynamic> json) => _$NotificationRequestFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationRequestToJson(this);
}
