// lib/models/apis/objects/member.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'member.g.dart';

@JsonSerializable(explicitToJson: true)
class Member extends BaseEntity {
  final String? memberId;
  final String? email;
  final String? nickname;
  final String? socialPlatform;
  final String? profileUrl;
  final String? role;
  final String? accountStatus;
  final bool? isFirstItemPosted;
  final bool? isFirstLogin;

  Member({
    super.createdDate,
    super.updatedDate,
    this.memberId,
    this.email,
    this.nickname,
    this.socialPlatform,
    this.profileUrl,
    this.role,
    this.accountStatus,
    this.isFirstItemPosted,
    this.isFirstLogin,
  });

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}