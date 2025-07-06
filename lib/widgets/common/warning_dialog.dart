import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        width: 312.w,
        height: 216.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.opacity15Black,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            SizedBox(height: 24.h),
            Center(
              child: SvgPicture.asset(
                'assets/images/warning.svg',
                width: 40.w,
                height: 40.h,
                colorFilter: const ColorFilter.mode(
                  AppColors.warningRed,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: CustomTextStyles.p2.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.opacity80White,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              description,
              style: CustomTextStyles.p2.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.3,
                color: AppColors.opacity80White,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Padding(
              padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 24.h),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }

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
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: CustomTextStyles.p1.copyWith(
            color: AppColors.textColorWhite,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
