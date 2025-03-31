// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberRequest _$MemberRequestFromJson(Map<String, dynamic> json) =>
    MemberRequest(
      member: json['member'] == null
          ? null
          : Member.fromJson(json['member'] as Map<String, dynamic>),
      preferredCategories: (json['preferredCategories'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      siDo: json['siDo'] as String?,
      siGunGu: json['siGunGu'] as String?,
      eupMyoenDong: json['eupMyoenDong'] as String?,
      ri: json['ri'] as String?,
      fullAddress: json['fullAddress'] as String?,
      roadAddress: json['roadAddress'] as String?,
    );

Map<String, dynamic> _$MemberRequestToJson(MemberRequest instance) =>
    <String, dynamic>{
      'member': instance.member?.toJson(),
      'preferredCategories': instance.preferredCategories,
      'longitude': instance.longitude,
      'latitude': instance.latitude,
      'siDo': instance.siDo,
      'siGunGu': instance.siGunGu,
      'eupMyoenDong': instance.eupMyoenDong,
      'ri': instance.ri,
      'fullAddress': instance.fullAddress,
      'roadAddress': instance.roadAddress,
    };
