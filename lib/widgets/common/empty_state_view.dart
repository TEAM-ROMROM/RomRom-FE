import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/completion_button.dart';

/// 빈 상태 뷰 (예: 좋아요 목록이 비어있을 때)
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String centerText;
  final String? descriptionText;
  final String? buttonText;
  final VoidCallback? onButtonTap;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.centerText,
    this.descriptionText,
    this.buttonText,
    this.onButtonTap,
  });

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
              CompletionButton(isEnabled: true, buttonText: buttonText!, enabledOnPressed: onButtonTap),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }
}
