// lib/models/apis/objects/notification_history.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';
import 'package:romrom_fe/models/apis/objects/member.dart';

part 'notification_history.g.dart';

@JsonSerializable(explicitToJson: true)
class NotificationHistory extends BaseEntity {
  final String? notificationHistoryId;
  final Member? member;
  final String? notificationType;
  final String? title;
  final String? body;
  final Map<String, dynamic>? payload;
  final bool? isRead;
  final DateTime? publishedAt;

  NotificationHistory({
    super.createdDate,
    super.updatedDate,
    this.notificationHistoryId,
    this.member,
    this.notificationType,
    this.title,
    this.body,
    this.payload,
    this.isRead,
    this.publishedAt,
  });

  factory NotificationHistory.fromJson(Map<String, dynamic> json) => _$NotificationHistoryFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$NotificationHistoryToJson(this);
}
