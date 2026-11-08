// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyword_alert_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeywordAlertResponse _$KeywordAlertResponseFromJson(Map<String, dynamic> json) => KeywordAlertResponse(
  keywordAlerts: (json['keywordAlerts'] as List<dynamic>?)
      ?.map((e) => KeywordAlert.fromJson(e as Map<String, dynamic>))
      .toList(),
  maximumKeywordAlertCount: (json['maximumKeywordAlertCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$KeywordAlertResponseToJson(KeywordAlertResponse instance) => <String, dynamic>{
  'keywordAlerts': instance.keywordAlerts?.map((e) => e.toJson()).toList(),
  'maximumKeywordAlertCount': instance.maximumKeywordAlertCount,
};
