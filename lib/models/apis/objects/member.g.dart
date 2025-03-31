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
      isFirstItemPosted: json['isFirstItemPosted'] as bool?,
      isFirstLogin: json['isFirstLogin'] as bool?,
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
      'isFirstItemPosted': instance.isFirstItemPosted,
      'isFirstLogin': instance.isFirstLogin,
    };
