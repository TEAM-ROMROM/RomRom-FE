import 'package:romrom_fe/services/apis/promotion_api.dart';

/// 우선노출(롬업) 백엔드 API 래핑. UI를 모른다.
class PromotionRepository {
  final PromotionApi _api;

  PromotionRepository(this._api);

  /// 우선노출 활성화 요청.
  Future<void> activate(String itemId) => _api.activatePromotion(itemId);
}
