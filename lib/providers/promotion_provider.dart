import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/enums/promote_result.dart';
import 'package:romrom_fe/providers/promotion_repository_provider.dart';
import 'package:romrom_fe/states/promotion_state.dart';

final promotionProvider = NotifierProvider<PromotionNotifier, PromotionState>(PromotionNotifier.new);

/// 우선노출(롬업) 상태를 단일 소유하는 오케스트레이터.
/// 광고 보상을 받아야만 백엔드 활성화를 호출한다.
class PromotionNotifier extends Notifier<PromotionState> {
  final Set<String> _inFlight = {}; // 중복 요청 방지

  // TODO(#819 BE): 현재는 휘발성 상태라 앱 재시작 시 우선노출 뱃지가 사라진다.
  // BE에 "현재 우선노출 중인 내 물건" 조회 API가 확정되면 build()에서 초기 fetch해
  // 복원할 것(필요 시 AsyncNotifier 전환).
  @override
  PromotionState build() => const PromotionState();

  Future<PromoteResult> promoteItem(String itemId) async {
    if (_inFlight.contains(itemId)) return PromoteResult.alreadyInFlight;
    _inFlight.add(itemId);
    try {
      // 1. 광고 — 보상 받아야만 진행
      final earned = await ref.read(rewardedAdServiceProvider).showAndAwaitReward();
      if (!earned) return PromoteResult.adNotEarned;

      // 2. 백엔드 활성화
      await ref.read(promotionRepositoryProvider).activate(itemId);

      // 3. optimistic 반영 (아직 추가 안 했으므로 롤백 불필요)
      state = state.copyWith(promotedItemIds: {...state.promotedItemIds, itemId});
      return PromoteResult.success;
    } catch (e, st) {
      // 보상은 받았으나 백엔드 활성화 실패 — 원인 추적용 로그 (스테이징 디버그)
      debugPrint('[Promotion] 활성화 실패: $e\n$st');
      return PromoteResult.failed;
    } finally {
      _inFlight.remove(itemId);
    }
  }
}
