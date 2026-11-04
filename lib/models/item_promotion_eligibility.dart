import 'package:flutter/foundation.dart';

/// 롬업 사전 자격 (서버 /api/item/promote/eligibility): 가능 여부, 불가 사유 errorCode, 남은 횟수, 다음 가능 시각
@immutable
class ItemPromotionEligibility {
  final bool isEligible;
  // ITEM_NOT_PROMOTABLE / ITEM_PROMOTION_ALREADY_ACTIVE / ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED (가능 > null)
  final String? ineligibleReason;
  final int? remainingDailyPromotionCount;
  final DateTime? nextAvailableAt;

  const ItemPromotionEligibility({
    required this.isEligible,
    this.ineligibleReason,
    this.remainingDailyPromotionCount,
    this.nextAvailableAt,
  });

  /// 서버 JSON > 자격 (가능 여부 없음 > null = 판단 불가)
  static ItemPromotionEligibility? tryFromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final isEligible = json['isEligible'];
    if (isEligible is! bool) return null;
    final remainingDailyPromotionCount = json['remainingDailyPromotionCount'];
    return ItemPromotionEligibility(
      isEligible: isEligible,
      ineligibleReason: json['ineligibleReason'] as String?,
      remainingDailyPromotionCount: remainingDailyPromotionCount is num ? remainingDailyPromotionCount.toInt() : null,
      nextAvailableAt: DateTime.tryParse(json['nextAvailableAt']?.toString() ?? ''),
    );
  }
}
