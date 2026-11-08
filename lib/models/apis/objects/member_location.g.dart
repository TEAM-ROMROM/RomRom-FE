// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberLocation _$MemberLocationFromJson(Map<String, dynamic> json) => MemberLocation(
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
  updatedDate: json['updatedDate'] == null ? null : DateTime.parse(json['updatedDate'] as String),
  memberLocationId: json['memberLocationId'] as String?,
  member: json['member'] as String?,
  longitude: (json['longitude'] as num?)?.toDouble(),
  latitude: (json['latitude'] as num?)?.toDouble(),
  siDo: json['siDo'] as String?,
  siGunGu: json['siGunGu'] as String?,
  eupMyoenDong: json['eupMyoenDong'] as String?,
  ri: json['ri'] as String?,
  isLocationVerified: json['isLocationVerified'] as bool?,
  locationVerifiedAt: json['locationVerifiedAt'] == null ? null : DateTime.parse(json['locationVerifiedAt'] as String),
  locationVerificationMethod: json['locationVerificationMethod'] as String?,
);

Map<String, dynamic> _$MemberLocationToJson(MemberLocation instance) => <String, dynamic>{
  'createdDate': instance.createdDate?.toIso8601String(),
  'updatedDate': instance.updatedDate?.toIso8601String(),
  'memberLocationId': instance.memberLocationId,
  'member': instance.member,
  'longitude': instance.longitude,
  'latitude': instance.latitude,
  'siDo': instance.siDo,
  'siGunGu': instance.siGunGu,
  'eupMyoenDong': instance.eupMyoenDong,
  'ri': instance.ri,
  'isLocationVerified': instance.isLocationVerified,
  'locationVerifiedAt': instance.locationVerifiedAt?.toIso8601String(),
  'locationVerificationMethod': instance.locationVerificationMethod,
};
