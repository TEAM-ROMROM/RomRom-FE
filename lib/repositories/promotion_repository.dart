import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/item_promotion_eligibility.dart';
import 'package:romrom_fe/services/apis/promotion_api.dart';

/// 우선노출(롬업) 저장소: PromotionApi 래핑 (UI 모름)
class PromotionRepository {
  final PromotionApi _api;

  PromotionRepository(this._api);

  /// 우선노출 활성화 > 활성화된 물품 (실패는 ApiException 그대로 전달)
  Future<Item?> promote(String itemId) => _api.promoteItem(itemId);

  /// 우선노출 사전 자격 (구버전 서버·실패 > 예외 전달, 형식 불일치 > null)
  Future<ItemPromotionEligibility?> getEligibility(String itemId) => _api.getPromotionEligibility(itemId);
}
