import 'package:flutter/foundation.dart';
import 'package:romrom_fe/models/apis/objects/keyword_alert.dart';
import 'package:romrom_fe/models/apis/responses/keyword_alert_response.dart';
import 'package:romrom_fe/utils/keyword_alert_rules.dart';

/// 키워드 알림 상태: 등록 목록(최신 등록순), 최대 개수 (#1020)
@immutable
class KeywordAlertsState {
  final List<KeywordAlert> keywordAlerts;
  final int maximumKeywordAlertCount;

  const KeywordAlertsState({
    this.keywordAlerts = const [],
    this.maximumKeywordAlertCount = defaultMaximumKeywordAlertCount,
  });

  /// 서버 응답 > 상태 (목록 없음 > 빈 목록, 최대 개수 없음 > 기본값)
  factory KeywordAlertsState.fromResponse(KeywordAlertResponse response) => KeywordAlertsState(
    keywordAlerts: List.unmodifiable(response.keywordAlerts ?? const <KeywordAlert>[]),
    maximumKeywordAlertCount: response.maximumKeywordAlertCount ?? defaultMaximumKeywordAlertCount,
  );

  int get registeredCount => keywordAlerts.length;

  bool get hasReachedLimit => registeredCount >= maximumKeywordAlertCount;

  /// 원문 키워드 목록 (키워드 없는 항목 제외)
  List<String> get registeredKeywords => keywordAlerts.map((alert) => alert.keyword).whereType<String>().toList();

  /// 정규화 값이 같은 등록 키워드 (없으면 null)
  KeywordAlert? findByKeyword(String keyword) =>
      keywordAlerts.where((alert) => alert.keyword != null && isSameKeywordAlert(alert.keyword!, keyword)).firstOrNull;

  bool isKeywordRegistered(String keyword) => findByKeyword(keyword) != null;

  KeywordAlertsState copyWith({List<KeywordAlert>? keywordAlerts, int? maximumKeywordAlertCount}) => KeywordAlertsState(
    keywordAlerts: keywordAlerts ?? this.keywordAlerts,
    maximumKeywordAlertCount: maximumKeywordAlertCount ?? this.maximumKeywordAlertCount,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KeywordAlertsState &&
          listEquals(keywordAlerts, other.keywordAlerts) &&
          maximumKeywordAlertCount == other.maximumKeywordAlertCount;

  @override
  int get hashCode => Object.hash(Object.hashAll(keywordAlerts), maximumKeywordAlertCount);

  @override
  String toString() =>
      'KeywordAlertsState(keywordAlerts: ${keywordAlerts.length}, maximumKeywordAlertCount: $maximumKeywordAlertCount)';
}
