// lib/models/apis/objects/keyword_alert.dart
import 'package:json_annotation/json_annotation.dart';

part 'keyword_alert.g.dart';

/// 등록한 키워드 알림 1건 (백엔드 MemberKeywordAlert, BE #873): id, 원문 키워드, 등록일
@JsonSerializable()
class KeywordAlert {
  final String? keywordAlertId;
  // 사용자가 입력한 원문 (표시용, 비교는 정규화 값)
  final String? keyword;
  final DateTime? createdDate;

  const KeywordAlert({this.keywordAlertId, this.keyword, this.createdDate});

  factory KeywordAlert.fromJson(Map<String, dynamic> json) => _$KeywordAlertFromJson(json);
  Map<String, dynamic> toJson() => _$KeywordAlertToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordAlert &&
          keywordAlertId == other.keywordAlertId &&
          keyword == other.keyword &&
          createdDate == other.createdDate;

  @override
  int get hashCode => Object.hash(keywordAlertId, keyword, createdDate);

  @override
  String toString() => 'KeywordAlert(keywordAlertId: $keywordAlertId, keyword: $keyword)';
}
