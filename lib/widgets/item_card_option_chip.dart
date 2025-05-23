import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/item_card_scale_utils.dart';
import '../models/app_colors.dart';
import '../models/app_theme.dart';

/// 물품 카드 옵션 토글칩 위젯
/// : 추가금, 직거래, 택배 여부 선택하는 칩
class ItemCardOptionChip extends ConsumerWidget {
  final String itemId; // 각 물품의 고유 ID
  final String itemOption; // 옵션 이름 (추가금, 직거래, 택배)

  const ItemCardOptionChip({
    super.key,
    required this.itemId,
    required this.itemOption,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = itemCardProvider(itemId);
    final asyncState = ref.watch(provider);

    return asyncState.when(
      data: (state) {
        final cs = state.scale;
        final isSelected = state.selectedOptions.contains(itemOption);

        final chipColor =
            isSelected ? AppColors.primaryYellow : AppColors.itemCardOptionChip;
        final chipRadius = cs.radius(100);

        final textStyle = CustomTextStyles.p3.copyWith(
          fontSize: cs.fontSize(CustomTextStyles.p3.fontSize!),
          color: isSelected ? AppColors.primaryBlack : AppColors.textColorWhite,
        );

        return Material(
          color: Colors.transparent,
          child: Ink(
            decoration: buildBoxDecoration(chipColor, chipRadius),
            child: InkWell(
              borderRadius: chipRadius,
              onTap: () {
                ref.read(provider.notifier).toggleOption(itemOption);
              },
              child: Container(
                width: cs.s(72),
                height: cs.s(29),
                alignment: Alignment.center,
                child: Text(itemOption, style: textStyle),
              ),
            ),
          ),
        );
      },
      loading: () => Container(
        width: 72,
        height: 29,
        alignment: Alignment.center,
        decoration: buildBoxDecoration(
            AppColors.itemCardOptionChip, BorderRadius.circular(100)),
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (err, stack) => Container(
        width: 72,
        height: 29,
        alignment: Alignment.center,
        decoration: buildBoxDecoration(Colors.grey, BorderRadius.circular(100)),
        child: const Icon(Icons.error, color: Colors.white, size: 16),
      ),
    );
  }
}
