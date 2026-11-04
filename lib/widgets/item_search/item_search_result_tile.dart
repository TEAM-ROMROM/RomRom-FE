// 물품 검색 결과 한 줄: 썸네일(Hero), 이름, 카테고리·등록 시각, 가격, 좋아요 수
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/item_categories.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/apis/objects/item.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/app_pressable.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/error_image_placeholder.dart';

class ItemSearchResultTile extends StatelessWidget {
  final Item item;
  final String heroTag;
  final VoidCallback onTap;

  const ItemSearchResultTile({super.key, required this.item, required this.heroTag, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final categoryLabel = ItemCategories.fromServerName(item.itemCategory)?.label;
    final uploadTime = getTimeAgo(item.createdDate);
    final subtitle = [?categoryLabel, if (uploadTime.isNotEmpty) uploadTime].join(' · ');

    return AppPressable(
      onTap: onTap,
      scaleDown: AppPressable.scaleCard,
      enableRipple: false,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4.r),
              child: SizedBox(
                width: 90.w,
                height: 90.w,
                child: Hero(tag: heroTag, child: _buildThumbnail(item.primaryImageUrl)),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.itemName ?? '물품명 없음',
                    style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(subtitle, style: CustomTextStyles.p3.copyWith(color: AppColors.opacity60White)),
                  ],
                  SizedBox(height: 10.h),
                  Text('${formatPrice(item.price ?? 0)}원', style: CustomTextStyles.p1),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Icon(AppIcons.itemRegisterHeart, size: 14.sp, color: AppColors.opacity60White),
                      SizedBox(width: 4.w),
                      Text(
                        '${item.likeCount ?? 0}',
                        style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 썸네일: 주소 없음·로드 실패 > 플레이스홀더
  Widget _buildThumbnail(String? imageUrl) {
    if (imageUrl == null || imageUrl.trim().isEmpty) return const ErrorImagePlaceholder();
    return CachedImage(
      imageUrl: imageUrl.trim(),
      width: 90.w,
      height: 90.w,
      fit: BoxFit.cover,
      errorWidget: const ErrorImagePlaceholder(),
    );
  }
}
