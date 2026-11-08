// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keyword_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KeywordAlert _$KeywordAlertFromJson(Map<String, dynamic> json) => KeywordAlert(
  keywordAlertId: json['keywordAlertId'] as String?,
  keyword: json['keyword'] as String?,
  createdDate: json['createdDate'] == null ? null : DateTime.parse(json['createdDate'] as String),
);

Map<String, dynamic> _$KeywordAlertToJson(KeywordAlert instance) => <String, dynamic>{
  'keywordAlertId': instance.keywordAlertId,
  'keyword': instance.keyword,
  'createdDate': instance.createdDate?.toIso8601String(),
};
