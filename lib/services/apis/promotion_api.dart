import 'package:romrom_fe/models/app_urls.dart';
import 'package:romrom_fe/services/api_client.dart';

class PromotionApi {
  static final PromotionApi _instance = PromotionApi._internal();
  factory PromotionApi() => _instance;
  PromotionApi._internal();

  /// 우선노출 활성화. 광고 보상 시청 완료 후 호출.
  /// TODO(#819 BE): 엔드포인트/요청 바디/보상 검증 토큰은 백엔드 확정 시 교체.
  Future<void> activatePromotion(String itemId) async {
    final url = '${AppUrls.baseUrl}/api/item/promote';
    await ApiClient.sendHttpRequest(url: url, method: 'POST', body: {'itemId': itemId}, onSuccess: (_) {});
  }
}
