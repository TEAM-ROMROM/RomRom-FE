// 물품 등록 옵션 칩 선택 영역: 칩 목록(선택 표시), 미선택 오류 문구 (사용감·거래 방식 공통)
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/register_option_chip.dart';

/// 선택 규칙(단일·복수)은 호출부 onOptionTap이 결정
class RegisterOptionSelector<T> extends StatelessWidget {
  final List<T> options;
  final List<T> selectedOptions;
  final String Function(T option) labelOf;
  final ValueChanged<T> onOptionTap;
  // 터치했거나 제출 시도 후 미선택이면 오류 표시
  final bool shouldShowError;
  final String errorText;
  // 칩 줄 간격 (사용감 8.w, 거래 방식 0)
  final double runSpacing;

  const RegisterOptionSelector({
    super.key,
    required this.options,
    required this.selectedOptions,
    required this.labelOf,
    required this.onOptionTap,
    required this.shouldShowError,
    required this.errorText,
    this.runSpacing = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 8.0.h),
          child: Wrap(
            spacing: 8.w,
            runSpacing: runSpacing,
            children: options
                .map(
                  (option) => RegisterOptionChip(
                    itemOption: labelOf(option),
                    isSelected: selectedOptions.contains(option),
                    onTap: () => onOptionTap(option),
                  ),
                )
                .toList(),
          ),
        ),
        // 오류 없을 때도 빈 줄로 높이 유지
        (shouldShowError && selectedOptions.isEmpty)
            ? Text(errorText, style: CustomTextStyles.p3.copyWith(color: AppColors.errorBorder))
            : Text('', style: CustomTextStyles.p3),
      ],
    );
  }
}
