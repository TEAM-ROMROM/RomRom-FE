import 'package:romrom_fe/models/apis/responses/keyword_alert_response.dart';
import 'package:romrom_fe/services/apis/keyword_alert_api.dart';

/// 키워드 알림 저장소: 목록 조회, 등록, 삭제 (KeywordAlertApi 래핑, 응답 = 변경 후 최신 목록)
class KeywordAlertRepository {
  final KeywordAlertApi _api;

  KeywordAlertRepository(this._api);

  Future<KeywordAlertResponse> getKeywordAlerts() => _api.getKeywordAlerts();

  Future<KeywordAlertResponse> registerKeywordAlert(String keyword) => _api.postKeywordAlert(keyword);

  Future<KeywordAlertResponse> deleteKeywordAlert(String keywordAlertId) => _api.deleteKeywordAlert(keywordAlertId);
}
