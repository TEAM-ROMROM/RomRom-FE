import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';

/// 프로필 정보 행 (label + value)
class ProfileInfoSection extends StatelessWidget {
  final String label;
  final String value;

  const ProfileInfoSection({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CustomTextStyles.p2),
          Text(
            value,
            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w400, color: AppColors.opacity60White),
          ),
        ],
      ),
    );
  }
}

/// 받은 좋아요 수 행
class ProfileLikesSection extends StatelessWidget {
  final int likeCount;

  const ProfileLikesSection({super.key, required this.likeCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54.h,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('받은 좋아요 수', style: CustomTextStyles.p2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(AppIcons.profilelikecount, size: 16.sp, color: AppColors.textColorWhite),
              SizedBox(width: 3.w),
              Text(
                '$likeCount',
                style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
                textAlign: TextAlign.right,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
