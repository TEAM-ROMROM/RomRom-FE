import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// 공통 실패 모달
class CommonFailModal extends StatelessWidget {
  final String titleLine1;
  final String titleLine2;
  final VoidCallback onConfirm;

  const CommonFailModal({
    super.key,
    required this.titleLine1,
    required this.titleLine2,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Center(
        child: Container(
          width: 312.w,
          height: 216.h,
          decoration: BoxDecoration(
            color: AppColors.secondaryBlack,
            borderRadius: BorderRadius.circular(8.r),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(2, 2),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(height: 24.h),
              SvgPicture.asset(
                'assets/images/temp/warningRed.svg',
                width: 40.w,
                height: 40.w,
              ),
              SizedBox(height: 16.h),
              Text(
                titleLine1,
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorWhite.withValues(alpha: 0.8),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                titleLine2,
                style: CustomTextStyles.p2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColorWhite.withValues(alpha: 0.8),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: 264.w,
                height: 44.h,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.warningRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    '확인',
                    style: CustomTextStyles.p1.copyWith(
                      color: AppColors.textColorWhite,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }
} 