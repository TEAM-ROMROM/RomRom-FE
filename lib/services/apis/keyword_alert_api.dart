// lib/services/apis/keyword_alert_api.dart
import 'package:flutter/material.dart';
import 'package:romrom_fe/models/apis/responses/keyword_alert_response.dart';
import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

/// 키워드 알림 API: 목록 조회, 등록, 삭제 (응답은 모두 변경 후 최신 목록, BE #873)
/// 실패 응답은 ApiClient가 ApiException으로 전달
class KeywordAlertApi {
  static final KeywordAlertApi _instance = KeywordAlertApi._internal();

  factory KeywordAlertApi() => _instance;

  KeywordAlertApi._internal();

  /// `POST /api/members/keyword-alert/get`
  Future<KeywordAlertResponse> getKeywordAlerts() => _sendKeywordAlertRequest(path: 'get', fields: const {});

  /// `POST /api/members/keyword-alert/post` (form: keyword)
  Future<KeywordAlertResponse> postKeywordAlert(String keyword) =>
      _sendKeywordAlertRequest(path: 'post', fields: {'keyword': keyword});

  /// `POST /api/members/keyword-alert/delete` (form: keywordAlertId)
  Future<KeywordAlertResponse> deleteKeywordAlert(String keywordAlertId) =>
      _sendKeywordAlertRequest(path: 'delete', fields: {'keywordAlertId': keywordAlertId});

  /// 공통 multipart 요청 > 목록 응답 변환 (응답 형식 오류 > 호출부에 예외)
  Future<KeywordAlertResponse> _sendKeywordAlertRequest({
    required String path,
    required Map<String, dynamic> fields,
  }) async {
    late KeywordAlertResponse keywordAlertResponse;
    await ApiClient.sendMultipartRequest(
      url: '${AppUrls.baseUrl}/api/members/keyword-alert/$path',
      fields: fields,
      isAuthRequired: true,
      onSuccess: (responseData) {
        keywordAlertResponse = KeywordAlertResponse.fromJson(responseData);
        debugPrint('[keyword alert] $path succeeded : ${keywordAlertResponse.keywordAlerts?.length ?? 0} keywords');
      },
    );
    return keywordAlertResponse;
  }
}
