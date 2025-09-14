import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

class CommonSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    Color backgroundColor = Colors.black,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40), // 블러 강도
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.opacity30White,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 16.w),
                      decoration: const BoxDecoration(
                        color: AppColors.opacity20PrimaryYellow,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.onboardingProgressCheck,
                        color: AppColors.primaryYellow,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        message.trim(),
                        style: CustomTextStyles.p2.copyWith(height: 1.4),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        backgroundColor: AppColors.transparent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
        margin: EdgeInsets.only(bottom: 0.h, left: 0.w, right: 0.w),
        duration: const Duration(seconds: 2),
        elevation: 0,
      ),
    );
  }
}
