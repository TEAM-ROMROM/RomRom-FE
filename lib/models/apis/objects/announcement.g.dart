// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'announcement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Announcement _$AnnouncementFromJson(Map<String, dynamic> json) => Announcement(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  announcementId: json['announcementId'] as String?,
  title: json['title'] as String?,
  content: json['content'] as String?,
  imageUrl: json['imageUrl'] as String?,
  linkUrl: json['linkUrl'] as String?,
);

Map<String, dynamic> _$AnnouncementToJson(Announcement instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'announcementId': instance.announcementId,
  'title': instance.title,
  'content': instance.content,
  'imageUrl': instance.imageUrl,
  'linkUrl': instance.linkUrl,
};
