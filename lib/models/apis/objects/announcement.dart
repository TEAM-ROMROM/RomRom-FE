// lib/models/apis/objects/announcement.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'announcement.g.dart';

/// 공지사항 (백엔드 Announcement 엔티티, BE #861): 제목·본문·작성일, 선택 이미지·링크
@JsonSerializable()
class Announcement extends BaseEntity {
  final String? announcementId;
  final String? title;
  final String? content;
  final String? imageUrl;
  // 외부 https:// 또는 앱 내부 romrom:// 딥링크
  final String? linkUrl;

  Announcement({
    super.createdDate,
    super.updatedDate,
    this.announcementId,
    this.title,
    this.content,
    this.imageUrl,
    this.linkUrl,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => _$AnnouncementFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AnnouncementToJson(this);
}
