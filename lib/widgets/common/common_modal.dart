import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_motion.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/utils/device_type.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';

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

  //  앱 내에서 특정 조건에서 한 번만 보여줘야 하는 모달 처리 헬퍼
  static void showOnceAfterFrame({
    required BuildContext context,
    required bool Function() shouldShow, // 보여줘야 하는지 판단하는 함수
    required VoidCallback markShown, // 보여줬다고 표시하는 함수
    required bool Function() isShown, // 이미 보여줬는지 체크하는 함수
    required String message,
    required VoidCallback onConfirm,
  }) {
    if (isShown()) return;
    if (!shouldShow()) return;

    markShown();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      await CommonModal.error(context: context, message: message, onConfirm: onConfirm);
    });
  }

  /// 모달 등장 애니메이션: fade + scale (0.92→1.0)
  static Widget _buildTransition(Widget child, Animation<double> animation) {
    final curvedAnim = CurvedAnimation(parent: animation, curve: AppMotion.decelerate);
    return FadeTransition(
      opacity: curvedAnim,
      child: ScaleTransition(scale: Tween<double>(begin: 0.92, end: 1.0).animate(curvedAnim), child: child),
    );
  }

  /// 성공 모달 (노란색 체크 아이콘, 1버튼)
  static Future<void> success({
    required BuildContext context,
    required String message,
    String buttonText = '확인',
    required VoidCallback onConfirm,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      barrierLabel: '',
      transitionDuration: AppMotion.slow,
      transitionBuilder: (context0, animation, secondaryAnimation0, child) => _buildTransition(child, animation),
      pageBuilder: (context0, animation0, secondaryAnimation0) => CommonModal._(
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
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      barrierLabel: '',
      transitionDuration: AppMotion.slow,
      transitionBuilder: (context0, animation, secondaryAnimation0, child) => _buildTransition(child, animation),
      pageBuilder: (context0, animation0, secondaryAnimation0) => CommonModal._(
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
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.dialogBarrier,
      barrierLabel: '',
      transitionDuration: AppMotion.slow,
      transitionBuilder: (context0, animation, secondaryAnimation0, child) => _buildTransition(child, animation),
      pageBuilder: (context0, animation0, secondaryAnimation0) => CommonModal._(
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
      insetPadding: EdgeInsets.symmetric(horizontal: isTablet ? 200 : 40.w),
      child: Container(
        width: 312.w,
        constraints: BoxConstraints(maxWidth: 312.w),
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: const [BoxShadow(color: AppColors.opacity15Black, blurRadius: 10, offset: Offset(2, 2))],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 아이콘
              Center(
                child: Container(
                  width: 40,
                  height: 40,
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
              SizedBox(height: 24.h),
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
      height: 44,
      child: AppPressable(
        onTap: onConfirm,
        borderRadius: BorderRadius.circular(10.r),
        rippleColor: darkenBlend(confirmButtonColor),
        child: Container(
          decoration: BoxDecoration(color: confirmButtonColor, borderRadius: BorderRadius.circular(10.r)),
          alignment: Alignment.center,
          child: Text(
            confirmText,
            style: CustomTextStyles.p1.copyWith(color: confirmTextColor, fontWeight: FontWeight.w700),
          ),
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
        Expanded(
          child: SizedBox(
            height: 44,
            child: AppPressable(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(10.r),
              rippleColor: darkenBlend(AppColors.opacity30PrimaryBlack),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.opacity30PrimaryBlack,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                alignment: Alignment.center,
                child: Text(cancelText!, style: CustomTextStyles.p1, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
        SizedBox(width: 8.w),
        // 확인/삭제/나가기 버튼
        Expanded(
          child: SizedBox(
            height: 44,
            child: AppPressable(
              onTap: onConfirm,
              borderRadius: BorderRadius.circular(10.r),
              rippleColor: darkenBlend(confirmButtonColor),
              child: Container(
                decoration: BoxDecoration(color: confirmButtonColor, borderRadius: BorderRadius.circular(10.r)),
                alignment: Alignment.center,
                child: Text(confirmText, style: CustomTextStyles.p1, textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
