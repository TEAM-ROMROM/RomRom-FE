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
  final DateTime? lastActiveAt;
  final bool? isFirstLogin;
  final bool? isItemCategorySaved;
  final bool? isFirstItemPosted;
  final bool? isMemberLocationSaved;
  final bool? isRequiredTermsAgreed;
  final bool? isMarketingInfoAgreed;
  final bool? isActivityNotificationAgreed;
  final bool? isChatNotificationAgreed;
  final bool? isContentNotificationAgreed;
  final bool? isTradeNotificationAgreed;
  final double? latitude;
  final double? longitude;
  final int? totalLikeCount;
  final double? searchRadiusInMeters;
  final bool? isOnline;

  /// 해당 회원이 차단된 상태인지 여부 (타인 프로필 조회 시)
  final bool? isBlocked;

  /// 위치 주소 문자열 (예: "서울특별시 광진구 화양동")
  final String? locationAddress;

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
    this.lastActiveAt,
    this.isFirstLogin,
    this.isItemCategorySaved,
    this.isFirstItemPosted,
    this.isMemberLocationSaved,
    this.isRequiredTermsAgreed,
    this.isMarketingInfoAgreed,
    this.isActivityNotificationAgreed,
    this.isChatNotificationAgreed,
    this.isContentNotificationAgreed,
    this.isTradeNotificationAgreed,
    this.latitude,
    this.longitude,
    this.totalLikeCount,
    this.searchRadiusInMeters,
    this.isBlocked,
    this.locationAddress,
    this.isOnline,
  });

  factory Member.fromJson(Map<String, dynamic> json) => _$MemberFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MemberToJson(this);
}
