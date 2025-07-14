import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class WarningDialog extends StatelessWidget {
  final String title;
  final String description;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const WarningDialog({
    super.key,
    required this.title,
    required this.description,
    this.cancelText = '취소',
    this.confirmText = '삭제',
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      elevation: 0,
      backgroundColor: AppColors.secondaryBlack,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Container(
        width: 312.w,
        height: 216.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: const [
            BoxShadow(
              color: AppColors.opacity15Black,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24.0.w),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.warningRed.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    AppIcons.warning,
                    size: 28.sp,
                    color: AppColors.warningRed,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "$title\n$description",
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: AppColors.opacity80White,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(
                    text: cancelText,
                    backgroundColor: AppColors.opacity30PrimaryBlack,
                    onPressed: onCancel,
                  ),
                  SizedBox(width: 8.w),
                  _buildButton(
                    text: confirmText,
                    backgroundColor: AppColors.warningRed,
                    onPressed: onConfirm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 취소, 삭제 버튼을 생성하는 메소드
  Widget _buildButton({
    required String text,
    required Color backgroundColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 128.w,
      height: 44.h,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: CustomTextStyles.p1,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
