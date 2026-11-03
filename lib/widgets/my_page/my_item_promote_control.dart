import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/item_promotion_policy.dart';
import 'package:romrom_fe/providers/promotion_provider.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/common_modal.dart';
import 'package:romrom_fe/widgets/common/common_snack_bar.dart';

/// 내 물건 우선노출(롬업) 컨트롤: 노출 중 > 남은 시간 배지, 처리 중 > 비활성 버튼, 그 외 > 우선 노출 버튼
/// 노출 중 판정은 서버 물품 필드(promotionExpiresAt·isPromoted) 기준 (앱 재시작 후에도 유지), 노출 중이면 최대 1분마다 다시 그림
class MyItemPromoteControl extends ConsumerStatefulWidget {
  final Item item;

  /// 노출 판정·남은 시간 기준 시각 공급자 (테스트 주입용, null > 현재 시각)
  final DateTime Function()? clock;

  const MyItemPromoteControl({super.key, required this.item, this.clock});

  // 노출 중 배지 다시 그리는 최대 간격 (분 단위 표시)
  static const Duration badgeRefreshInterval = Duration(minutes: 1);

  /// 남은 시간 > 배지 문구 (1시간 이상 > 시간, 미만 > 분 최소 1, 종료 시각 없음 > 문구만)
  @visibleForTesting
  static String toPromotionActiveLabel(Duration? remainingDuration) {
    if (remainingDuration == null) return '⚡ 노출 중';
    if (remainingDuration.inHours >= 1) return '⚡ 노출 중 · ${remainingDuration.inHours}시간 남음';
    final remainingMinutes = remainingDuration.inMinutes < 1 ? 1 : remainingDuration.inMinutes;
    return '⚡ 노출 중 · $remainingMinutes분 남음';
  }

  @override
  ConsumerState<MyItemPromoteControl> createState() => _MyItemPromoteControlState();
}

class _MyItemPromoteControlState extends ConsumerState<MyItemPromoteControl> {
  // 다음 배지 갱신 예약 (만료 시 버튼으로 전환, 남은 시간 문구 갱신)
  Timer? _badgeRefreshTimer;

  @override
  void dispose() {
    _badgeRefreshTimer?.cancel();
    super.dispose();
  }

  /// 노출 중이면 다음 갱신 예약: 남은 시간과 1분 중 짧은 쪽 (만료 순간 바로 다시 그림)
  void _scheduleBadgeRefresh(Duration? remainingDuration) {
    _badgeRefreshTimer?.cancel();
    if (remainingDuration == null) return;
    final refreshDelay = Duration(
      microseconds: min(remainingDuration.inMicroseconds, MyItemPromoteControl.badgeRefreshInterval.inMicroseconds),
    );
    _badgeRefreshTimer = Timer(refreshDelay, () {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final itemId = widget.item.itemId;
    if (itemId == null) return const SizedBox.shrink();

    final now = (widget.clock ?? DateTime.now)();
    if (widget.item.isPromotionActiveAt(now)) {
      final remainingDuration = widget.item.promotionRemainingAt(now);
      _scheduleBadgeRefresh(remainingDuration);
      return _buildPromotionActiveBadge(MyItemPromoteControl.toPromotionActiveLabel(remainingDuration));
    }
    _scheduleBadgeRefresh(null);

    final isPromoting = ref.watch(promotionProvider.select((state) => state.isPromoting(itemId)));
    return AppPressable(
      enabled: !isPromoting,
      onTap: () => _onPromoteButtonPressed(itemId),
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

  /// 우선 노출 탭: 확인 창(광고 시청·하루 횟수 안내) > 광고 > 서버 활성화 (notifier) > 결과별 토스트 (중복 요청은 토스트 없음)
  Future<void> _onPromoteButtonPressed(String itemId) async {
    final isConfirmed = await _confirmPromotion();
    if (isConfirmed != true || !mounted) return;

    final result = await ref.read(promotionProvider.notifier).promoteItem(itemId);
    final toastMessage = result.toastMessage;
    final toastType = result.toastType;
    if (!mounted || toastMessage == null || toastType == null) return;
    CommonSnackBar.show(context: context, message: toastMessage, type: toastType);
  }

  /// 우선 노출 확인 창 (노출 시간은 서버가 정해 숫자 없이 안내, 시작 후 배지에 남은 시간 표시)
  Future<bool?> _confirmPromotion() {
    return CommonModal.confirm(
      context: context,
      message: '광고를 끝까지 보면 이 물품이\n홈 피드에 우선 노출돼요.\n우선 노출은 하루 ${ItemPromotionPolicy.dailyLimitCount}회까지 쓸 수 있어요.',
      confirmText: '광고 보기',
      icon: AppIcons.arrowUpward,
      iconColor: AppColors.primaryYellow,
      confirmButtonColor: AppColors.primaryYellow,
      confirmTextColor: AppColors.textColorBlack,
      onCancel: () => Navigator.of(context).pop(false),
      onConfirm: () => Navigator.of(context).pop(true),
    );
  }
}
