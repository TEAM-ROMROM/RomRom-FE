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
              return _TradeOptionChip(
                label: option.label,
                isSelected: isSelected,
                onTap: () => _toggle(option, isSelected),
              );
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

class _TradeOptionChip extends StatefulWidget {
  const _TradeOptionChip({required this.label, required this.isSelected, required this.onTap});

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_TradeOptionChip> createState() => _TradeOptionChipState();
}

class _TradeOptionChipState extends State<_TradeOptionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(100.r);

    final bg = widget.isSelected ? AppColors.primaryYellow : AppColors.secondaryBlack1;
    final baseText = widget.isSelected ? AppColors.primaryBlack : AppColors.textColorWhite;

    // 눌렸을 때 글씨를 살짝 “먹이거나(불투명도↓)” 혹은 “톤 변경”
    final pressedText = baseText.withValues(alpha: 0.75);

    final splash = bg.withValues(alpha: 0.25);

    return Material(
      color: bg,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        onHighlightChanged: (v) => setState(() => _pressed = v),
        splashColor: splash,
        highlightColor: Colors.transparent, // 텍스트 위에 하이라이트가 덮이는 느낌 방지
        customBorder: RoundedRectangleBorder(borderRadius: radius),
        child: SizedBox(
          width: 80.w,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
                style: CustomTextStyles.p2.copyWith(color: _pressed ? pressedText : baseText, letterSpacing: -0.32.sp),
                child: Text(widget.label),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
