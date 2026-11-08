// lib/models/apis/responses/keyword_alert_response.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';

part 'keyword_alert_response.g.dart';

/// 키워드 알림 목록 응답 (조회·등록·삭제 공통 `POST /api/members/keyword-alert/*`): 최신 등록순 목록, 최대 개수
@JsonSerializable(explicitToJson: true)
class KeywordAlertResponse {
  final List<KeywordAlert>? keywordAlerts;
  final int? maximumKeywordAlertCount;

  KeywordAlertResponse({this.keywordAlerts, this.maximumKeywordAlertCount});

  factory KeywordAlertResponse.fromJson(Map<String, dynamic> json) => _$KeywordAlertResponseFromJson(json);
  Map<String, dynamic> toJson() => _$KeywordAlertResponseToJson(this);
}
