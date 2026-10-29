import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 빈 상태·에러 상태 뷰: 아이콘, 중앙 문구, 설명, 버튼(옵션)
/// 목록 비어있음 > 기본 생성자 / 불러오기 실패 > .error (다시 시도 버튼)
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String centerText;
  final String? descriptionText;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  // 버튼 동작 진행 중 여부 (true면 스피너 표시 + 탭 무시)
  final bool isButtonLoading;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.centerText,
    this.descriptionText,
    this.buttonText,
    this.onButtonTap,
    this.isButtonLoading = false,
  });

  /// 불러오기 실패 뷰: 경고 아이콘 + 다시 시도 버튼 (isRetrying이면 재시도 탭 무시)
  const EmptyStateView.error({
    super.key,
    required VoidCallback onRetry,
    this.centerText = '불러오지 못했어요',
    String this.descriptionText = '잠시 후 다시 시도해 주세요',
    bool isRetrying = false,
  }) : icon = AppIcons.warning,
       buttonText = '다시 시도',
       onButtonTap = onRetry,
       isButtonLoading = isRetrying;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 아이콘
            Icon(icon, size: 80.sp, color: AppColors.opacity40White),
            SizedBox(height: 24.h),

            // 중앙 텍스트
            Text(
              centerText,
              style: CustomTextStyles.h3.copyWith(fontWeight: FontWeight.w600, color: AppColors.textColorWhite),
              textAlign: TextAlign.center,
            ),

            // 설명 텍스트 (옵션)
            if (descriptionText != null) ...[
              SizedBox(height: 12.h),
              Text(
                descriptionText!,
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w400,
                  color: AppColors.opacity60White,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],

            // 버튼 (옵션)
            if (buttonText != null && onButtonTap != null) ...[
              SizedBox(height: 40.h),
              CompletionButton(
                isEnabled: true,
                isLoading: isButtonLoading,
                buttonText: buttonText!,
                enabledOnPressed: onButtonTap,
              ),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
