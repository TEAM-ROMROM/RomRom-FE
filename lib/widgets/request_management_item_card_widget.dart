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
  final double? width;
  final double? height;

  const RequestManagementItemCardWidget({
    super.key,
    required this.card,
    this.isActive = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // 카드 사이즈 (기본값 또는 커스텀)
    final cardWidth = width ?? 219.w;
    final cardHeight = height ?? 326.h;

    // 이미지 높이 비율 적용 (전체 높이의 75%)
    final imageHeight = cardHeight * 0.75;

    // 스케일 팩터 계산 (기본 크기에 대한 비율)
    final double scaleFactor = cardHeight / 326.0.h;

    // 카드 스케일 조정
    final scale = isActive ? 1.0 : 0.85;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 300),
      child: SizedBox(
        width: cardWidth,
        height: cardHeight,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular((10 * scaleFactor).r),
            border: Border.all(
              color: card.aiPrice ? AppColors.textColorWhite : AppColors.opacity60White,
              width: (4 * scaleFactor).w,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
            color: AppColors.textColorWhite,
            boxShadow: card.aiPrice
                ? [
                    BoxShadow(
                      color: AppColors.aiCardGradient[0],
                      offset: Offset((-1 * scaleFactor).w, (-1 * scaleFactor).h),
                      blurRadius: (4 * scaleFactor).r,
                      spreadRadius: (5 * scaleFactor).r,
                    ),
                    BoxShadow(
                      color: AppColors.aiCardGradient[1],
                      offset: Offset(0, (5 * scaleFactor).h),
                      blurRadius: (25 * scaleFactor).r,
                      spreadRadius: (5 * scaleFactor).r,
                    ),
                    BoxShadow(
                      color: AppColors.aiCardGradient[2],
                      offset: Offset((-5 * scaleFactor).w, (-5 * scaleFactor.h)),
                      blurRadius: (10 * scaleFactor).r,
                      spreadRadius: (5 * scaleFactor).r,
                    ),
                  ]
                : [const BoxShadow(color: AppColors.itemCardShadow, offset: Offset(4, 4), blurRadius: 10)],

            backgroundBlendMode: BlendMode.srcOver,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 영역
              SizedBox(
                width: cardWidth,
                height: imageHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular((10 * scaleFactor).r)),
                  child: _buildImage(card.imageUrl),
                ),
              ),

              // 정보 영역
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB((12 * scaleFactor).w, (8 * scaleFactor).h, (12 * scaleFactor).w, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 카테고리
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            card.category,
                            style: CustomTextStyles.p4.copyWith(
                              color: AppColors.itemCardCategoryText,
                              fontSize: (CustomTextStyles.p4.fontSize ?? 10) * scaleFactor,
                            ),
                          ),
                          SizedBox(height: (8 * scaleFactor).h),

                          // 제목
                          Text(
                            card.title,
                            style: CustomTextStyles.p3.copyWith(
                              color: AppColors.itemCardNameText,
                              fontFamily: FontFamily.nexonLv2Gothic.fontName,
                              fontWeight: FontWeight.w700,
                              fontSize: (CustomTextStyles.p3.fontSize ?? 12) * scaleFactor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),

                      SizedBox(height: card.aiPrice ? (9 * scaleFactor).h : (12 * scaleFactor).h),
                      // 가격과 좋아요 영역
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // AI 배지
                          if (card.aiPrice) ...[
                            SizedBox(
                              width: (21 * scaleFactor).w,
                              height: (20 * scaleFactor).h,
                              child: const FittedBox(fit: BoxFit.contain, child: AiBadgeWidget()),
                            ),
                            SizedBox(width: (8 * scaleFactor).w),
                          ],
                          // 가격
                          Text(
                            '${formatPrice(card.price)}원',
                            style: CustomTextStyles.p2.copyWith(
                              color: AppColors.itemCardPriceText,
                              fontWeight: FontWeight.w600,
                              fontSize: (CustomTextStyles.p2.fontSize ?? 12) * scaleFactor,
                            ),
                          ),

                          const Spacer(),

                          // 좋아요 아이콘 및 수
                          _buildLikeCount(card.likeCount, scaleFactor),
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
    );
  }

  /// 좋아요 아이콘과 개수 위젯
  Widget _buildLikeCount(int count, double scaleFactor) {
    return Row(
      children: [
        Icon(AppIcons.itemRegisterHeart, size: (14 * scaleFactor).sp, color: AppColors.itemCardLikeText),
        SizedBox(width: (4 * scaleFactor).w),
        Text(
          '$count',
          style: CustomTextStyles.p3.copyWith(
            color: AppColors.itemCardLikeText,
            fontWeight: FontWeight.w500,
            fontSize: (CustomTextStyles.p3.fontSize ?? 12) * scaleFactor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// 이미지 로드 위젯
  Widget _buildImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return const ErrorImagePlaceholder();
    }

    return CachedImage(imageUrl: imageUrl, fit: BoxFit.cover, errorWidget: const ErrorImagePlaceholder());
  }
}
