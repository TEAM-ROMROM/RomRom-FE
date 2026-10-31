import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/providers/promotion_provider.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 내 물건 우선노출(롬업) 컨트롤: 노출 중 > 남은 시간 배지, 처리 중 > 비활성 버튼, 그 외 > 우선 노출 버튼
/// 노출 중 판정은 서버 물품 필드(promotionExpiresAt·isPromoted) 기준 (앱 재시작 후에도 유지)
class MyItemPromoteControl extends ConsumerWidget {
  final Item item;

  /// 노출 판정·남은 시간 기준 시각 (테스트 주입용, null > 현재 시각)
  final DateTime? referenceTime;

  const MyItemPromoteControl({super.key, required this.item, this.referenceTime});

  /// 남은 시간 > 배지 문구 (1시간 이상 > 시간, 미만 > 분 최소 1, 종료 시각 없음 > 문구만)
  @visibleForTesting
  static String toPromotionActiveLabel(Duration? remainingDuration) {
    if (remainingDuration == null) return '⚡ 노출 중';
    if (remainingDuration.inHours >= 1) return '⚡ 노출 중 · ${remainingDuration.inHours}시간 남음';
    final remainingMinutes = remainingDuration.inMinutes < 1 ? 1 : remainingDuration.inMinutes;
    return '⚡ 노출 중 · $remainingMinutes분 남음';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemId = item.itemId;
    if (itemId == null) return const SizedBox.shrink();

    final now = referenceTime ?? DateTime.now();
    if (item.isPromotionActiveAt(now)) {
      return _buildPromotionActiveBadge(toPromotionActiveLabel(item.promotionRemainingAt(now)));
    }

    final isPromoting = ref.watch(promotionProvider.select((state) => state.isPromoting(itemId)));
    return AppPressable(
      enabled: !isPromoting,
      onTap: () => _onPromoteButtonPressed(context, ref, itemId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isPromoting ? AppColors.opacity10White : AppColors.primaryYellow,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          isPromoting ? '광고 준비 중' : '⚡ 우선 노출',
          style: CustomTextStyles.p3.copyWith(
            color: isPromoting ? AppColors.opacity60White : AppColors.primaryBlack,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPromotionActiveBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White, fontWeight: FontWeight.w600),
      ),
    );
  }

  /// 우선 노출 탭: 광고 > 서버 활성화 (notifier) > 결과별 토스트 (중복 요청은 토스트 없음)
  Future<void> _onPromoteButtonPressed(BuildContext context, WidgetRef ref, String itemId) async {
    final result = await ref.read(promotionProvider.notifier).promoteItem(itemId);
    final toastMessage = result.toastMessage;
    final toastType = result.toastType;
    if (!context.mounted || toastMessage == null || toastType == null) return;
    CommonSnackBar.show(context: context, message: toastMessage, type: toastType);
  }
}
