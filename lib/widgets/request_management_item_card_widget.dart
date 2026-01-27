import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/font_family.dart';
import 'package:romrom_fe/icons/app_icons.dart';

import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/models/request_management_item_card.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/ai_badge.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';

/// 요청 관리 아이템 카드 위젯
class RequestManagementItemCardWidget extends StatelessWidget {
  final RequestManagementItemCard card;
  final bool isActive;

  const RequestManagementItemCardWidget({super.key, required this.card, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    // 카드 스케일 조정
    final scale = isActive ? 1.0 : 0.85;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: SizedBox(
          width: 219.w,
          height: 326.h,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(color: AppColors.opacity60White, width: 4.w, strokeAlign: BorderSide.strokeAlignOutside),
              color: AppColors.opacity80White,
              boxShadow: [BoxShadow(color: AppColors.opacity15Black, blurRadius: 10.r, spreadRadius: 0, offset: Offset(4.w, 4.h))],
              backgroundBlendMode: BlendMode.srcOver,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 영역
                SizedBox(
                  width: 219.w,
                  height: 247.h,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
                    child: _buildImage(card.imageUrl),
                  ),
                ),

                // 정보 영역
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 0.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 카테고리
                        Text(card.category, style: CustomTextStyles.p4.copyWith(color: AppColors.itemCardCategoryText)),
                        SizedBox(height: 8.h),

                        // 제목
                        Text(
                          card.title,
                          style: CustomTextStyles.p3.copyWith(color: AppColors.itemCardNameText, fontFamily: FontFamily.nexonLv2Gothic.fontName, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // 가격과 좋아요 영역
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // AI 배지
                            if (card.aiPrice) ...[const AiBadgeWidget(), SizedBox(width: 8.w)],
                            // 가격
                            Padding(
                              padding: EdgeInsets.only(top: 12.0.h),
                              child: Text(
                                '${formatPrice(card.price)}원',
                                style: CustomTextStyles.p2.copyWith(color: AppColors.itemCardPriceText, fontWeight: FontWeight.w600),
                              ),
                            ),

                            const Spacer(),

                            // 좋아요 아이콘 및 수
                            _buildLikeCount(card.likeCount),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 좋아요 아이콘과 개수 위젯
  Widget _buildLikeCount(int count) {
    return Padding(
      padding: EdgeInsets.only(top: 12.0.h),
      child: Row(
        children: [
          Icon(AppIcons.itemRegisterHeart, size: 14.sp, color: AppColors.itemCardLikeText),
          SizedBox(width: 4.w),
          Text(
            '$count',
            style: CustomTextStyles.p3.copyWith(color: AppColors.itemCardLikeText, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 이미지 로드 위젯
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const ErrorImagePlaceholder();
    }

    return CachedImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: const ErrorImagePlaceholder(),
    );
  }
}
