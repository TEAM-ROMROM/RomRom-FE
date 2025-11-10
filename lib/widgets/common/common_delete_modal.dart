import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CommonDeleteModal extends StatelessWidget {
  final String description;
  final String leftText;
  final String rightText;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  const CommonDeleteModal({
    super.key,
    required this.description,
    this.leftText = '취소',
    this.rightText = '삭제',
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.r),
      ),
      elevation: 0,
      backgroundColor: AppColors.secondaryBlack1,
      insetPadding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Container(
        width: 312.w,
        height: 206.h,
        decoration: BoxDecoration(
          color: AppColors.secondaryBlack1,
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
                  child:  Icon(
                    AppIcons.warning,
                    size: 40.sp,
                    color: AppColors.warningRed,
                  ),
                ),
              ),
              SizedBox(height: 16.h),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildButton(
                    text: leftText,
                    backgroundColor: AppColors.opacity30PrimaryBlack,
                    onPressed: onLeft,
                  ),
                  SizedBox(width: 8.w),
                  _buildButton(
                    text: rightText,
                    backgroundColor: AppColors.warningRed,
                    onPressed: onRight,
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
