import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 공통 모달 위젯
/// 팩토리 메서드 패턴으로 success, error, confirm 타입 지원
class CommonModal extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final String message;
  final String? cancelText;
  final String confirmText;
  final Color confirmButtonColor;
  final Color confirmTextColor;
  final VoidCallback? onCancel;
  final VoidCallback onConfirm;

  const CommonModal._({
    required this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    required this.message,
    this.cancelText,
    required this.confirmText,
    required this.confirmButtonColor,
    required this.confirmTextColor,
    this.onCancel,
    required this.onConfirm,
  });

  /// 성공 모달 (노란색 체크 아이콘, 1버튼)
  static Future<void> success({
    required BuildContext context,
    required String message,
    String buttonText = '확인',
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      builder: (_) => CommonModal._(
        icon: AppIcons.onboardingProgressCheck,
        iconColor: AppColors.primaryYellow,
        iconBackgroundColor: AppColors.primaryYellow.withValues(alpha: 0.2),
        message: message,
        confirmText: buttonText,
        confirmButtonColor: AppColors.primaryYellow,
        confirmTextColor: AppColors.textColorBlack,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 에러 모달 (빨간색 경고 아이콘, 1버튼)
  static Future<void> error({
    required BuildContext context,
    required String message,
    String buttonText = '확인',
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      builder: (_) => CommonModal._(
        icon: AppIcons.warning,
        iconColor: AppColors.warningRed,
        iconBackgroundColor: AppColors.warningRed.withValues(alpha: 0.2),
        message: message,
        confirmText: buttonText,
        confirmButtonColor: AppColors.warningRed,
        confirmTextColor: AppColors.textColorWhite,
        onConfirm: onConfirm,
      ),
    );
  }

  /// 확인 모달 (빨간색 경고 아이콘, 2버튼)
  /// confirmText를 통해 '삭제', '나가기', '탈퇴' 등 커스텀 가능
  static Future<bool?> confirm({
    required BuildContext context,
    required String message,
    String cancelText = '취소',
    String confirmText = '확인',
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      builder: (_) => CommonModal._(
        icon: AppIcons.warning,
        iconColor: AppColors.warningRed,
        iconBackgroundColor: AppColors.warningRed.withValues(alpha: 0.2),
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        confirmButtonColor: AppColors.warningRed,
        confirmTextColor: AppColors.textColorWhite,
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isTwoButton = cancelText != null && onCancel != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      elevation: 0,
      backgroundColor: AppColors.secondaryBlack1,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Container(
        width: 312.w,
        height: 206.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: const [BoxShadow(color: AppColors.opacity15Black, blurRadius: 10, offset: Offset(2, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            children: [
              // 아이콘
              Center(
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(color: iconBackgroundColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 40.sp, color: iconColor),
                ),
              ),
              SizedBox(height: 16.h),
              // 메시지
              Text(
                message,
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.opacity80White,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // 버튼
              isTwoButton ? _buildTwoButtons() : _buildSingleButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// 단일 버튼 (success, error)
  Widget _buildSingleButton() {
    return SizedBox(
      width: 264.w,
      height: 44.h,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: confirmButtonColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ),
        onPressed: onConfirm,
        child: Text(
          confirmText,
          style: CustomTextStyles.p1.copyWith(color: confirmTextColor, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// 2버튼 (confirm)
  Widget _buildTwoButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 취소 버튼
        SizedBox(
          width: 128.w,
          height: 44.h,
          child: ElevatedButton(
            onPressed: onCancel,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.opacity30PrimaryBlack,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
              padding: EdgeInsets.zero,
            ),
            child: Text(cancelText!, style: CustomTextStyles.p1, textAlign: TextAlign.center),
          ),
        ),
        SizedBox(width: 8.w),
        // 확인/삭제/나가기 버튼
        SizedBox(
          width: 128.w,
          height: 44.h,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmButtonColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              elevation: 0,
              padding: EdgeInsets.zero,
            ),
            child: Text(confirmText, style: CustomTextStyles.p1, textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}
