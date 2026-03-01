// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  memberId: json['memberId'] as String?,
  email: json['email'] as String?,
  nickname: json['nickname'] as String?,
  socialPlatform: json['socialPlatform'] as String?,
  profileUrl: json['profileUrl'] as String?,
  role: json['role'] as String?,
  accountStatus: json['accountStatus'] as String?,
  lastActiveAt: json['lastActiveAt'] == null ? null : DateTime.parse(json['lastActiveAt'] as String),
  isFirstLogin: json['isFirstLogin'] as bool?,
  isItemCategorySaved: json['isItemCategorySaved'] as bool?,
  isFirstItemPosted: json['isFirstItemPosted'] as bool?,
  isMemberLocationSaved: json['isMemberLocationSaved'] as bool?,
  isRequiredTermsAgreed: json['isRequiredTermsAgreed'] as bool?,
  isMarketingInfoAgreed: json['isMarketingInfoAgreed'] as bool?,
  isActivityNotificationAgreed: json['isActivityNotificationAgreed'] as bool?,
  isChatNotificationAgreed: json['isChatNotificationAgreed'] as bool?,
  isContentNotificationAgreed: json['isContentNotificationAgreed'] as bool?,
  isTradeNotificationAgreed: json['isTradeNotificationAgreed'] as bool?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  totalLikeCount: (json['totalLikeCount'] as num?)?.toInt(),
  searchRadiusInMeters: (json['searchRadiusInMeters'] as num?)?.toDouble(),
  isBlocked: json['isBlocked'] as bool?,
  locationAddress: json['locationAddress'] as String?,
  isOnline: json['isOnline'] as bool?,
);

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'memberId': instance.memberId,
  'email': instance.email,
  'nickname': instance.nickname,
  'socialPlatform': instance.socialPlatform,
  'profileUrl': instance.profileUrl,
  'role': instance.role,
  'accountStatus': instance.accountStatus,
  'lastActiveAt': instance.lastActiveAt?.toIso8601String(),
  'isFirstLogin': instance.isFirstLogin,
  'isItemCategorySaved': instance.isItemCategorySaved,
  'isFirstItemPosted': instance.isFirstItemPosted,
  'isMemberLocationSaved': instance.isMemberLocationSaved,
  'isRequiredTermsAgreed': instance.isRequiredTermsAgreed,
  'isMarketingInfoAgreed': instance.isMarketingInfoAgreed,
  'isActivityNotificationAgreed': instance.isActivityNotificationAgreed,
  'isChatNotificationAgreed': instance.isChatNotificationAgreed,
  'isContentNotificationAgreed': instance.isContentNotificationAgreed,
  'isTradeNotificationAgreed': instance.isTradeNotificationAgreed,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'totalLikeCount': instance.totalLikeCount,
  'searchRadiusInMeters': instance.searchRadiusInMeters,
  'isOnline': instance.isOnline,
  'isBlocked': instance.isBlocked,
  'locationAddress': instance.locationAddress,
};
