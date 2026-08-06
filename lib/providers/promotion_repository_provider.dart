import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/repositories/promotion_repository.dart';
import 'package:romrom_fe/services/apis/promotion_api.dart';
import 'package:romrom_fe/services/rewarded_ad_service.dart';

/// 우선노출 repository 주입용 공유 Provider.
final promotionRepositoryProvider = Provider<PromotionRepository>((ref) => PromotionRepository(PromotionApi()));

/// 보상형 광고 서비스 주입용 공유 Provider.
final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) => RewardedAdService());
