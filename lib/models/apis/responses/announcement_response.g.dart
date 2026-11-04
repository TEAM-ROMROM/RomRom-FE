// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AnnouncementResponse _$AnnouncementResponseFromJson(Map<String, dynamic> json) => AnnouncementResponse(
  announcement: json['announcement'] == null
      ? null
      : Announcement.fromJson(json['announcement'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AnnouncementResponseToJson(AnnouncementResponse instance) => <String, dynamic>{
  'announcement': instance.announcement?.toJson(),
};
