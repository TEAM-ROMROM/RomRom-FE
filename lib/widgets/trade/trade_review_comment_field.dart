// 거래 후기 한마디 입력: 입력 상자 (글자 수 제한) + 글자 수 표시
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/trade_review_rules.dart';

// 한마디 입력 상자 최소 높이 (px)
const double _commentBoxMinHeight = 140;

class TradeReviewCommentField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  // 입력 변경 (부모의 완료 버튼 활성·글자 수 갱신)
  final ValueChanged<String> onChanged;

  const TradeReviewCommentField({super.key, required this.controller, required this.hintText, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 최소 높이·여백 고정 px (iPad 비율 확대 시 고정 높이 넘침 방지), 글이 길면 늘어남
        Container(
          constraints: const BoxConstraints(minHeight: _commentBoxMinHeight),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryBlack1,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.opacity30White, width: 1.5.w),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            style: CustomTextStyles.p2,
            cursorColor: AppColors.textColorWhite,
            inputFormatters: [LengthLimitingTextInputFormatter(tradeReviewCommentMaxLength)],
            onChanged: onChanged,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          '${controller.text.characters.length}/$tradeReviewCommentMaxLength',
          textAlign: TextAlign.right,
          style: CustomTextStyles.p3.copyWith(color: AppColors.opacity40White),
        ),
      ],
    );
  }
}
