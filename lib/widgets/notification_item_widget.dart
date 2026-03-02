import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:romrom_fe/enums/notification_type.dart';
import 'package:romrom_fe/icons/app_icons.dart';
import 'package:romrom_fe/models/app_colors.dart';
import 'package:romrom_fe/models/app_theme.dart';
import 'package:romrom_fe/utils/common_utils.dart';
import 'package:romrom_fe/widgets/common/cached_image.dart';
import 'package:romrom_fe/widgets/common/romrom_context_menu.dart';

/// 알림 데이터 모델
class NotificationItemData {
  final String id;
  final NotificationType type;
  final String title;
  final String description;
  final DateTime time;
  final String? imageUrl;
  final bool isRead;
  final String? deepLink;

  NotificationItemData({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.imageUrl,
    this.isRead = false,
    this.deepLink,
  });
}

/// 알림 아이템 위젯
class NotificationItemWidget extends StatelessWidget {
  final NotificationItemData data;
  final bool isMuted;
  final VoidCallback? onMuteTap;
  final VoidCallback? onDeleteTap;
  final VoidCallback? onTap;

  const NotificationItemWidget({
    super.key,
    required this.data,
    this.isMuted = false,
    this.onMuteTap,
    this.onDeleteTap,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: data.isRead ? AppColors.primaryBlack : AppColors.notificationUnReadIndicator, // 읽은 알림과 안 읽은 알림 구분
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 : 카테고리 + 시간 + 메뉴
            _buildTopRow(),

            SizedBox(height: 4.h),

            // 하단 : 제목 + 설명 + 사진
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  /// 카테고리 아이콘
  Widget _buildCategoryIcon() {
    return Container(
      width: 20.w,
      height: 20.w,
      decoration: BoxDecoration(color: AppColors.secondaryBlack1, borderRadius: BorderRadius.circular(4.r)),
      child: Center(
        child: SvgPicture.asset(data.type.svgAssetPath, width: 16.w, height: 16.w),
      ),
    );
  }

  /// 상단 섹션 (카테고리 + 시간 + 메뉴)
  Widget _buildTopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 카테고리 아이콘 + 라벨
              Row(
                children: [
                  // 카테고리 아이콘
                  _buildCategoryIcon(),
                  SizedBox(width: 8.w),

                  // 카테고리 라벨
                  Text(data.type.label, style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
                ],
              ),

              Text(getTimeAgo(data.time), style: CustomTextStyles.p2.copyWith(color: AppColors.opacity60White)),
            ],
          ),
        ),

        // 더보기 메뉴
        Container(
          width: 24.w,
          height: 24.h,
          margin: EdgeInsets.only(top: 1.h),
          child: RomRomContextMenu(
            customTrigger: Icon(AppIcons.dotsVerticalDefault, size: 24.sp, color: AppColors.textColorWhite),
            items: [
              ContextMenuItem(
                id: 'mute',
                icon: isMuted ? AppIcons.alert : AppIcons.alertOff,
                title: isMuted ? '알림 켜기' : '알림 끄기',
                onTap: () {
                  if (onMuteTap != null) onMuteTap!();
                },
                showDividerAfter: true,
              ),
              ContextMenuItem(
                id: 'delete',
                icon: AppIcons.trash,
                iconColor: AppColors.itemOptionsMenuRedIcon,
                title: '삭제',
                textColor: AppColors.itemOptionsMenuRedText,
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

  /// 하단 섹션 (시간 + 메뉴 + 썸네일)
  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 28.w), // 왼쪽 여백
        // 제목 + 설명
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                data.title,
                style: CustomTextStyles.p1.copyWith(fontWeight: FontWeight.w600, color: AppColors.textColorWhite),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8.h),

              // 설명
              Text(
                data.description,
                style: CustomTextStyles.p3.copyWith(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textColorWhite,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // 썸네일 이미지 (있는 경우) - 메뉴 왼쪽 12px
        if (data.imageUrl != null) _buildThumbnail(),
      ],
    );
  }

  /// 썸네일 이미지
  Widget _buildThumbnail() {
    return Padding(
      padding: EdgeInsets.only(left: 12.0.w),
      child: CachedImage(imageUrl: data.imageUrl!, width: 48.w, height: 48.w, borderRadius: BorderRadius.circular(4.r)),
    );
  }
}
