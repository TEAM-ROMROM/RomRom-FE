// lib/models/apis/objects/member.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/base_entity.dart';

part 'member.g.dart';

@JsonSerializable()
class Member extends BaseEntity {
  final String? memberId;
  final String? email;
  final String? nickname;
  final String? socialPlatform;
  final String? profileUrl;
  final String? role;
  final String? accountStatus;
  final bool? isFirstLogin;
  final bool? isItemCategorySaved;
  final bool? isFirstItemPosted;
  final bool? isMemberLocationSaved;
  final bool? isRequiredTermsAgreed;
  final bool? isMarketingInfoAgreed;
  final double? latitude;
  final double? longitude;

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
    this.isFirstLogin,
    this.isItemCategorySaved,
    this.isFirstItemPosted,
    this.isMemberLocationSaved,
    this.isRequiredTermsAgreed,
    this.isMarketingInfoAgreed,
    this.latitude,
    this.longitude,
  });

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}
