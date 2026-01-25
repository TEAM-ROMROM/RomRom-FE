import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:romrom_fe/enums/notification_category.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

/// 알림 데이터 모델
class NotificationItemData {
  final String id;
  final NotificationCategory category;
  final String title;
  final String description;
  final DateTime time;
  final String? imageUrl;
  final bool isRead;

  NotificationItemData({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.time,
    this.imageUrl,
    this.isRead = false,
  });
}

/// 알림 아이템 위젯
class NotificationItemWidget extends StatelessWidget {
  final NotificationItemData data;
  final VoidCallback? onMuteTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onTap;

  const NotificationItemWidget({
    super.key,
    required this.data,
    this.onMuteTap,
    this.onDeleteTap,
    this.onTap,
  });

  /// 시간 포맷팅
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${time.month}월 ${time.day}일';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 아이콘
            _buildCategoryIcon(),
            SizedBox(width: 12.w),

            // 콘텐츠 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 카테고리 + 시간 + 더보기 메뉴
                  _buildHeader(),
                  SizedBox(height: 8.h),

                  // 제목
                  Text(
                    data.title,
                    style: CustomTextStyles.p2.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColorWhite,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),

                  // 설명
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          data.description,
                          style: CustomTextStyles.p3.copyWith(
                            fontWeight: FontWeight.w400,
                            color: AppColors.opacity60White,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // 썸네일 이미지 (있는 경우)
                      if (data.imageUrl != null) ...[
                        SizedBox(width: 12.w),
                        _buildThumbnail(),
                      ],
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

  /// 카테고리 아이콘
  Widget _buildCategoryIcon() {
    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: AppColors.secondaryBlack1,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Center(
        child: Icon(
          data.category.icon,
          size: 20.sp,
          color: data.category.iconColor,
        ),
      ),
    );
  }

  /// 헤더 (카테고리 라벨 + 시간 + 더보기 메뉴)
  Widget _buildHeader() {
    return Row(
      children: [
        // 카테고리 라벨
        Text(
          data.category.label,
          style: CustomTextStyles.p3.copyWith(
            fontWeight: FontWeight.w500,
            color: AppColors.opacity60White,
          ),
        ),
        SizedBox(width: 8.w),

        // 시간
        Text(
          _formatTime(data.time),
          style: CustomTextStyles.p3.copyWith(
            fontWeight: FontWeight.w400,
            color: AppColors.opacity40White,
          ),
        ),

        const Spacer(),

        // 더보기 메뉴
        SizedBox(
          width: 24.w,
          height: 24.h,
          child: RomRomContextMenu(
            customTrigger: Icon(
              AppIcons.dotsVerticalSmall,
              size: 20.sp,
              color: AppColors.opacity60White,
            ),
            items: [
              ContextMenuItem(
                id: 'mute',
                svgAssetPath: 'assets/images/alertOff.svg',
                title: '알림 끄기',
                onTap: () {
                  if (onMuteTap != null) onMuteTap!();
                },
                showDividerAfter: true,
              ),
              ContextMenuItem(
                id: 'delete',
                svgAssetPath: 'assets/images/trashRed.svg',
                title: '삭제',
                textColor: AppColors.itemOptionsMenuDeleteText,
                onTap: () {
                  if (onDeleteTap != null) onDeleteTap!();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 썸네일 이미지
  Widget _buildThumbnail() {
    return CachedImage(
      imageUrl: data.imageUrl!,
      width: 48.w,
      height: 48.w,
      borderRadius: BorderRadius.circular(8.r),
    );
  }
}
