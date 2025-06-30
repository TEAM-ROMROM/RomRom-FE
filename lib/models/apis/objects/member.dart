// lib/models/apis/objects/member.dart
import 'package:json_annotation/json_annotation.dart';

part 'member.g.dart';

@JsonSerializable()
class Member {
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

  Member({
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
  });

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}