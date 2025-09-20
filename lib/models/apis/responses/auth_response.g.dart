// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      isFirstLogin: json['isFirstLogin'] as bool?,
      isFirstItemPosted: json['isFirstItemPosted'] as bool?,
      isItemCategorySaved: json['isItemCategorySaved'] as bool?,
      isMemberLocationSaved: json['isMemberLocationSaved'] as bool?,
      isMarketingInfoAgreed: json['isMarketingInfoAgreed'] as bool?,
      isRequiredTermsAgreed: json['isRequiredTermsAgreed'] as bool?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'isFirstLogin': instance.isFirstLogin,
      'isFirstItemPosted': instance.isFirstItemPosted,
      'isItemCategorySaved': instance.isItemCategorySaved,
      'isMemberLocationSaved': instance.isMemberLocationSaved,
      'isMarketingInfoAgreed': instance.isMarketingInfoAgreed,
      'isRequiredTermsAgreed': instance.isRequiredTermsAgreed,
    };
