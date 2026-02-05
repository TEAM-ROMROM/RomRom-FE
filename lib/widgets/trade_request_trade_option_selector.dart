import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_trade_option.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 요청하기 화면 하단에 표시되는 거래 옵션 선택 위젯
class TradeRequestTradeOptionSelector extends StatelessWidget {
  final Set<ItemTradeOption> selectedOptions;
  final ValueChanged<Set<ItemTradeOption>> onChanged;

  const TradeRequestTradeOptionSelector({super.key, required this.selectedOptions, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(color: AppColors.primaryBlack, borderRadius: BorderRadius.circular(10.r)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '거래방식 선택',
            style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500, color: AppColors.opacity50White),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: ItemTradeOption.values.map((option) {
              final isSelected = selectedOptions.contains(option);
              return _TradeOptionChip(option: option, isSelected: isSelected, onTap: () => _toggle(option, isSelected));
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _toggle(ItemTradeOption option, bool isSelected) {
    final next = Set<ItemTradeOption>.from(selectedOptions);
    if (isSelected) {
      next.remove(option);
    } else {
      next.add(option);
    }
    onChanged(next);
  }
}

/// 개별 거래 옵션 칩 위젯
class _TradeOptionChip extends StatelessWidget {
  final ItemTradeOption option;
  final bool isSelected;
  final VoidCallback onTap;

  const _TradeOptionChip({required this.option, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 80.w,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryYellow : AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(100.r),
        ),
        child: Text(
          option.label,
          style: CustomTextStyles.p2.copyWith(
            color: isSelected ? AppColors.primaryBlack : AppColors.textColorWhite,
            letterSpacing: -0.32.sp,
          ),
        ),
      ),
    );
  }
}
