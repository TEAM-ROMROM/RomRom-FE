// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
      createdDate: json['createdDate'] == null
          ? null
          : DateTime.parse(json['createdDate'] as String),
      updatedDate: json['updatedDate'] == null
          ? null
          : DateTime.parse(json['updatedDate'] as String),
      memberId: json['memberId'] as String?,
      email: json['email'] as String?,
      nickname: json['nickname'] as String?,
      socialPlatform: json['socialPlatform'] as String?,
      profileUrl: json['profileUrl'] as String?,
      role: json['role'] as String?,
      accountStatus: json['accountStatus'] as String?,
      isFirstLogin: json['isFirstLogin'] as bool?,
      isItemCategorySaved: json['isItemCategorySaved'] as bool?,
      isFirstItemPosted: json['isFirstItemPosted'] as bool?,
      isMemberLocationSaved: json['isMemberLocationSaved'] as bool?,
      isRequiredTermsAgreed: json['isRequiredTermsAgreed'] as bool?,
      isMarketingInfoAgreed: json['isMarketingInfoAgreed'] as bool?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
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
      'isFirstLogin': instance.isFirstLogin,
      'isItemCategorySaved': instance.isItemCategorySaved,
      'isFirstItemPosted': instance.isFirstItemPosted,
      'isMemberLocationSaved': instance.isMemberLocationSaved,
      'isRequiredTermsAgreed': instance.isRequiredTermsAgreed,
      'isMarketingInfoAgreed': instance.isMarketingInfoAgreed,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
