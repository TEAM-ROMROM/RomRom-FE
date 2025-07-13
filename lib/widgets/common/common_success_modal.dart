import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 공통 성공 모달
class CommonSuccessModal extends StatelessWidget {
  final String message;
  final VoidCallback onConfirm;

  const CommonSuccessModal({
    super.key,
    required this.message,
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
          height: 206.h,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 24.h),
              SvgPicture.asset(
                'assets/images/temp/confirmYellow.svg',
                width: 40.w,
                height: 40.w,
              ),
              SizedBox(height: 24.h),
              Text(
                message,
                style: CustomTextStyles.h3.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: 264.w,
                height: 44.h,
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primaryYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: onConfirm,
                  child: Text(
                    '완료',
                    style: CustomTextStyles.p1.copyWith(
                      color: AppColors.textColorBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }
} 