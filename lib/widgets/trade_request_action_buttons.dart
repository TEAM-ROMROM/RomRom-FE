import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/app_test_keys.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/loading_indicator.dart';

/// 교환 요청 화면 하단 버튼: 취소, 요청하기 (비활성 > 반투명·탭 무시, 진행 중 > 검정 스피너)
class TradeRequestActionButtons extends StatelessWidget {
  final bool isRequestDisabled;
  final bool isRequestLoading;
  final VoidCallback onCancel;
  final VoidCallback onRequest;

  const TradeRequestActionButtons({
    super.key,
    required this.isRequestDisabled,
    required this.isRequestLoading,
    required this.onCancel,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    // 요청하기 버튼 색
    Color requestButtonColor = isRequestDisabled
        ? AppColors.primaryYellow.withValues(alpha: 0.5)
        : AppColors.primaryYellow;
    // 요청하기 버튼 highlightColor
    Color requestButtonHighlightColor = darkenBlend(requestButtonColor);
    Color requestButtonSplashColor = requestButtonHighlightColor.withValues(alpha: 0.3);

    // 취소 버튼 색
    Color cancelButtonColor = AppColors.secondaryBlack1;
    // 취소 버튼 highlightColor
    Color cancelButtonHighlightColor = darkenBlend(AppColors.buttonHighlightColorGray);
    Color cancelButtonSplashColor = darkenBlend(AppColors.buttonHighlightColorGray).withValues(alpha: 0.3);

    return Row(
      children: [
        // 취소 버튼
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 56.h,
            child: Material(
              color: cancelButtonColor,
              borderRadius: BorderRadius.circular(10.r),
              child: InkWell(
                onTap: onCancel,
                customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                highlightColor: cancelButtonHighlightColor,
                splashColor: cancelButtonSplashColor,
                child: Center(child: Text('취소', style: CustomTextStyles.p1)),
              ),
            ),
          ),
        ),
        SizedBox(width: 7.w),
        // 요청하기 버튼
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 56.h,
            child: Material(
              color: requestButtonColor,
              borderRadius: BorderRadius.circular(10.r),
              child: InkWell(
                key: AppTestKeys.tradeRequestSubmitButton,
                customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                onTap: isRequestDisabled ? null : onRequest,
                highlightColor: requestButtonHighlightColor,
                splashColor: requestButtonSplashColor,
                child: Center(
                  // 요청 중이면 검정 스피너, 아니면 버튼 텍스트
                  child: isRequestLoading
                      ? const CommonLoadingIndicator(color: AppColors.textColorBlack)
                      : Text('요청하기', style: CustomTextStyles.p1.copyWith(color: AppColors.textColorBlack)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
