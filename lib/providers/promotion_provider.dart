import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/enums/rewarded_ad_outcome.dart';
import 'package:romrom_fe/exceptions/api_exception.dart';
import 'package:romrom_fe/providers/my_items_provider.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/states/promotion_state.dart';

final promotionProvider = NotifierProvider<PromotionNotifier, PromotionState>(PromotionNotifier.new);

/// 우선노출(롬업) 오케스트레이터: 광고 보상 > 서버 활성화 > 내 물건 재조회
/// 노출 중 표시는 myItemsProvider 물품 필드 기준, 이 상태는 처리 중 itemId만 소유
class PromotionNotifier extends Notifier<PromotionState> {
  @override
  PromotionState build() => const PromotionState();

  /// 우선노출 1회: 중복 차단 > 광고 시청 (보상 적립 시에만 진행) > 서버 활성화 > 내 물건 재조회
  Future<PromoteResult> promoteItem(String itemId) async {
    if (state.isPromoting(itemId)) return PromoteResult.alreadyInFlight;
    state = state.copyWith(promotingItemIds: {...state.promotingItemIds, itemId});
    try {
      final adOutcome = await ref.read(rewardedAdServiceProvider).showAndAwaitReward();
      if (adOutcome != RewardedAdOutcome.earned) return _toAdFailureResult(adOutcome);

      await ref.read(promotionRepositoryProvider).promote(itemId);
      // 배지·남은 시간은 서버 재조회 결과로 표시 (CLAUDE.md 규칙 3)
      await ref.read(myItemsProvider.notifier).reload();
      return PromoteResult.success;
    } catch (error) {
      debugPrint('[item promote] failed : $error');
      return toPromoteFailureResult(error);
    } finally {
      state = state.copyWith(promotingItemIds: {...state.promotingItemIds}..remove(itemId));
    }
  }

  PromoteResult _toAdFailureResult(RewardedAdOutcome adOutcome) =>
      adOutcome == RewardedAdOutcome.notEarned ? PromoteResult.adNotEarned : PromoteResult.adUnavailable;
}

// 백엔드 errorCode > 우선노출 결과
const _promoteResultByErrorCode = <String, PromoteResult>{
  'ITEM_PROMOTION_ALREADY_ACTIVE': PromoteResult.alreadyPromoted,
  'ITEM_PROMOTION_DAILY_LIMIT_EXCEEDED': PromoteResult.dailyLimitExceeded,
  'ITEM_NOT_PROMOTABLE': PromoteResult.notPromotable,
};

/// 활성화 실패 > 결과: errorCode 우선, 없으면 상태 코드 (409·429만), 그 외 failed
/// 404 ITEM_NOT_FOUND·403 INVALID_ITEM_OWNER·네트워크 오류 > failed
@visibleForTesting
PromoteResult toPromoteFailureResult(Object error) {
  if (error is! ApiException) return PromoteResult.failed;
  final resultByErrorCode = _promoteResultByErrorCode[error.errorCode];
  if (resultByErrorCode != null) return resultByErrorCode;
  return switch (error.statusCode) {
    409 => PromoteResult.alreadyPromoted,
    429 => PromoteResult.dailyLimitExceeded,
    _ => PromoteResult.failed,
  };
}
