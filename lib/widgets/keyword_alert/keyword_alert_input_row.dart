import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/keyword_alert_rules.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 키워드 입력칸 + 추가 버튼 + 입력 안내 문구 (#1020)
class KeywordAlertInputRow extends StatelessWidget {
  final TextEditingController keywordController;
  final bool canAddKeyword;
  final bool isSubmitting;
  final VoidCallback onAddPressed;
  // 입력 거부 사유 문구 (없으면 null)
  final String? rejectionMessage;

  const KeywordAlertInputRow({
    super.key,
    required this.keywordController,
    required this.canAddKeyword,
    required this.isSubmitting,
    required this.onAddPressed,
    this.rejectionMessage,
  });

  // 추가 버튼 크기 (모달·버튼류 고정 px)
  static const double addButtonWidth = 72;
  static const double addButtonHeight = 48;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(color: AppColors.opacity10White, borderRadius: BorderRadius.circular(8.r)),
                child: TextField(
                  controller: keywordController,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) {
                    if (canAddKeyword) onAddPressed();
                  },
                  style: CustomTextStyles.p2,
                  cursorColor: AppColors.textColorWhite,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    hintText: '찾는 물건 이름 ($minimumKeywordAlertLength~$maximumKeywordAlertLength자)',
                    hintStyle: CustomTextStyles.p2.copyWith(color: AppColors.opacity40White),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            CompletionButton(
              isEnabled: canAddKeyword,
              isLoading: isSubmitting,
              enabledOnPressed: onAddPressed,
              buttonText: '추가',
              buttonWidth: addButtonWidth,
              buttonHeight: addButtonHeight,
            ),
          ],
        ),
        if (rejectionMessage != null) ...[
          const SizedBox(height: 8),
          Text(rejectionMessage!, style: CustomTextStyles.p3.copyWith(color: AppColors.warningRed)),
        ],
      ],
    );
  }
}
