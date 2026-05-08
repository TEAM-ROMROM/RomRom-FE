import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:romrom_fe/enums/trade_review_rating.dart';
import 'package:romrom_fe/enums/trade_review_tag.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/user_profile_circular_avatar.dart';

class MyReviewSection extends StatelessWidget {
  const MyReviewSection({super.key});

  @override
  Widget build(BuildContext context) {
    final topRadius = BorderRadius.only(topLeft: Radius.circular(10.r), topRight: Radius.circular(10.r));

    final bottomRadius = BorderRadius.only(bottomLeft: Radius.circular(10.r), bottomRight: Radius.circular(10.r));

    return Column(
      children: [
        /// 교환 후기 섹션
        ClipRRect(
          borderRadius: topRadius,
          child: Stack(
            children: [
              /// 기본 배경
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: topRadius),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('교환 후기', style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(height: 16.h),
                    Column(
                      children: [
                        Center(
                          child: SizedBox(
                            height: 92.w,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (int index = 0; index < TradeReviewRating.values.length; index++) ...[
                                  _buildRatingCountColumn(TradeReviewRating.values[index]),

                                  if (index != TradeReviewRating.values.length - 1)
                                    Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 38.0.w),
                                      child: Container(
                                        width: 1.5.w,
                                        height: double.infinity,
                                        decoration: const BoxDecoration(color: AppColors.opacity10White),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                      ],
                    ),
                  ],
                ),
              ),

              /// 블러 그라데이션 오버레이
              Positioned(
                child: IgnorePointer(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 50, sigmaY: 80),
                    child: Container(
                      width: double.infinity,
                      height: 70.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.topRight,
                          colors: [
                            AppColors.reviewRatingBad,
                            AppColors.reviewRatingGood,
                            AppColors.reviewRatingGreat,
                          ].map((c) => c.withValues(alpha: 0.15)).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        /// 교환 후기 리스트
        Container(
          padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 20.h),
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: bottomRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  // TODO: 서버에서 후기 태그 리스트 받아와서 태그 많은순으로 정렬해서 표시하기
                  for (int index = 0; index < TradeReviewTag.values.length; index++) ...[
                    _buildRatingReviewTag(TradeReviewTag.values[index]),
                  ],
                ],
              ),
              SizedBox(height: 24.h),
              _buildReviewComment(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingCountColumn(TradeReviewRating rating) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SvgPicture.asset(rating.selectedImgAsset, width: 40.w),
        SizedBox(height: 12.h),
        Text(
          rating.label,
          style: CustomTextStyles.p3.copyWith(color: rating.selectedColor, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4.h),
        Text(
          // TODO: 서버에서 각 등급별 후기 개수 받아와서 표시하기
          '24',
          style: CustomTextStyles.h2.copyWith(color: rating.selectedColor, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildRatingReviewTag(TradeReviewTag tag) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(color: AppColors.secondaryBlack2, borderRadius: BorderRadius.circular(8.r)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(tag.label, style: CustomTextStyles.p2),
          SizedBox(width: 16.w),
          Text(
            // TODO: 서버에서 각 태그별 후기 개수 받아와서 표시하기
            '24',
            style: CustomTextStyles.p2.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewComment() {
    // TODO: 서버에서 후기 코멘트 받아와서 표시하기
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 0.h),
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(10.r)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          UserProfileCircularAvatar(avatarSize: Size(32.w, 32.w), isDeleteAccount: false),
          SizedBox(width: 12.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('닉네임', style: CustomTextStyles.p2.copyWith(fontSize: 13.sp)),
              SizedBox(height: 6.h),
              Text(
                '위치',
                style: CustomTextStyles.p2.copyWith(fontSize: 11.sp, color: AppColors.opacity60White),
              ),
              SizedBox(height: 8.h),
              Text(
                '후기 코멘트',
                style: CustomTextStyles.p2.copyWith(height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
