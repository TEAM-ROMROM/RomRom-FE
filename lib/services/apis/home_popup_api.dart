import 'dart:convert';

import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

/// 홈 팝업 API: 활성 팝업 조회 (응답 해석·실패 처리는 HomePopupRepository)
class HomePopupApi {
  static final HomePopupApi _instance = HomePopupApi._internal();

  factory HomePopupApi() => _instance;

  HomePopupApi._internal();

  /// 현재 노출 대상 팝업 1개 조회 > 디코딩된 응답 본문 (빈 본문이면 null)
  /// `GET /api/home-popups/active` (비로그인 포함 누구나, JWT 불필요)
  /// 2xx 외 응답은 ApiException
  Future<Object?> fetchActiveHomePopupBody() async {
    final String url = '${AppUrls.baseUrl}/api/home-popups/active';

    final response = await ApiClient.sendHttpRequest(url: url, method: 'GET', isAuthRequired: false, onSuccess: (_) {});
    if (response.body.trim().isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}
