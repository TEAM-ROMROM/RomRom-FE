// lib/models/apis/responses/announcement_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/announcement.dart';

part 'announcement_response.g.dart';

/// 공지 상세 응답 (`POST /api/notification/get/announcement`)
@JsonSerializable(explicitToJson: true)
class AnnouncementResponse {
  final Announcement? announcement;

  AnnouncementResponse({this.announcement});

  factory AnnouncementResponse.fromJson(Map<String, dynamic> json) => _$AnnouncementResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AnnouncementResponseToJson(this);
}
